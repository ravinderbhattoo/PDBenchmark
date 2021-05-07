export Bar, create

"""
    Bar
    123 Geom
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