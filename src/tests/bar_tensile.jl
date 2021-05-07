export BarTensileQS

function BarTensileQS(; gen_mat=nothing, spc_mat=nothing)
    Steps = 6000
    solver = PDBenchmark.NameParam(:vv, (Steps), Dict(:filewrite_freq=>100, :neigh_update_freq=>100, :file_prefix=>"BarTensileQS", :start_at=>0))
    obj = () -> begin changetype(Cuboid([0 10; 0 2; 0 2]), out -> begin x=out[1]; x[1, :] .> 5.0 end, 2) end
    geom = PDBenchmark.NameParam(obj, (), Dict(:resolution=>0.5))

    
    Es = 20
    nu = 0.2
    K = Es/3/(1-2nu)
    G = Es/2/(1+nu)
    rho = 1000.0
    horizon = 2.0
    s = 0.5

    gen_mat = PDBenchmark.NameParam(:GeneralMaterial, (horizon), Dict(:max_neigh=>200))
    
    spc_mat = PDBenchmark.NameParam(:OrdinaryStateBasedSpecific, ([K, K, K], [G, G, G], [s, s, s], [rho, rho], ), Dict())

    bc_f1 = x -> (vec(x[1,:] .<= 2.0), )
    bc_f2 = x -> (vec(x[1,:] .>= 8.0), [0.0005, 0, 0])

    bc = [PDBenchmark.NameParam(:FixBC, (bc_f1,)), PDBenchmark.NameParam(:MoveBC, (bc_f2,))]
    RM = [PDBenchmark.NameParam(:SimpleRepulsionModel, (2.0, 100.0), Dict(:blocks=>(1,), :distanceX=>3, :max_neighs=>200))]

    f = env -> begin
        env.Params = Dict("left" => (env.y[1,:] .< 2))
        env.Out = Dict("Force" => zeros(3, Steps))
        env.Collect! = (Params, Out, step) -> Out["Force"][:, step] = sum(env.f[:,Params["left"]], dims=2)
    end

    test = PDBenchmark.Test(solver, geom, gen_mat, spc_mat, bc, RM, f)

    return test
end