# Indentation test
export IndentationTest

"""
    IndentationTest(; gen_mat=nothing, spc_mat=nothing, resolution=1.0,
            angle=120.0, sides=3,
            solver=DSVelocityVerlet(), dt=1.0, steps=8000, testname="Indentation Test")

It is a test for indentation test. The test is performed by applying a displacement
to the indentor. The displacement is applied in the direction of the axis of
the indentor. The indentor is a triangular pyramid.

# Keyword Arguments
- `gen_mat`: The general material.
- `spc_mat`: The specific material.
- `resolution::Float64`: The resolution of the test.
- `angle::Float64`: The angle of the indentor.
- `sides::Int`: The number of sides of the indentor.
- `solver::Solver`: The solver.
- `dt::Float64`: The time step.
- `steps::Int`: The number of steps.
- `testname::String`: The name of the test.
"""
function IndentationTest(; gen_mat=nothing,
            spc_mat=nothing,
            resolution=1.0,
            angle=120.0,
            sides=3,
            solver=DSVelocityVerlet(),
            dt=1.0,
            steps=8000,
            testname="Indentation Test")

    # generate the geometry
    geom = TParam[]
    names = String[]

    ulength = unit(resolution)
    # block dim
    length_ = 10.0*ulength
    L = length_/2

    # Indentor dim
    height = 2.0*ulength
    # sides
    # angle

    # movement
    Δx = height/4 + 3*resolution
    total_Δx = 2Δx
    speed = total_Δx / steps / dt

    println(@yellow(@bold "INFO: "), "Δx = $(Δx),  speed = $speed, steps = $steps, dt = $dt")

    # Indentor
    indentor = Indentor(angle, height; sides=sides)
    obj = () -> move(indentor, by=[0.0, 0, 1]*resolution)
    push!(geom, TParam(obj, (), Dict(:resolution=>resolution, :type=>1, :rand_=>0.05)))
    push!(names, "Indentor")

    if 2L > 20*resolution
        L_ = L / 2
    else
        L_ = L
    end

    # Specimen
    obj = () -> Cuboid([-L L; -L L; -2L_ 0L_])
    push!(geom, TParam(obj, (), Dict(:resolution=>resolution, :type=>2, :rand_=>0.05)))
    push!(names, "Specimen")

    # generate the material
    general_material = map(x -> gen_mat, 1:length(geom))
    mat = realize(spc_mat)
    density = mat.density
    bulk_modulus = mat.bulk_modulus
    spc_mat0 = TParam(SkipSpecific, (density, ), Dict())
    specific_material = vcat(map(x->spc_mat0, 1:length(geom)-1), [spc_mat])

    # generate the boundary conditions
    if typeof(solver) <: QuasiStaticSolver
        velocity = [0.0, 0.0, -10]*speed
        steps = Int64(steps / 10)
    else
        velocity = [0.0, 0.0, -1]*speed
    end

    bc_f1 = env -> (vec(env.y[3, :] .<= -2L_ + 3*resolution), )
    bc_f2 = env -> (vec(env.type .== 1), velocity, Int64(steps / 2))
    bc_f3 = env -> (vec(env.type .== 2), )
    bc = [
            TParam(FixBC; args=(bc_f1,)),
            TParam(ToFroBC; args=(bc_f2,)),
            TParam(ContainerBC; args=(bc_f3,), kwargs=Dict(:limits=>[-2L 2L; -2L 2L; -3L L]))
            ]

    # generate the contact models
    RM = TParam[]
    K = bulk_modulus[1, 1]
    mfactor = 1
    stifness = 18K /pi / (3*resolution)^4
    rmodel = (args...) -> TParam(LinearSpringContactModel, (mfactor*stifness,),
                        Dict(:blocks=>args, :distanceX=>1.5, :distanceD=>3.0, :max_neighs=>200))

    n = length(geom)
    for i in 1:n-1
        push!(RM, rmodel(n, i)) # speciment with rest of the blocks
    end

    # specimen
    push!(RM, TParam(LinearSpringContactModel, (stifness,),
                Dict(:blocks=>(n, ), :distanceX=>1.5, :max_neighs=>200)))

    f = env -> begin
        indentor_ = (env.type .== 1)
        indentor_max = maximum(env.y[3, indentor_])
        env.Params = Dict(:indentor => indentor_,
                            :indentor_max=>indentor_max)
        env.Out = Dict(:Force => zeros(eltype(first(env.f) * first(env.mass)), steps, 3),
                            :Displacement => zeros(eltype(env.y), steps))
        env.Collect! = (env, step) -> begin
                env.Out[:Force][step, :] .= sum(env.f[:, env.Params[:indentor]] .* env.mass[env.Params[:indentor]]', dims=2)
                env.Out[:Displacement][step] = -(maximum(env.y[3, env.Params[:indentor]]) - env.Params[:indentor_max])
            end
    end

    cprint = (env) -> begin
        d = env.Out[:Displacement][env.time_step]
        F = env.Out[:Force][env.time_step, 3]
        log_data(Fz=F)
        log_data(Δx=d)
    end

    test = PDBenchmark.Test(solver, geom, general_material, specific_material, bc, RM, f;
                    dt = dt,
                    steps = steps,
                    names=names,
                    testname=testname,
                    cprint=cprint,
                    info="Indentation simulation. \
                    The indentor is moved at a fixed speed. \
                    Force on the indentor and displacement of the indentor are recorded. \
                    " *

"""

Type of indentor: $(indentor)

 v = $(round(unit(speed), speed, sigdigits=3)), α = $(round(angle, sigdigits=3)), faces=$(sides)
        ↓↓↓↓↓↓↓
        _______             z|  /y
        \\     /              | /
    _____\\ α /_____          |/______x
   /      \\ /     /|
  /        `     / |
 /______________/  | H = $(2L_)
 |              |  |
 |              |  |
 |              | / B = $(2L)
 |______________|/
    L = $(2L)

""")
    return test
end