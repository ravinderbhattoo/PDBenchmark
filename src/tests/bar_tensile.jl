export BarTensileQS

function BarTensileQS(; gen_mat=nothing, spc_mat=nothing)
    Steps = 10
    solver = PDBenchmark.NameParam(:qs, (Steps, 1.0), Dict(:filewrite_freq=>1, :neigh_update_freq=>1, :file_prefix=>"minimize", :start_at=>0))
    geom = PDBenchmark.NameParam(:Bar, (), Dict(:resolution=>0.5))

    if typeof(gen_mat) == Nothing
        rho = 1000.0
        horizon = 0.3
        s = 0.5
        gen_mat = PDBenchmark.NameParam(:GeneralMaterial, (rho, horizon, s), Dict())
    end

    if typeof(spc_mat)==Nothing
        Es = 20
        nu = 0.2
        K = Es/3/(1-2nu)
        G = Es/2/(1+nu)
        spc_mat = PDBenchmark.NameParam(:OrdinaryStateBasedSpecific, (K, G), Dict())
    end

    bc_f = out -> begin
    x = out[1]
    type = out[5][1]
    scalemask_f = out -> vec(begin x=out[1]; x[1, :] .< Inf end)
    fixmask_f = out -> vec(begin 
                            x=out[1]; 
                            mask1 = x[1,:] .<= 2.0 
                            mask2 = x[1,:] .>= 8.0
                            mask1 .| mask2  
                        end)
    return type, scalemask_f(out), [0.02, 0.0, 0.0], fixmask_f(out) 
    end

    bc = PDBenchmark.NameParam(:ScaleFixBC, bc_f, Dict())
    RM = PDBenchmark.NameParam(:SimpleRepulsionModel, (2.0, 1.0), Dict(:distanceX=>3, :max_neighs=>200))

    f = env -> begin
        env.Params = Dict("left" => (env.y[1,:] .< 2))
        env.Out = Dict("Force" => zeros(3, Steps))
        env.Collect! = (Params, Out, step) -> Out["Force"][:, step] = sum(env.f[:,Params["left"]], dims=2)
    end

    test = PDBenchmark.Test(solver, geom, gen_mat, spc_mat, bc, RM, f)

    return test
end