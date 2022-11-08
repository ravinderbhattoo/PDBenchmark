export FlexureFixedEndBar

function FlexureFixedEndBar(; gen_mat=nothing, spc_mat=nothing, dt = 1.0, Steps=nothing, max_disp=0.05, resolution=0.1, solver_=:qs, fwf=1, printevery=1,
                        makeplot=true, out_dir="FlexureFixedEndBar", trueE=nothing)
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
    solver = PDBenchmark.NameParam(solver_, sargs, Dict(:filewrite_freq=>fwf, :neigh_update_freq=>10, :out_dir=>out_dir, :start_at=>0, skwargs...))  ##skwarg = keyword argument

    effective_l = 10.0
    w = 2.0
    l = effective_l + 2*6*resolution

    I_ = w^4 / 12
    K_ = 12*trueE*I_ / l^3

    obj = () -> Bar(bounds=[0 l; 0 w; 0 w])

    velocity_rate = [0.0, max_disp * w / Steps / 2 / dt, 0]
    reso = resolution
    geom = PDBenchmark.NameParam(obj, (), Dict(:resolution=>reso, :rand_=>0.05))

    left_part = (l-effective_l) / 2
    right_part = effective_l + left_part

    if solver_ in [:qs]
        bc_f1 = env -> (vec(env.y[1,:] .<= left_part),  -velocity_rate)
        bc_f2 = env -> (vec(env.y[1,:] .>= right_part), velocity_rate)
        bc = [  PDBenchmark.NameParam(:MoveBC, (bc_f1,)),
                PDBenchmark.NameParam(:MoveBC, (bc_f2,)),
                ]
    else
        bc_f1 = env -> (vec(env.y[1,:] .<= left_part),  -velocity_rate)
        bc_f2 = env -> (vec(env.y[1,:] .>= right_part), velocity_rate)
        bc = [PDBenchmark.NameParam(:MoveBC, (bc_f1,)), PDBenchmark.NameParam(:MoveBC, (bc_f2,))]
    end
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
        env.Out = Dict("F_y" => zeros(1, Steps), "D_y" => zeros(1, Steps))
        env.Collect! = (env, step) -> begin

                env.Out["F_y"][1, step] = sum(env.f[2, env.Params["left"]]) * env.Params["mass"]
                env.Out["D_y"][1, step] = 2*velocity_rate[2]*step*env.dt

                if (env.time_step%printevery==0)
                    if makeplot
                        fig = plot(env.Out["D_y"][1, :], env.Out["F_y"][1, :])
                        if true #~isa(trueE, Nothing)
                            plot!([0.0, env.Out["D_y"][1, step]], [0.0, K_*env.Out["D_y"][1, step]])
                        end
                        display(fig)
                    end
                end

            end
    end

    test = PDBenchmark.Test(solver, geom, gen_mat, spc_mat, bc, RM, f; dt=dt)

    return test
end