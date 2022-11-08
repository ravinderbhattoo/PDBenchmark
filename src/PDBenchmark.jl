module PDBenchmark

# Write your package code here.
using PeriDyn
using PDMesh
using Plots

set_multi_threading = PeriDyn.set_multi_threading

function set_cuda(x)
    PeriDyn.set_cuda(x)
    PDMesh.set_cuda(x)
end

include("./tests/test.jl")
include("./tests/standardtests.jl")
include("./geom/geom.jl")
# include("./standard_simulations/standard_simulations.jl")
end
