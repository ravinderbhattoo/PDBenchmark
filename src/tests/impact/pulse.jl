export PulsePropagationBar

"""
    PulsePropagationBar(; gen_mat=nothing,
                        spc_mat=nothing,
                        dt = 1.0,
                        steps=1000,
                        init_velocity=nothing,
                        effective_length=20.0,
                        resolution=0.1,
                        solver=DSVelocityVerlet(),
                        testname="PulsePropagationBar Test",
                        )

It is a test for pulse propagation. The test is performed by applying a
impact on the right end of the specimen. The impact is applied in the
direction of the axis of the specimen. The specimen is a bar.

# Keyword Arguments
- `gen_mat`: The general material of the specimen.
- `spc_mat`: The specific material of the specimen.
- `dt::Float64`: The time step.
- `steps::Int64`: The number of steps.
- `init_velocity::Float64`: The initial velocity of the impact.
- `effective_length::Float64`: The effective length of the specimen.
- `resolution::Float64`: The resolution of the specimen.
- `solver::Function`: The solver.
- `testname::String`: The name of the test.
"""
function PulsePropagationBar(; gen_mat=nothing,
                        spc_mat=nothing,
                        dt = 1.0,
                        steps=1000,
                        init_velocity=nothing,
                        effective_length=20.0,
                        resolution=0.1,
                        solver=DSVelocityVerlet(),
                        testname="PulsePropagationBar Test",
                        )
    if isa(init_velocity, Nothing)
        init_velocity = 0.001 * resolution / dt
    end
    w = 2.0
    l = effective_length + 2*6*resolution
    obj = () -> Bar(bounds=[0 l; 0 w; 0 w])
    geom = TParam(obj, (), Dict(
                            :resolution=>resolution,
                            :rand_=>0.02))
    left_part = (l-effective_length) / 2
    right_part = effective_length + left_part
    bc_f1 = env -> (vec(env.y[1,:] .<= left_part), )
    bc = [TParam(FixBC, args=(bc_f1,))]
    RM = [
            # TParam(LinearSpringContactModel,
            #             (1.0,),
            #             Dict(:blocks=>(1,),
            #                     :distanceX=>3,
            #                     :max_neighs=>200))
        ]
    f = env -> begin
        left_ = (env.y[1,:] .<= left_part)
        right_ = (env.y[1,:] .>= right_part)
        l_ = maximum(env.y[1, right_]) - minimum(env.y[1, left_])
        env.Params = Dict(  "left" => left_,
                            "right"=>right_,
                            "l_"=>l_,
                            "mass"=>(env.material_blocks[1].specific.density[1] * resolution^3),
                            "area"=>w*w,
                         )
        env.v[1, right_] .= -init_velocity
        env.Out = Dict(:Stress_x => zeros(1, steps), :time => zeros(1, steps))
        env.Collect! = (env, step) -> begin
                current_l = maximum(env.y[1, right_]) - minimum(env.y[1, left_])
                env.Out[:Stress_x][1, step] = sum(env.f[1, env.Params["left"]]) * env.Params["mass"] / env.Params["area"]
                env.Out[:time][1, step] = step * env.dt
            end
    end
    test = PDBenchmark.Test(
                        solver,
                        geom,
                        gen_mat,
                        spc_mat,
                        bc,
                        RM,
                        f;
                        dt=dt,
                        steps=steps,
                        names=["Bar"],
                        testname=testname,
                        info="Pulse propagation in a bar. \
                        The left part of the bar is fixed. \
                        The right part is free. \
                        The bar is excited by a velocity pulse. \
                        The pulse propagates through the bar. \
                        The stress is measured at the left boundary. \
                        The time taken for the pulse to propagate through \
                        the bar is given by the time at which the stress \
                        is non-zero. \
                        The effective length of the bar is $effective_length \
                        and pusle should hit the left boundary at time \
                        $effective_length/wave_velocity. \n" *

"""
               ____
              |    | $w
            ↱ |____|
            :   $w     Wave velocity = √E/ρ
 /|_________:____________
 /|         :            | 🔨 impact location
 /|_________:____________|  v = $(init_velocity)
 /|         :
  |<-------------------->|
  ↑       $effective_length
  sensor location for stress measurement
""")
    return test
end

