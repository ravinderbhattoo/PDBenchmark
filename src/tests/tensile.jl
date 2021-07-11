export TensileBar, TensileNotchedBar

function TensileNotchedBar(args...; kwargs...)
    TensileBar(args...; notched=true, kwargs...)
end

function TensileBar(; gen_mat=nothing, spc_mat=nothing, resolution=0.1, solver_=:qs, notched=false, file_prefix="TensileBar")
    if solver_ in [:qs]
        Steps = 10
        sargs = (Steps, 0.01)
        skwargs = Dict(:max_iter=>500)
        fwf = 1
    else
        Steps = 1000
        sargs = (Steps, )
        skwargs = Dict()
        fwf = 10
    end
    solver = PDBenchmark.NameParam(solver_, sargs, Dict(:filewrite_freq=>fwf, :neigh_update_freq=>100, :file_prefix=>file_prefix, :start_at=>0, skwargs...))
    
    if notched
        obj = () -> NotchedBar(bounds=[0 12; 0 1; 0 1], notch=[5.75 6.25; 0.0 0.25; 0.0 1.0])
    else
        obj = () -> Bar(bounds=[0 12; 0 1; 0 1])
    end

    reso = resolution
    geom = PDBenchmark.NameParam(obj, (), Dict(:resolution=>reso))

    if solver_ in [:qs]
        bc_f1 = x -> (vec(x[1,:] .<= 01.0),  [-0.01, 0, 0])
        bc_f2 = x -> (vec(x[1,:] .>= 11.0), [0.01, 0, 0])
        bc = [  PDBenchmark.NameParam(:MoveBC, (bc_f1,)), 
                PDBenchmark.NameParam(:MoveBC, (bc_f2,)),
                ]
    else
        bc_f1 = x -> (vec(x[1,:] .<= 1.0),  [-0.0001, 0, 0])
        bc_f2 = x -> (vec(x[1,:] .>= 11.0), [0.0001, 0, 0])
        bc = [PDBenchmark.NameParam(:MoveBC, (bc_f1,)), PDBenchmark.NameParam(:MoveBC, (bc_f2,))]
    end
    RM = [PDBenchmark.NameParam(:LinearRepulsionModel, (100.0,), Dict(:blocks=>(1,), :distanceX=>3, :max_neighs=>200))]

    f = env -> begin
        left_ = (env.y[1,:] .<= 1.0)
        right_ = (env.y[1,:] .>= 11.0)
        right_max = maximum(env.y[1, right_])
        env.Params = Dict("left" => left_, "right"=>right_, "right_max"=>right_max)
        env.Out = Dict("Force" => zeros(3, Steps), "Displacement" => zeros(1, Steps))
        env.Collect! = (env, step) -> begin 
                env.Out["Force"][:, step] = sum(env.f[:,env.Params["left"]], dims=2)
                env.Out["Displacement"][1, step] = 2*(maximum(env.y[1,env.Params["right"]]) - env.Params["right_max"])
                if step%fwf==0
                    println("E = $(10.0*env.Out["Force"][1, step]/env.Out["Displacement"][1, step])")
                end
            end
    end

    test = PDBenchmark.Test(solver, geom, gen_mat, spc_mat, bc, RM, f)

    return test
end