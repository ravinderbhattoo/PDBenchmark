#exports
export PeriDynTest, Test, run, NameParam

Solvers = Dict(:qs => :quasi_static!, :vv => :velocity_verlet!, :min => :minimize!)

abstract type PeriDynTest end

struct NameParam
    name
    args
    kwargs
end

struct Test <: PeriDynTest 
    solver::NameParam
    geom::NameParam
    gen_material::NameParam
    spc_material::NameParam
    bc::NameParam
    RM::NameParam
    f::Function
end

function run(test::T) where T <: PeriDynTest
    error("No run defined for test of type **$(typeof(test))**")    
end

function getproperty_(a, b)
    if typeof(b)==Symbol
        return getproperty(a, b)
    elseif typeof(b)==Function
        return b
    else
        error("It should be either a Symbol or a Function.")
    end
end

function run(test::Test)
    solver = getproperty(PeriDyn, Solvers[test.solver.name])
    s_params = test.solver.kwargs

    geom = getproperty_(PDBenchmark, test.geom.name)
    g_params = test.geom.kwargs   
    out = create(geom(); g_params...)
    x, v, y, vol, type = out

    gen_mat_f = getproperty_(PeriDyn, test.gen_material.name)
    gm_params = test.gen_material.args
    gen_mat = gen_mat_f(y, v, x, vol, gm_params..., max_neigh=200)

    BC = getproperty_(PeriDyn, test.bc.name)(test.bc.args(out)...)

    spc_mat_f = getproperty_(PeriDyn, test.spc_material.name)
    sm_params = test.spc_material.args
    spc_mat = spc_mat_f(sm_params..., gen_mat)
    
    block_f = getproperty_(PeriDyn, Symbol(replace(string(test.spc_material.name), "Specific"=>"Material")))
    block = block_f(1, gen_mat, spc_mat)
    
    rm_f = getproperty_(PeriDyn, test.RM.name)
    RM = rm_f(test.RM.args..., block; test.RM.kwargs...)
    
    env =  PeriDyn.Env(1, [block], [RM], [BC], 1)

    test.f(env)
    
    solver([env],test.solver.args...; test.solver.kwargs...)

    return env    
end