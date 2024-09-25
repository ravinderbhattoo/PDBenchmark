# using Pkg
# Pkg.activate("examples")
# Pkg.instantiate()

println("Number of threads: ", Threads.nthreads())

# using Revise
using Unitful

using PDBenchmark
using PeriDyn
using Plots


Es = 1.0e1u"GPa"
nu = 0.15 # for bond based peridynamics
max_strain = 0.15

cs = 0.1
resolution = 10.0u"mm"
Length = 100*resolution
Width = 20*resolution
horizon = 3*resolution

K = Es/3/(1-2nu)
G = Es/2/(1+nu)
rho = 2440.0u"kg/m^3"
εy = 0.5*cs
σy = Es * εy

print("σy: ", σy, "\n")


wv = sqrt(Es/rho)
println("Wave velocity: ", wv)

dt = 0.1 * resolution / wv
Steps = 15000

total_time = dt*Steps 
strain_rate = max_strain / total_time
println("Strain rate: $(uconvert(u"m/m/s", strain_rate))")


gen_mat = TParam(GeneralMaterial, (horizon), Dict(:max_neigh=>200))


# spc_mat = TParam(BondBasedSpecific, ([K], [cs], [rho], ), Dict())
spc_mat = TParam(OrdinaryStateBasedSpecific, ([K], [G], [cs], [rho], ), Dict())
function stress_strain_curve(x; σy=σy, Es=Es)
    σ = Es * x
end

# spc_mat = TParam(ElastoPlasticSolidSpecific, ([K], [G], [cs], [rho], [σy] ), Dict())
# function stress_strain_curve(x; σy=σy, Es=Es)
#     σ = Es * x
#     map((i)->min(i, σy), σ)
# end


solver = DSVelocityVerlet()
# solver = QSDrag(1.0e-2, 1.0e-3)

test = PDBenchmark.TensileBar(;gen_mat=gen_mat,
                                dt=dt,
                                max_strain=max_strain,
                                steps=Steps,
                                effective_length=Length,
                                w=Width,
                                spc_mat=spc_mat,
                                resolution=resolution,
                                solver=solver
)

out_dir=joinpath(homedir(), "Downloads", reduce(*, split(test.testname)), "$(spc_mat.name)", "$(typeof(solver))")

# try
#     rm(out_dir; recursive=true)
# catch
#     nothing
# end
# mkpath(out_dir)

mkpath(out_dir)

env, solver, func = stage!(test)



PeriDyn.set_loglevel(2)
save_state!(joinpath(out_dir, "prerun.data"), env)

println("Number of particles: ", size(env.y, 2))

old_cprint = env.cprint

function makeplot(env)
    t = env.time_step
    x = vec(env.Out[:Strain_x])[1:t]
    y = vec(env.Out[:Stress_x])[1:t]
    fig = plot(title="Stress vs Strain")
    xlabel!("εₓ")
    ylabel!("σₓ")
    plot!(fig, x, stress_strain_curve(x), linewidth=1, label=raw"Elasto-Plastic")
    plot!(fig, x, y, linewidth=1, label="$(spc_mat.name)")
    display(fig)
    # savefig(joinpath(out_dir, "figure.png"))
end

env.cprint = function(env)
    old_cprint(env)
    if env.time_step % 100 == 0
        makeplot(env)
    end
end

print(env)

try
    func(env, solver; out_dir=out_dir,
                        ext=:data,
                        filewrite_freq=100,
                        neigh_update_freq=100,
                        average_prop_freq=100,
                        append_date=false
                        )
catch e
    error(e)
end
