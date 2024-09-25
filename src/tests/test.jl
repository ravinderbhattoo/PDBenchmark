export PDTest, Test, TParam, realize
export stage!, run!

"""
    PDTest

An abstract type for tests. It is used to pass tests to the run function.
"""
abstract type PDTest end

"""
    TParam

A type for test parameters. It is used to pass parameters to the test functions.
"""
struct TParam
    name
    args
    kwargs
end

"""
    TParam(name::Union{Function, Type}; args=(), kwargs=Dict())

Create a TParam object.

# Arguments
- `name::Union{Function, Type}`: The name of the parameter.

# Keyword Arguments
- `args::Tuple`: The arguments of the parameter.
- `kwargs::Dict`: The keyword arguments of the parameter.
"""
function TParam(name::Union{Function, Type}; args=(), kwargs=Dict())
    TParam(name, args, kwargs)
end

"""
    realize(m::TParam, module_::Module)

Realizes the parameter `m` by calling `getproperty(module_, m.name)(m.args...; m.kwargs...)`.

# Arguments
- `m::TParam`: The parameter to be realized.
- `module_::Module`: The module in which the function is defined.

# Returns
- The return value of the `m`.
"""
function realize(m::TParam, module_::Module)
    getproperty_(module_, m.name)(m.args...; m.kwargs...)
end

"""
    realize(m::TParam)

Realizes the parameter `m` by calling `m.name(m.args...; m.kwargs...)`.

# Arguments
- `m::TParam`: The parameter to be realized.
"""
function realize(m::TParam)
    m.name(m.args...; m.kwargs...)
end

"""
    realize(m::TParam, args...; kwargs...)

Realizes the parameter `m` by calling `m.name(args..., m.args...; kwargs..., m.kwargs...)`.

# Arguments
- `m::TParam`: The parameter to be realized.
- `args...`: The arguments to be passed to the function.

# Keyword Arguments
- `kwargs...`: The keyword arguments to be passed to the function.

# Returns
- The return value of the `m`.
"""
function realize(m::TParam, args...; kwargs...)
    m.name(args..., m.args...; kwargs..., m.kwargs...)
end

function Base.show(io::IO, m::TParam)
    print(io, "TParam($(m.name), $(m.args), $(m.kwargs))")
end


@inline function ifiterable(x)
    typeof(x) <: AbstractArray
end


"""
    Test <: PDTest

An abstract type for tests. It is used to pass tests to the run function.

# Fields
- `solver`: The solver to be used.
- `geom`: The geometry of the blocks.
- `gen_material`: The material of the blocks.
- `spc_material`: The special material of the blocks.
- `bc`: The boundary conditions of the blocks.
- `RM`: The contact models of the blocks.
- `f`: The post environment function.
- `dt`: The time step.
- `steps`: The number of steps.
- `blocknames`: The names of the blocks.
- `testname`: The name of the test.
- `info`: The information of the test.
- `cprint`: The function to be used for printing.
- `units`: Whether to use units.
"""
struct Test <: PDTest
    solver
    geom
    gen_material
    spc_material
    bc
    RM
    f
    dt
    steps
    blocknames
    testname
    info
    cprint
    units
end

"""
    Test(args...; dt=1.0, steps=1000,
            names=nothing,
            testname="Test ABC",
            info="",
            cprint=(x)-> nothing,
            units=true
            )

Create a Test object.

# Arguments
- `args...`: The arguments of the test.

# Keyword Arguments
- `dt::Float64`: The time step.
- `steps::Int`: The number of steps.
- `names::Union{Nothing, Vector{String}}`: The names of the blocks.
- `testname::String`: The name of the test.
- `info::String`: The information of the test.
- `cprint::Function`: The function to be used for printing.
- `units::Bool`: Whether to use units.
"""
function Test(args...; dt=1.0, steps=1000,
                names=nothing,
                testname="Test ABC",
                info="",
                cprint=(x)-> nothing,
                units=true
                )
    if isa(typeof(names), Nothing)
        names = ["Block $i" for i in 1:length(args[3])]
    end
    Test([ ifiterable(i) ? i : [i] for i in args]...,
            dt, steps, names, testname, info, cprint, units)
end

function Base.show(io::IO, test::Test)
    print(io, getPanel(test))
end

