using Pkg
Pkg.activate("examples")
Pkg.instantiate()

println("Number of threads: ", Threads.nthreads())

using Revise
using PDBenchmark
using PeriDyn
using Unitful
using Plots
using TimerOutputs

Plots.set_default_backend!(:gr)

enable_timer!(PeriDyn.timings)
PeriDyn.set_loglevel(0)
PDBenchmark.set_loglevel(0)

# # Fuzed silica
# # density in g/cm3 = 2.2
# ρ = 2.2u"g/cm^3"
# # Young's modulus in N/mm2 = 73.1
# E = 73.1u"N/mm^2"
# # Poisson's ratio = 0.17
# ν = 0.17
# # Shear modulus in N/mm2 = 28.9
# G = 28.9u"N/mm^2"
# # Bulk modulus in N/mm2 = 38.5
# K = 38.5u"N/mm^2"
# resolution = 0.15u"mm"
# horizon = 3*resolution

# # How do we calculate the critical stretch in peridynamics from the above parameters?
# # We can use the following formula:
# cs = sqrt(2*G/(ρ*horizon)) # this expression is derived




Es = 70u"GPa" # Young's modulus
nu = 0.15 # Poisson's ratio
K = Es/3/(1-2nu) # Bulk modulus
G = Es/2/(1+nu) # Shear modulus
rho = 2800.0u"kg/m^3" # density
cs = 0.01 # critical stretch
resolution = 0.15u"mm"
horizon = 3*resolution

gen_mat = TParam(GeneralMaterial, (horizon), Dict(:max_neigh=>200))

spc_mat = TParam(BondBasedSpecific, ([K], [cs], [rho], ), Dict())
# spc_mat = TParam(OrdinaryStateBasedSpecific, ([K], [G], [cs], [rho], ), Dict())

solver = DSVelocityVerlet()
# solver = QSDrag(1.0e-2, 1.0e-2)

wave_velocity = sqrt(Es / rho)
dt = uconvert(u"μs", resolution / 10 / wave_velocity)

steps = 100000
angle = 90.0
test = IndentationTest(;gen_mat=gen_mat,
                    dt=dt,
                    spc_mat=spc_mat,
                    resolution=resolution,
                    angle = angle,
                    solver=solver,
                    steps=steps
                    );
                    
out_dir=joinpath(homedir(), "Downloads", "IndentationTest", "$(spc_mat.name)", "$(typeof(solver))")

try
    rm(out_dir; recursive=true)
catch
    nothing
end
mkpath(out_dir)

env, solver, func = stage!(test);

# using BenchmarkTools
# PeriDyn.set_loglevel(0)
# print(env)
# env.material_blocks[2].general.deformed .= 1

# @btime PeriDyn.update_mat_acc!(env)
# @btime PeriDyn.update_mom_acc!(env)
# @btime PeriDyn.update_contact_acc!(env)
# reset_timer!(PeriDyn.timings); update_acc!(env); show(PeriDyn.timings)

# save_state!("$(out_dir)/prerun.data", env; force=true)

println("Number of particles: ", size(env.y, 2))

# env.y[1:2, :] .*= 1.01

envs = PeriDyn.ustrip_to_default(env);

# enable_timer!(PeriDyn.timings)
# reset_timer!(PeriDyn.timings);
# for i in 1:10
#     update_acc!(envs);
# end
# show(PeriDyn.timings)

unit_x = unit(eltype(env.y))
unit_F = unit(eltype(env.f)) * unit(eltype(env.mass))
unit_F = unit(uconvert(u"N", 1unit_F))

function makeplot(env)
    F = vec(env.Out[:Force][:, 3])
    x = vec(env.Out[:Displacement])
    N = Int(size(x, 1) // 2)
    plot(x[1:N], F[1:N], linewidth=1, label="Loading", legend=:topleft)
    plot!(x[N:end], F[N:end], linewidth=1, label="Unloading", legend=:topleft)
    scatter!([x[env.time_step]], [F[env.time_step]], label="", markersize=5)
    xlabel!("Displacement ($unit_x)")
    ylabel!("Force ($unit_F)")
    savefig("$(out_dir)/Fvsd.png")
end



envs.cprint = env -> begin
    if env.time_step%10==0
        log_data(
            Δz=env.Out[:Displacement][env.time_step],
            Fz=env.Out[:Force][env.time_step, 3],
            )
        # PeriDyn.meminfo_julia()
        # show(PeriDyn.timings)
        # reset_timer!(PeriDyn.timings)
    end
end

func(envs, solver; out_dir=out_dir,
                        ext=:data,
                        filewrite_freq=100,
                        neigh_update_freq=100,
                        average_prop_freq=100,
                        append_date=false
                        )

