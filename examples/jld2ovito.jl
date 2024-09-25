filename, N = ARGS[1:2]
N = Int(Meta.parse(N))

function clean(s)
    if s[1]=='-'
        s = s[2:end]
        return clean(s)
    else
        return s
    end
end

kwargs = Dict()
for item in ARGS[3:end]
    key, value = split(item, "=")
    key = Symbol(clean(key))
    kwargs[key] = Int(Meta.parse(value))
end

using Pkg
Pkg.activate("examples")
Pkg.instantiate()

using PeriDyn

println("Converting JLD files to Ovito files...")
PeriDyn.jld2ovito(filename, N; kwargs...)

#