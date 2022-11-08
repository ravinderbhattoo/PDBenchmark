export TensileBar, TensileNotchedBar

function TensileNotchedBar(args...; kwargs...)
    TensileBar(args...; notched=true, kwargs...)
end

function TensileBar(; gen_mat=nothing, spc_mat=nothing, dt=1.0, max_strain=0.05, resolution=0.1, solver=PeriDyn.DSVelocityVerlet(), Steps=100, fwf=1, nuf=10, printevery=1,
                        makeplot=true, notched=false, out_dir="TensileBar", trueE=nothing)

    solver = PDBenchmark.NameParam(solver, (Steps), Dict(:filewrite_freq=>fwf, :neigh_update_freq=>nuf, :out_dir=>out_dir, :start_at=>0))

    effective_l = 6.0
    w = 2.0
    l = effective_l + 2*6*resolution
    if notched
        obj = () -> NotchedBar(bounds=[0 l; 0 w; 0 w], notch=[0.575*l 0.625*l; 0.0 0.25*w; 0.0 1.0*w])
    else
        obj = () -> Bar(bounds=[0 l; 0 w; 0 w])
    end

    velocity_rate = max_strain * l / Steps / 2 / dt
    reso = resolution
    geom = PDBenchmark.NameParam(obj, (), Dict(:resolution=>reso, :rand_=>0.05))

    left_part = (l-effective_l) / 2
    right_part = effective_l + left_part

    bc_f1 = env -> (vec(env.y[1,:] .<= left_part),  [-velocity_rate, 0, 0])
    bc_f2 = env -> (vec(env.y[1,:] .>= right_part), [velocity_rate, 0, 0])
    BCs = [  PDBenchmark.NameParam(:MoveBC, (bc_f1,)),
            PDBenchmark.NameParam(:MoveBC, (bc_f2,)),
            ]

    RMs = [] #[PDBenchmark.NameParam(:LinearRepulsionModel, (1.0,), Dict(:blocks=>(1,), :distanceX=>3, :max_neighs=>200))]

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
        env.Out = Dict("Stress_x" => zeros(1, Steps), "Strain_x" => zeros(1, Steps))
        env.Collect! = (env, step) -> begin

                current_l = maximum(env.y[1, right_]) - minimum(env.y[1, left_])
                env.Out["Stress_x"][1, step] = sum(env.f[1, env.Params["left"]]) * env.Params["mass"] / env.Params["area"]
                env.Out["Strain_x"][1, step] = (current_l - env.Params["l_"]) / env.Params["l_"]

                if (env.time_step%printevery==0)
                    println("Es = $(env.Out["Stress_x"][1, step] / env.Out["Strain_x"][1, step])")
                    println("L = $(current_l), $(env.Params["l_"])")
                    # println.([env.Params["l_"], env.Params["mass"], env.Params["area"]])
                    if makeplot
                        fig = plot(env.Out["Strain_x"][1, :], env.Out["Stress_x"][1, :], label="PD Model")
                        if true #~isa(trueE, Nothing)
                            plot!([0.0, env.Out["Strain_x"][1, step]], [0.0, trueE*env.Out["Strain_x"][1, step]], label=raw"\sigma = "*"$(trueE)"*raw" \epsilon")
                        end
                        plot!(legend=:topleft)
                        if Steps==step
                            mkpath("./output/$(out_dir)")
                            xlabel!(raw"\epsilon_x")
                            ylabel!(raw"\sigma_x")
                            savefig("./output/$(out_dir)/stress_strain.png")
                        end
                        display(fig)
                    end
                end
            end
    end

    test = PDBenchmark.Test(solver, geom, gen_mat, spc_mat, BCs, RMs, f; dt=dt)

    return test
end