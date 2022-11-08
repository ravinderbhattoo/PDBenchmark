export ImpactDisk

function ImpactDisk(; gen_mat=nothing, spc_mat=nothing, dt = 1.0, Steps=nothing, projectile_velocity=[0.0, 0.0, -0.001], resolution=0.1,
                        solver_=:qs, fwf=1, nuf=10, printevery=1,
                        makeplot=true, out_dir="ImpactDisk", trueE=nothing)
    if solver_ in [:qs]
        if Steps===nothing
            Steps = 100
        end
        sargs = (Steps, 0.001)
        skwargs = Dict(:max_iter => 100)
        fwf = fwf
    else
        if Steps===nothing
            Steps = 10000
        end
        sargs = (Steps, )
        skwargs = Dict()
        fwf = fwf    ##File write frequency
    end

    solver = PDBenchmark.NameParam(solver_, sargs, Dict(:filewrite_freq=>fwf, :neigh_update_freq=>nuf, :out_dir=>out_dir, :start_at=>0, skwargs...))  ##skwarg = keyword argument

    radius = 25.0
    thickness = 4.0

    obj = () -> Disk(radius, thickness) 
    ball_radius = max(0.1*radius, 6*resolution)
    proj = () ->  move(Sphere(ball_radius), by=[0.0, 0.0, ball_radius+thickness+2*resolution])

    reso = resolution
    projectile_type = 2

    geom = [
                PDBenchmark.NameParam(obj, (), Dict(:resolution=>reso, :rand_=>0.02, :type=>1)),
                PDBenchmark.NameParam(proj, (), Dict(:resolution=>reso, :rand_=>0.02, :type=>projectile_type))
            ]



    bc = []

    RM = [PDBenchmark.NameParam(:LinearRepulsionModel, (1000.0,), Dict(:blocks=>(1, 2), :distanceX=>3, :max_neighs=>200))]

    f = env -> begin
        env.v[:, env.type .== projectile_type] .= projectile_velocity
        # env.Params = Dict(  "left" => left_,
        #                     "right"=>right_,
        #                     "l_"=>l_,
        #                     "mass"=>(env.material_blocks[1].specific.density[1] * reso^3),
        #                     "area"=>w*w,
        #                  )
        # env.Out = Dict("F_y" => zeros(1, Steps), "D_y" => zeros(1, Steps))
        # env.Collect! = (env, step) -> begin

        #         env.Out["F_y"][1, step] = sum(env.f[2, env.Params["left"]]) * env.Params["mass"]
        #         env.Out["D_y"][1, step] = 2*velocity_rate[2]*step*env.dt

        #         if (env.time_step%printevery==0)
        #             if makeplot
        #                 fig = plot(env.Out["D_y"][1, :], env.Out["F_y"][1, :])
        #                 if true #~isa(trueE, Nothing)
        #                     plot!([0.0, env.Out["D_y"][1, step]], [0.0, K_*env.Out["D_y"][1, step]])
        #                 end
        #                 display(fig)
        #             end
        #         end

        #     end
    end

    if length(geom) == length(spc_mat)
        nothing
    else
        spc_mat = [spc_mat for x in geom]
    end

    if length(geom) == length(gen_mat)
        nothing
    else
        gen_mat = [gen_mat for x in geom]
    end


    test = PDBenchmark.Test(solver, geom,  gen_mat, spc_mat, bc, RM, f; dt=dt)

    return test
end