function getPanel(test::Test; ptype=PeriDyn.SPanel, width=Term.default_width())
    defaultPanel(args...; width=width-6, kwargs...) = Panel(
        args...; kwargs...,
        width=width,
        title_style="bold red")
    parse_args(item) = begin
        @green "$(item.name)\n" *
        "$(variable_color("Args")): $(item.args)\n" *
        "$(variable_color("KwArgs")): $(item.kwargs)\n"
    end
    parse_args2(item) = begin
        @green "$(item.name)\n" *
        "$(variable_color("Args")): \n$(mapreduce((i)->PeriDyn.variable_txt(i),
                                                *, item.args; init=""))" *
        "$(variable_color("KwArgs")): \n$(mapreduce((i)->PeriDyn.variable_color(i[1])*": "*PeriDyn.variable_txt(i[2]),
                                                *, item.kwargs; init=""))\n"
    end
    showblock(items, name) = begin
        defaultPanel(mapreduce(parse_args2, *, items; init=""),
                title=name)
    end
    material_blocks = [Panel(
                parse_args(test.geom[i]) *
                parse_args(test.gen_material[i]) *
                parse_args2(test.spc_material[i]),
                title= "$(test.blocknames[i])",
                title_style="bold blue",
                width=width-12
                )
                for i in 1:length(test.blocknames)]
    return ptype(
        [
            defaultPanel("$(test.info)",
                title="📜 Info"),
            defaultPanel(material_blocks,
                title="🧱 Material Blocks"),
            showblock(test.bc, "📍 Boundary Conditions"),
            showblock(test.RM, "💥 Contact Models"),
            defaultPanel("$(test.solver[1])",
                "$(variable_color("dt")): $(test.dt)",
                "$(variable_color("steps")): $(test.steps)",
                title="⏳ Solver"),
            defaultPanel("$(test.f[1])",
                title="🛠️  Post env function")
        ],
        title="🧪 "*test.testname,
        subtitle="End of test report",
        subtitle_style="bold blue",
        subtitle_justify=:center,
        width=width,
        justify=:center
    )
end


function getproperty_(a, b)
    if typeof(b)==Symbol
        return getproperty(a, b)
    elseif typeof(b) <: Union{Function, Type}
        return b
    else
        error("It should be either a Symbol or a Function.")
    end
end



"""
    stage!(test::Test)

Stage the test for running.

# Arguments
- `test::Test`: The test to be staged.

# Returns
- `env::Environment`: The environment of the test.
- `solver::Solver`: The solver of the test.
- `func::Function`: The run function of the test.
"""
function stage!(test::Test)

    print(test)

    solver = test.solver[1]

    println("Creating geometry blocks...")
    geoms = [PDMaterialPoints.create(getproperty_(PDBenchmark, x.name)(x.args...); x.kwargs...) for x in test.geom]

    println("Creating general materials...")
    gen_mat = [realize(x, y)  for (x, y) in zip(test.gen_material, geoms)]

    println("Creating specific materials...")
    spc_mat = [realize(x)  for x in test.spc_material]

    println("Creating material blocks...")
    block = [PeriDyn.PeridynamicsMaterial(x, y; name=name) for (x, y, name) in zip(gen_mat, spc_mat, test.blocknames)]

    println("Creating contact models...")
    RM = []
    for x in test.RM
        kwargs_ = copy(x.kwargs)
        bks = pop!(kwargs_, :blocks)
        y = [block[i] for i in bks]
        push!(RM, getproperty_(PeriDyn, x.name)(x.args..., y...; kwargs_...))
    end

    env =  PeriDyn.Env(1, block, RM, Any[], test.dt; units=test.units)
    env.cprint = test.cprint

    println("Creating boundary conditions...")
    BC = [getproperty_(PeriDyn, x.name)(x.args[1](env)...; x.kwargs...) for x in test.bc]

    for bc in BC
        push!(env.boundary_conditions, bc)
    end

    for ff in test.f
        ff(env)
    end

    steps = test.steps
    out_dir_ = lowercase(replace(test.testname, " " => "_"))

    function func(env_, solver; out_dir=nothing, kwargs...)
        if isa(typeof(out_dir), Nothing)
            out_dir = out_dir_
        end
        simulate!([env_], steps, solver; out_dir=out_dir, kwargs...)
        PeriDyn.write_data(joinpath(out_dir, "env_Out.jld"); env_.Out...)
    end

    return env, solver, func
end

"""
    run!(test::Test; append_date=false, pseudorun=false, kwargs...)

Runs the test `test` and returns the environment `env` after the simulation.

# Arguments
- `test::Test`: The test to be run.
- `append_date::Bool=false`: If true, the date will be appended to the output directory.
- `pseudorun::Bool=false`: If true, the simulation will not be run.
- `kwargs...`: Keyword arguments to be passed to `PeriDyn.run!` function.

!!! tip "Keyword Arguments are same as for `PeriDyn.run!` function"
    - `steps`: Int64, the number of steps to run. Default is 100.
    - `filewrite_freq`: Int64, the frequency of writing data files to disk. Default is 10.
    - `neigh_update_freq`: Int64, the frequency of updating neighbors. Default is 1.
    - `average_prop_freq`: Int64, the frequency of calculating average properties. Default is 1.
    - `out_dir`: String, the directory where the data files are saved. Default is "datafile".
    - `start_at`: Int64, the starting step. Default is 0.
    - `write_from`: Int, the starting index of the data files. Default is 0.
    - `ext`: Symbol, the extension of the data files. Default is :jld.
    - `max_part`: Int, the maximum number of particles in a neighborhood. Default is 30.

# Returns
- `env::Env`: The environment after the simulation.
"""
function run!(test::Test; append_date=false, pseudorun=false, print_env=false, kwargs...)

    env, solver, env_solve! = stage!(test)
    if print_env
        show(env)
    end
    if ~pseudorun
        env_solve!(env, solver; append_date=append_date, kwargs...)
    end

    return env
end