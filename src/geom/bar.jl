export Bar, NotchedBar

"""
    Bar <: PDBGeom

A bar geometry.

# Fields
- `obj::Cuboid`: a Cuboid object
"""
struct Bar <: PDBGeom
    obj
end

"""
    Bar(;bounds=[0.0 10; 0 2;0 2])

Create a Bar object.

# Keyword Arguments
- `bounds::Array{Float64, 2}`: bounds of the bar
"""
function Bar(;bounds=[0.0 10; 0 2;0 2])
    Bar(Cuboid(bounds))
end


"""
    function create(geom::Bar; resolution=0.1, rand_=0.05, type=1)

Create a PDMaterialPoints object from a Bar object.

# Arguments
- `geom::Bar`: a Bar object

# Keyword Arguments
- `resolution::Float64`: resolution of the bar
- `rand_::Float64`: randomization of the bar
- `type::Int`: type of the bar

# Returns
- `dict`: a dictionary same as the one returned by `PDMaterialPoints.create`
"""
function PDMaterialPoints.create(geom::Bar; resolution=0.1, rand_=0.05, type=1)
    block = geom.obj
    return PDMaterialPoints.create(block; resolution=resolution, rand_=rand_, type=type)
end

"""
    NotchedBar <: PDBGeom

A notched bar geometry.

# Fields
- `obj::Cuboid`: a Cuboid object
- `notch::Array{Float64, 2}`: a 2D array of notches
"""
struct NotchedBar <: PDBGeom
    obj
    notch
end

"""
    NotchedBar(;bounds=[0.0 7.0; 0 1;0 1], notch=nothing)

Create a NotchedBar object.

# Keyword Arguments
- `bounds::Array{Float64, 2}`: bounds of the bar
- `notch::Array{Float64, 2}`: a 2D array of notches
"""
function NotchedBar(;bounds=[0.0 7.0; 0 1;0 1], notch=nothing)
    NotchedBar(Cuboid(bounds), notch)
end

"""
    function create(geom::NotchedBar; resolution=0.1, rand_=0.05, type=1)

Create a PDMaterialPoints object from a NotchedBar object.

# Arguments
- `geom::NotchedBar`: a NotchedBar object

# Keyword Arguments
- `resolution::Float64`: resolution of the bar
- `rand_::Float64`: randomization of the bar
- `type::Int`: type of the bar

# Returns
- `dict`: a dictionary same as the one returned by `PDMaterialPoints.create`
"""
function PDMaterialPoints.create(geom::NotchedBar; resolution=0.1, rand_=0.05, type=1)
    obj = geom.obj
    if geom.notch !== nothing
        obj = PDMaterialPoints.delete(obj, out -> begin x=out[:x]; prod((x .<= geom.notch[:, 2]) .& (x .>= geom.notch[:, 1] ), dims=1) end)
    end
    return PDMaterialPoints.create(obj; resolution=resolution, rand_=rand_, type=type)
end