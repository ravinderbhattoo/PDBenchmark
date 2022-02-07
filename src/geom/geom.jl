export PDBGeom

abstract type PDBGeom end

"""
    function create(geom::PDBGeom; resolution=0.1, rand_=0.05, type=1)

This create a PDB geometry.
"""
function PDMesh.create(geom::PDBGeom; resolution=0.1, rand_=0.05, type=1)
    error("Not implemented for type **$(typeof(geom))** yet.")
end

include("./bar.jl")