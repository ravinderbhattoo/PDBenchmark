"""
This module contains the tests for flexure.

Implementations:
1. 3 Point Beam Bending Test
2. 4 Point Beam Bending Test
3. 3 Point Beam Bending Test with Notch
4. 4 Point Beam Bending Test with Notch
"""

export _3PointNotchedBeamBendingTest, _3PointBeamBendingTest, _4PointNotchedBeamBendingTest, _4PointBeamBendingTest
export BeamBendingTest

"""
    _3PointBeamBendingTest(args...; testname="3 Point Beam Bending Test", kwargs...)

It is a test for beam bending. The test is performed by applying a point load
on the top of the specimen. The specimen is a beam. Both ends of the beam are
supported by a pin support.
# Arguments
- `args...`: The arguments of the test. The arguments are passed to the
    `BeamBendingTest` function.

# Keyword Arguments
- `testname::String`: The name of the test.
- `kwargs...`: The keyword arguments of the test. The keyword arguments are
    passed to the `BeamBendingTest` function. `_4point` is set to `false` by default.

# Returns
- The return value of the `BeamBendingTest` function.
"""
function _3PointBeamBendingTest(args...; testname="3 Point Beam Bending Test", kwargs...)
    BeamBendingTest(args...; _4point=false, testname=testname, kwargs...)
end

"""
    _3PointNotchedBeamBendingTest(args...; testname="3 Point Notched Beam Bending Test", kwargs...)

It is a test for beam bending. The test is performed by applying a point load
on the top of the specimen. The specimen is a beam. Both ends of the beam are
supported by a pin support.

# Arguments
- `args...`: The arguments of the test. The arguments are passed to the
    `_3PointBeamBendingTest` function.

# Keyword Arguments
- `testname::String`: The name of the test.
- `kwargs...`: The keyword arguments of the test. The keyword arguments are
    passed to the `_3PointBeamBendingTest` function. `notched` is set to `true` by default.

# Returns
- The return value of the `BeamBendingTest` function.
"""
function _3PointNotchedBeamBendingTest(args...; testname="3 Point Notched Beam Bending Test", kwargs...)
    _3PointBeamBendingTest(args...; notched=true, testname=testname, kwargs...)
end

"""
    _4PointBeamBendingTest(args...; testname="4 Point Beam Bending Test", kwargs...)

It is a test for beam bending. The test is performed by applying a point load
on the top of the specimen. The specimen is a beam. Both ends of the beam are
supported by a pin support.

# Arguments
- `args...`: The arguments of the test. The arguments are passed to the
    `BeamBendingTest` function.

# Keyword Arguments
- `testname::String`: The name of the test.
- `kwargs...`: The keyword arguments of the test. The keyword arguments are
    passed to the `BeamBendingTest` function. `_4point` is set to `true` by default.

# Returns
- The return value of the `BeamBendingTest` function.
"""
function _4PointBeamBendingTest(args...; testname="4 Point Beam Bending Test", kwargs...)
    BeamBendingTest(args...; _4point=true, testname=testname, kwargs...)
end

"""
    _4PointNotchedBeamBendingTest(args...; testname="4 Point Notched Beam Bending Test", kwargs...)

It is a test for beam bending. The test is performed by applying a point load
on the top of the specimen. The specimen is a beam. Both ends of the beam are
supported by a pin support.

# Arguments
- `args...`: The arguments of the test. The arguments are passed to the
    `_4PointBeamBendingTest` function.

# Keyword Arguments
- `testname::String`: The name of the test.
- `kwargs...`: The keyword arguments of the test. The keyword arguments are
    passed to the `_4PointBeamBendingTest` function. `notched` is set to `true` by default.

# Returns
- The return value of the `BeamBendingTest` function.
"""
function _4PointNotchedBeamBendingTest(args...; testname="4 Point Notched Beam Bending Test", kwargs...)
    _4PointBeamBendingTest(args...; notched=true, testname=testname, kwargs...)
end


