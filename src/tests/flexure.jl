export _3PointBendingNotched, _3PointBending, _4PointBendingNotched, _4PointBending

function _3PointBendingNotched(args...; kwargs...)
    _3PointBending(args...; notched=true, kwargs...)
end

function _4PointBendingNotched(args...; kwargs...)
    _4PointBending(args...; notched=true, kwargs...)
end

function _4PointBending(args...; kwargs...)
    _3PointBending(args...; _4point=true, kwargs...)
end

function _3PointBending(; gen_mat=nothing, spc_mat=nothing, resolution=0.1, solver_=:qs, notched=false, _4point=true, file_prefix="TensileBar")
    if solver_ in [:qs]
        Steps = 100
        sargs = (Steps, 0.01)
        skwargs = Dict(:max_iter=>500)
        fwf = 1
    else
        Steps = 1000
        sargs = (Steps, )
        skwargs = Dict()
        fwf = 10
    end
    solver = PDBenchmark.NameParam(solver_, sargs, Dict(:filewrite_freq=>fwf, :file_prefix=>file_prefix, :start_at=>0, skwargs...))
    
    geom = []
    reso = resolution

    obj = () -> move(Disk(0.5, 1.0), by=[1.0,  -0.5, 0.0])
    push!(geom, PDBenchmark.NameParam(obj, (), Dict(:resolution=>reso, :type=>2)))

    obj = () -> move(Disk(0.5, 1.0), by=[11.0, -0.5, 0.0])
    push!(geom, PDBenchmark.NameParam(obj, (), Dict(:resolution=>reso, :type=>2)))

    obj = () -> move(Disk(0.5, 1.0), by=[6.00,  1.5, 0.0])
    push!(geom, PDBenchmark.NameParam(obj, (), Dict(:resolution=>reso, :type=>3)))

    if notched
        obj = () -> NotchedBar(bounds=[0 12; 0 1; 0 1], notch=[5.75 6.25; 0.0 0.25; 0.0 1.0])
    else
        obj = () -> Bar(bounds=[0 12; 0 1; 0 1])
    end

    push!(geom, PDBenchmark.NameParam(obj, (), Dict(:resolution=>reso, :type=>1)))

    gen_mat = [gen_mat, gen_mat, gen_mat, gen_mat]

    mat = getproperty_(PeriDyn, spc_mat.name)(spc_mat.args...; spc_mat.kwargs...)
    spc_mat0 = PDBenchmark.NameParam(:SkipSpecific, (mat.density, ), Dict())
    spc_mat = [spc_mat0, spc_mat0, spc_mat0, spc_mat]

    if solver_ in [:qs]
        bc_f1 = env -> (vec(env.type .== 2), )
        bc_f2 = env -> (vec(env.type .== 3), [0.0, -0.01, 0])
        bc = [  PDBenchmark.NameParam(:FixBC, (bc_f1,)), 
                PDBenchmark.NameParam(:MoveBC, (bc_f2,)),
                ]
    else
        bc_f1 = env -> (vec(env.type .== 2), )
        bc_f2 = env -> (vec(env.type .== 3), [0.0, -0.001, 0])
        bc = [  PDBenchmark.NameParam(:FixBC, (bc_f1,)), 
                PDBenchmark.NameParam(:MoveBC, (bc_f2,))
                ]
    end

    RM = []
    push!(RM, PDBenchmark.NameParam(:LinearRepulsionModel, (100.0,), Dict(:blocks=>(4,), :distanceX=>3, :max_neighs=>200)))
    push!(RM, PDBenchmark.NameParam(:LinearRepulsionModel, (100.0,), Dict(:blocks=>(4,1), :distanceX=>3, :max_neighs=>200)))
    push!(RM, PDBenchmark.NameParam(:LinearRepulsionModel, (100.0,), Dict(:blocks=>(4,2), :distanceX=>3, :max_neighs=>200)))
    push!(RM, PDBenchmark.NameParam(:LinearRepulsionModel, (100.0,), Dict(:blocks=>(4,3), :distanceX=>3, :max_neighs=>200)))

    f = env -> begin
        pin_ = (env.type .== 3)
        pin_max = maximum(env.y[2, pin_])
        env.Params = Dict("pin" => pin_, "pin_max"=>pin_max)
        env.Out = Dict("Force" => zeros(3, Steps), "Displacement" => zeros(1, Steps))
        env.Collect! = (env, step) -> begin 
                env.Out["Force"][:, step] = sum(env.f[:,env.Params["pin"]], dims=2)
                env.Out["Displacement"][1, step] = -(maximum(env.y[1,env.Params["pin"]]) - env.Params["pin_max"])
                if step%fwf==0
                    println("∂P/∂y = 48EI/L^3 = 4.0e-3 * E = $(env.Out["Force"][2, step]/env.Out["Displacement"][1, step])")
                end
            end
    end

    test = PDBenchmark.Test(solver, geom, gen_mat, spc_mat, bc, RM, f; names=["LSupport", "RSupport", "Pin", "Beam"])

    return test
end