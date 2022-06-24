module PDBenchmark

# Write your package code here.
using PeriDyn
using PDMesh
using Plots

set_multi_threading = PeriDyn.set_multi_threading

include("./tests/test.jl")
include("./tests/standardtests.jl")
include("./geom/geom.jl")

end
