export TensileNotchedBar, TensileBar, TensileRod
export UniaxialDeformationTest, TensileTest

"""
    TensileTest(args...; max_strain=0.05, testname="Tensile Test", kwargs...)

It is a test for uniaxial deformation.

# Arguments
- `args...`: The arguments of the test. The arguments are passed to the
    `UniaxialDeformationTest` function.

# Keyword Arguments
- `testname::String`: The name of the test.
- `max_strain::Float64`: The maximum strain of the test. If it is negative, the
    absolute value of it is used.
- `kwargs...`: The keyword arguments of the test. The keyword arguments
    are passed to the `UniaxialDeformationTest` function.

# Returns
- The return value of the `UniaxialDeformationTest` function.
"""
function TensileTest(args...; max_strain=0.05, testname="Tensile Test", kwargs...)
    if max_strain < 0.0
        name = variable_color("max_strain")
        log_impinfo("$name must be positive for tensile test. \
                     $name is set to $(abs(max_strain)) now.")
    end
    UniaxialDeformationTest(args...; max_strain=abs(max_strain), testname=testname, kwargs...)
end


"""
    TensileBar(args...; testname="Tensile Test Bar", kwargs...)

It is a test for uniaxial deformation.

# Arguments
- `args...`: The arguments of the test. The arguments are passed to the
    `TensileTest` function.

# Keyword Arguments
- `testname::String`: The name of the test.
- `kwargs...`: The keyword arguments of the test. The keyword arguments are
    passed to the `TensileTest` function. `specimen` is set to `:bar` by default.

# Returns
- The return value of the `TensileTest` function.
"""
function TensileBar(args...; testname="Tensile Test Bar", kwargs...)
    TensileTest(args...; specimen=:bar, testname=testname,kwargs...)
end

"""
    TensileNotchedBar(args...; testname="Tensile Test Notched Bar", kwargs...)

It is a test for uniaxial deformation.

# Arguments
- `args...`: The arguments of the test. The arguments are passed to the
    `TensileBar` function.

# Keyword Arguments
- `testname::String`: The name of the test.
- `kwargs...`: The keyword arguments of the test. The keyword arguments are
    passed to the `TensileBar` function. `notched` is set to `true` by default.

# Returns
- The return value of the `TensileBar` function.
"""
function TensileNotchedBar(args...; testname="Tensile Test Notched Bar", kwargs...)
    TensileBar(args...; notched=true, testname=testname, kwargs...)
end

"""
    TensileRod(args...; testname="Tensile Test Rod", kwargs...)

It is a test for uniaxial deformation.

# Arguments
- `args...`: The arguments of the test. The arguments are passed to the
    `TensileTest` function.

# Keyword Arguments
- `kwargs...`: The keyword arguments of the test. The keyword arguments are
    passed to the `TensileTest` function. `specimen` is set to `:rod` by default.

# Returns
- The return value of the `TensileTest` function.
"""
function TensileRod(args...; kwargs...)
    TensileTest(args...; specimen=:rod, testname="Tensile Test Rod", kwargs...)
end

