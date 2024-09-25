module PDBenchmark

# Write your package code here.
using Term
using Unitful
using PeriDyn
using PDMaterialPoints

variable_color = PeriDyn.variable_color

"""
    set_device(x)

Set the device to run on.

# Arguments
- `x::Symbol`: The device to run on. Can be `:cpu` or `:cuda`.
"""
function set_device(x)
    PeriDyn.set_device(x)
    PDMaterialPoints.set_device(x)
end

"""
    set_loglevel(x)

Set the log level.

# Arguments
- `x::Symbol`: The log level. Can be `:debug`, `:info`, `:warn`, `:error`, or `:fatal`.
"""
function set_loglevel(x)
    PeriDyn.set_loglevel(x)
    # PDMaterialPoints.set_loglevel(x)
end

include("tests/test.jl")
include("tests/standardtests.jl")
include("geom/geom.jl")
include("standard_simulations/standard_simulations.jl")


end
