export PDBGeom

"""
    PDBGeom

Abstract type for PDBGeom objects.
A PDBGeom object is a representation of a geometry of an object.
"""
abstract type PDBGeom end

"""
    function create(geom::PDBGeom; resolution=0.1, rand_=0.05, type=1)

Create a PDMaterialPoints object from a PDBGeom object.

# Arguments
- `geom::PDBGeom`: a PDBGeom object

# Keyword Arguments
- `resolution::Float64`: resolution of the bar
- `rand_::Float64`: randomization of the bar
- `type::Int`: type of the bar

# Returns
- `dict`: a dictionary same as the one returned by `PDMaterialPoints.create`
"""
function PDMaterialPoints.create(geom::PDBGeom; resolution=0.1, rand_=0.05, type=1)
    error("Not implemented for type **$(typeof(geom))** yet.")
end


# include all files in the folder
include("./bar.jl")