"""
    UniaxialDeformationTest(; gen_mat=nothing, spc_mat=nothing, dt=1.0,
                        max_strain=0.05,
                        resolution=0.1,
                        rand_=0.05,
                        solver=PeriDyn.DSVelocityVerlet(),
                        steps=10000,
                        notched=false,
                        effective_length = 12.0,
                        specimen=:bar,
                        testname="Tensile Test")

It is a test for uniaxial deformation. The test is performed by applying a
displacement on both ends of the specimen. The specimen is a bar by default.

# Keyword Arguments
- `gen_mat`: The general material of the specimen.
- `spc_mat`: The specific material of the specimen.
- `dt`: The time step of the simulation.
- `max_strain::Float64`: The maximum strain of the specimen.
- `resolution`: The resolution of the specimen.
- `rand_`: The random factor of the specimen.
- `solver`: The solver.
- `steps`: The number of steps.
- `notched`: Whether the specimen is notched.
- `effective_length`: The effective length of the specimen.
- `specimen`: The type of the specimen. It can be `:bar`, `:rod` or `:cylinder`.
- `testname`: The name of the test.

# Returns
- `test`: The test.
"""
function UniaxialDeformationTest(; gen_mat=nothing, spc_mat=nothing,
                        dt=1.0,
                        max_strain=0.05,
                        resolution=0.1,
                        rand_=0.05,
                        solver=PeriDyn.DSVelocityVerlet(),
                        steps=10000,
                        notched=false,
                        effective_length = 12.0,
                        w = nothing,
                        specimen=:bar,
                        testname="Tensile Test")
    if w == nothing
        w = effective_length / 5
    end
    if specimen == :rod
        notched = false
        log_impinfo("Rod test, notched = false")
        radius = w/2
        l = effective_length + 2*6*resolution
        obj = () -> move(rotate(Disk(radius, l);
                                angle=90,
                                vector_=[0.0, 1.0, 0.0]), by=[-1/2, 0.0, 0.0]*l)
    elseif specimen == :cylinder
        notched = false
        log_impinfo("Cylinder test, notched = false")
        radius = w/2
        thickness = 0.3*radius
        l = effective_length + 2*6*resolution
        obj = () -> move(rotate(Cylinder(radius, thickness, l);
                                angle=90,
                                vector_=[0.0, 1.0, 0.0]), by=[-1/2, 0.0, 0.0]*l)
    else
        l = effective_length + 2*6*resolution
        notch_hwidth = 2*resolution
        notch_length = 0.1*w
        bounds = [-l/2 l/2; -w/2 w/2; -w/2 w/2]
        if notched
            obj = () -> NotchedBar(bounds=bounds,
                            notch=[-notch_hwidth notch_hwidth;
                                    -Inf Inf;
                                    w/2-notch_length Inf])
        else
            obj = () -> Bar(bounds=bounds)
        end
    end

    geom = TParam(obj, (), Dict(:resolution=>resolution, :rand_=>rand_))

    left_part = -effective_length/2
    right_part = effective_length/2

    # movement
    Δx = max_strain * l /2
    speed = Δx / steps / dt

    println(@yellow(@bold "INFO: "), "Δx = $(Δx),  speed = $speed, steps = $steps, dt = $dt")


    # generate the boundary conditions
    if typeof(solver) <: QuasiStaticSolver
        speed = 10*speed
        steps = Int64(steps / 10)
    end

    bc_f1 = env -> (vec(env.y[1,:] .<= left_part),  [-1, 0, 0]*speed)
    bc_f2 = env -> (vec(env.y[1,:] .>= right_part), [1, 0, 0]*speed)
    BCs = [TParam(MoveBC, args=(bc_f1,), kwargs=Dict(:pos_type=>eltype(l))),
            TParam(MoveBC, args=(bc_f2,), kwargs=Dict(:pos_type=>eltype(l))),
            ]

    # generate the specific material
    mfactor = 1
    K = realize(spc_mat).bulk_modulus[1, 1] * mfactor
    horizon = 3*resolution
    RMs = [
            TParam(ShortRangeContactModel,
                    (K, horizon),
                    Dict(:blocks=>(1,), :distanceX=>3, :max_neighs=>200))
        ]

    f = env -> begin
        left_ = (env.y[1,:] .<= left_part)
        right_ = (env.y[1,:] .>= right_part)
        l_ = maximum(env.y[1, right_]) - minimum(env.y[1, left_])
        env.Params = Dict(
                        :left=>left_,
                        :right=>right_,
                        :l_=>l_,
                        :mass=>(env.material_blocks[1].specific.density[1] * resolution^3),
                        :area=>w*w,
                    )
        ustress = first(env.f) * env.Params[:mass] / env.Params[:area]
        env.Out = Dict(:Stress_x => zeros(typeof(ustress), 1, steps), :Strain_x => zeros(1, steps))
        env.Collect! = (env, step) -> begin
                current_l = maximum(env.y[1, right_]) - minimum(env.y[1, left_])
                env.Out[:Stress_x][1, step] = sum(env.f[1, env.Params[:left]]) * env.Params[:mass] / env.Params[:area]
                env.Out[:Strain_x][1, step] = (current_l - env.Params[:l_]) / env.Params[:l_]
            end
    end

    cprint = (env) -> begin
        ε = env.Out[:Strain_x][env.time_step]
        σ = env.Out[:Stress_x][env.time_step]
        log_data(σₓ=σ)
        log_data(εₓ=ε)
        log_data(Υ = σ/ε)
    end

    test = PDBenchmark.Test(solver,
                        geom,
                        gen_mat,
                        spc_mat,
                        BCs,
                        RMs,
                        f;
                        dt=dt,
                        steps=steps,
                        names=["Bar"],
                        testname=testname,
                        cprint=cprint,
                        info="Tensile simulation of a bar. \
                        The left and right ends are moved at a constant speed of $speed. \
                        " *

"""

                 ____
                |    | $w
              ↱ |____|
              :   $w
      ________:_____________
    ⭅|        :            |⭆
    ⭅|________:____________|⭆
              :
     |<-------------------->|
     ↑       $effective_length
     sensor location for force measurement
""")
    return test
end