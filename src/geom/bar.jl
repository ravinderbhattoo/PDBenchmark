export Bar, NotchedBar

"""
    Bar
"""
struct Bar <: PDBGeom
    obj
end

function Bar(;bounds=[0.0 10; 0 2;0 2])
    Bar(Cuboid(bounds))
end

function PDMesh.create(geom::Bar; resolution=0.1, rand_=0.05, type=1)
    block = geom.obj
    return PDMesh.create(block; resolution=resolution, rand_=rand_, type=type)
end

"""
    NotchedBar
"""
struct NotchedBar <: PDBGeom
    obj
    notch
end

function NotchedBar(;bounds=[0.0 7.0; 0 1;0 1], notch=nothing)
    NotchedBar(Cuboid(bounds), notch)
end

function PDMesh.create(geom::NotchedBar; resolution=0.1, rand_=0.05, type=1)
    obj = geom.obj
    if geom.notch !== nothing
        obj = PDMesh.delete(obj, out -> begin x=out[1]; prod((x .<= geom.notch[:, 2]) .& (x .>= geom.notch[:, 1] ), dims=1) end)
    end
    return PDMesh.create(obj; resolution=resolution, rand_=rand_, type=type)
end