"""
    function BeamBendingTest(; gen_mat=nothing, spc_mat=nothing, resolution=0.1,
            solver=DSVelocityVerlet(), dt=1.0, steps=1000,
            notched=false, _4point=false, testname="Beam Bending Test")

It is a test for beam bending. The test is performed by applying a point load
on the top of the specimen. The specimen is a beam. Both ends of the beam are
supported by a pin support.

# Keyword Arguments
- `gen_mat`: The general material of the specimen.
- `spc_mat`: The specific material of the specimen.
- `resolution`: The resolution of the specimen.
- `solver`: The solver of the simulation.
- `dt`: The time step of the simulation.
- `steps`: The number of steps of the simulation.
- `notched`: Whether the specimen is notched.
- `_4point`: Whether the specimen is a 4 point beam bending test.
- `testname`: The name of the test.
"""
function BeamBendingTest(; gen_mat=nothing, spc_mat=nothing, resolution=0.1,
            solver=DSVelocityVerlet(), dt=1.0, steps=10000, width2height_ratio=1.0,
            notched=false, _4point=false, testname="Beam Bending Test")

    # generate the geometry
    geom = TParam[]
    names = String[]

    # pin and support
    disc_radius = 0.5

    # beam
    length_ = 12.0
    height = 1.0
    width = width2height_ratio * height

    # Support 1
    obj = () -> move(Disk(disc_radius, width), by=[height,  -disc_radius, 0.0])
    push!(geom, TParam(obj, (), Dict(:resolution=>resolution, :type=>1)))
    push!(names, "Support 1")

    # Support 2
    obj = () -> move(Disk(disc_radius, width), by=[length_-height, -disc_radius, 0.0])
    push!(geom, TParam(obj, (), Dict(:resolution=>resolution, :type=>2)))
    push!(names, "Support 2")

    if ~_4point
        # Pin load 1
        obj = () -> move(Disk(disc_radius, width),
                            by=[length_/2,  height+disc_radius, 0.0])
        push!(geom, TParam(obj, (), Dict(:resolution=>resolution, :type=>3)))
        push!(names, "Pin load 1")
    else
        # Pin load 1
        obj = () -> move(Disk(disc_radius, width),
                            by=[lenlength_gth/2 - 1.5*height,  height+disc_radius, 0.0])
        push!(geom, TParam(obj, (), Dict(:resolution=>resolution, :type=>3)))
        push!(names, "Pin load 1")

        # Pin load 2
        obj = () -> move(Disk(disc_radius, width),
                            by=[length_/2 + 1.5*height,  height+disc_radius, 0.0])
        push!(geom, TParam(obj, (), Dict(:resolution=>resolution, :type=>4)))
        push!(names, "Pin load 2")
    end

    # Beam
    bounds = [0 length_; 0 height; 0 width]
    if notched
        notch_width = max(3*resolution, height/8)
        notch_height = height/4
        notch = [length_/2-notch_width/2 length_/2+notch_width/2;
                0.0 notch_height;
                -Inf Inf]
        obj = () -> NotchedBar(bounds=bounds, notch=notch)
    else
        obj = () -> Bar(bounds=bounds)
    end
    push!(geom, TParam(obj, (), Dict(:resolution=>resolution, :type=> _4point ? 5 : 4)))
    push!(names, "Beam")

    # generate the material
    general_material = map(x -> gen_mat, 1:length(geom))
    mat = realize(spc_mat)
    density = mat.density
    bulk_modulus = mat.bulk_modulus
    spc_mat0 = TParam(SkipSpecific, (density, ), Dict())
    specific_material = vcat(map(x->spc_mat0, 1:length(geom)-1), [spc_mat])

    wv = sqrt(first(bulk_modulus)/first(density))
    dt = resolution / wv / 5

    total_time = dt*steps
    speed = height / total_time

    # generate the boundary conditions
    zero_ = zero(speed)
    if typeof(solver) <: QuasiStaticSolver
        velocity = [zero_, -speed * 10, zero_]
        steps = Int64(steps / 10)
    else
        velocity = [zero_, -speed, zero_]
    end

    bc_f1 = env -> (vec(env.type .== 1 .|| env.type .== 2), )
    if _4point
        bc_f2 = env -> (vec(env.type .== 3 .|| env.type .== 4),
                               velocity)
    else
        bc_f2 = env -> (vec(env.type .== 3), velocity)
    end
    bc = [TParam(FixBC; args=(bc_f1,)), TParam(MoveBC; args=(bc_f2,))]

    # generate the contact models
    RM = TParam[]
    stifness = bulk_modulus[1, 1] * 18 /pi / (3*resolution)^4
    rmodel = (args...) -> TParam(LinearSpringContactModel, (stifness,),
                        Dict(:blocks=>args, :distanceX=>2, :max_neighs=>100))

    n = length(geom)
    for i in 1:n-1
        push!(RM, rmodel(n, i)) # beam with rest of the blocks
    end
    push!(RM, rmodel(n)) # beam

    f = env -> begin
        pin_ = (env.type .== 3)
        pin_max = maximum(env.y[2, pin_])
        env.Params = Dict(:pin => pin_, :pin_max=>pin_max)
        env.Out = Dict(:Force => zeros(3, steps), :Displacement => zeros(1, steps))
        env.Collect! = (env, step) -> begin
                env.Out[:Force][:, step] = sum(env.f[:,env.Params[:pin]], dims=2)
                env.Out[:Displacement][1, step] = -(maximum(env.y[2, env.Params[:pin]]) - env.Params[:pin_max])
            end
    end

    test = PDBenchmark.Test(solver, geom, general_material, specific_material, bc, RM, f;
                    dt = dt,
                    steps = steps,
                    names=names,
                    testname=testname)
    return test
end