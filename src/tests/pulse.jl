export PulsePropagationBar

function PulsePropagationBar(; gen_mat=nothing, spc_mat=nothing, dt = 1.0, Steps=nothing, init_velocity=nothing, resolution=0.1, solver_=:qs, fwf=1, printevery=1,
                        makeplot=true, out_dir="PulsePropagationBar", trueE=nothing)
    if solver_ in [:qs]
        if Steps===nothing
            Steps = 100
        end
        sargs = (Steps, 0.001)
        skwargs = Dict(:max_iter => 500)
        fwf = fwf
    else
        if Steps===nothing
            Steps = 10000
        end
        sargs = (Steps, )
        skwargs = Dict()
        fwf = fwf    ##File write frequency
    end

    if isa(init_velocity, Nothing)
        init_velocity = 0.001*resolution/dt
    end

    solver = PDBenchmark.NameParam(solver_, sargs, Dict(:filewrite_freq=>fwf, :neigh_update_freq=>10, :out_dir=>out_dir, :start_at=>0, skwargs...))  ##skwarg = keyword argument

    effective_l = 20.0
    w = 2.0
    l = effective_l + 2*6*resolution

    println("Effective length of Bar: ", effective_l)

    obj = () -> Bar(bounds=[0 l; 0 w; 0 w])


    reso = resolution
    geom = PDBenchmark.NameParam(obj, (), Dict(:resolution=>reso, :rand_=>0.02))

    left_part = (l-effective_l) / 2
    right_part = effective_l + left_part

    bc_f1 = env -> (vec(env.y[1,:] .<= left_part), )
    bc = [PDBenchmark.NameParam(:FixBC, (bc_f1,))]

    RM = [] #[PDBenchmark.NameParam(:LinearRepulsionModel, (1.0,), Dict(:blocks=>(1,), :distanceX=>3, :max_neighs=>200))]

    f = env -> begin
        left_ = (env.y[1,:] .<= left_part)
        right_ = (env.y[1,:] .>= right_part)
        l_ = maximum(env.y[1, right_]) - minimum(env.y[1, left_])
        env.Params = Dict(  "left" => left_,
                            "right"=>right_,
                            "l_"=>l_,
                            "mass"=>(env.material_blocks[1].specific.density[1] * reso^3),
                            "area"=>w*w,
                         )
        env.v[1, right_] .= -init_velocity
        env.Out = Dict("Stress_x" => zeros(1, Steps), "time" => zeros(1, Steps))
        env.Collect! = (env, step) -> begin

                current_l = maximum(env.y[1, right_]) - minimum(env.y[1, left_])
                env.Out["Stress_x"][1, step] = sum(env.f[1, env.Params["left"]]) * env.Params["mass"] / env.Params["area"]
                env.Out["time"][1, step] = step * env.dt

                if (env.time_step%printevery==0)
                    if makeplot
                        fig = plot(env.Out["time"][1, :], env.Out["Stress_x"][1, :])
                        display(fig)
                    end
                end

            end
    end

    test = PDBenchmark.Test(solver, geom, gen_mat, spc_mat, bc, RM, f; dt=dt)

    return test
end