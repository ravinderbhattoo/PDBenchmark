#exports
export PeriDynTest, Test, run, NameParam

Solvers = Dict(:qs => :quasi_static!, :vv => :velocity_verlet!, :min => :minimize!)

abstract type PeriDynTest end

struct NameParam
    name
    args
    kwargs
end

function NameParam(name, args::Tuple{Any})
    NameParam(name, args, Dict())
end

function Base.length(x::NameParam) 1 end
function Base.first(x::NameParam) x end
function Base.length(x::Function) 1 end
function Base.first(x::Function) x end

struct Test <: PeriDynTest
    solver
    geom
    gen_material
    spc_material
    bc
    RM
    f
    dt
    blocknames

    function Test(args...; dt=1.0, names=nothing)
        if names === nothing
            names = ["Default name" for i in 1:length(args[3])]
        end
        new([length(i)==1 ? [first(i)] : i for i in args]..., dt, names)
    end
end


function run(test::T) where T <: PeriDynTest
    error("No run defined for test of type **$(typeof(test))**")
end

function getproperty_(a, b)
    if typeof(b)==Symbol
        return getproperty(a, b)
    elseif typeof(b) <: Function
        return b
    else
        error("It should be either a Symbol or a Function.")
    end
end

function stage!(test::Test)
    solver = getproperty(PeriDyn, Solvers[first(test.solver).name])
    skwargs = first(test.solver).kwargs
    sargs = first(test.solver).args

    println("Creating geometry blocks...")
    geoms = [PDMesh.create(getproperty_(PDBenchmark, x.name)(x.args...); x.kwargs...) for x in test.geom]

    println("Creating general materials...")
    gen_mat = [getproperty_(PeriDyn, x.name)(y, x.args...; x.kwargs...)  for (x, y) in zip(test.gen_material, geoms)]

    println("Creating specific materials...")
    spc_mat = [getproperty_(PeriDyn, x.name)(x.args...; x.kwargs...) for x in test.spc_material]

    println("Creating material blocks...")
    block = [getproperty_(PeriDyn, :PeridynamicsMaterial)(x, y; name=name) for (x,y, name) in zip(gen_mat, spc_mat, test.blocknames)]

    RM = []
    for x in test.RM
        bks = pop!(x.kwargs, :blocks)
        y = [block[i] for i in bks]
        push!(RM, getproperty_(PeriDyn, x.name)(x.args..., y...; x.kwargs...))
    end

    env =  PeriDyn.Env(1, block, RM, Any[], test.dt)

    BC = [getproperty_(PeriDyn, x.name)(x.args[1](env)...; x.kwargs...) for x in test.bc]

    for bc in BC
        push!(env.boundary_conditions, bc)
    end

    for ff in test.f
        ff(env)
    end

    println("\n\n")
    println("=========================")
    println("     Pre Test Report     ")
    println("=========================")
    println("\n=========Solver==========")
    println(solver)
    println("\tArgs: ", sargs)
    println("\tKwargs: ", skwargs)
    println("\tTime step: ", test.dt)

    println("\n====General Materials====")
    for i in 1:length(gen_mat)
        println("$i.)")
        println("Block name: $(test.blocknames[i])")
        show(gen_mat[i])
    end

    println("\n===Specific Materials ===")
    for i in 1:length(spc_mat)
        println("$i.)")
        println("Block name: $(test.blocknames[i])")
        show(spc_mat[i])
    end

    println("\n===Boundary Conditions===")
    for i in 1:length(BC)
        println("$i.)")
        show(BC[i])
    end

    println("\n====Repulsive Models ====")
    for i in 1:length(RM)
        println("$i.)")
        show(RM[i])
    end

    println("=========================")
    println("     Test Report End     ")
    println("=========================")
    println("\n\n")

    function func(env_; append_date=false)
        simulate([env_], sargs...; solver=first(test.solver).name, append_date=append_date, skwargs...)
    end
    return env, func

end

function run!(test::Test; append_date=false, pseudorun=false)

    env, env_solve! = stage!(test)
    if ~pseudorun
        env_solve!(env, append_date=append_date)
    end

    return env
end