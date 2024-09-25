using Pkg
Pkg.activate("examples")
Pkg.instantiate()

println("Number of threads: ", Threads.nthreads())

using Revise
using PDBenchmark
using PeriDyn

Es = 100.0
nu = 0.25 # for bond based peridynamics
K = Es/3/(1-2nu)
G = Es/2/(1+nu)
rho = 2440.0
cs = 0.5
resolution = 0.1
horizon = 3*resolution

wv = sqrt(Es/rho)
time_step = 1.0 * resolution / wv
println("Wave velocity: ", wv)

gen_mat = TParam(GeneralMaterial, (horizon), Dict(:max_neigh=>200))
spc_mat = TParam(BondBasedSpecific, ([K], [cs], [rho], ), Dict())

solver = DSVelocityVerlet()

test = PulsePropagationBar(;gen_mat=gen_mat,
                                dt=time_step,
                                init_velocity=0.1*wv,
                                effective_length=20.0,
                                spc_mat=spc_mat,
                                resolution=resolution,
                                solver=solver,
                                steps=500)

out_dir="PulsePropagationBar/$(spc_mat.name)/$(typeof(solver))"
try
    rm("./output/$(out_dir)"; recursive=true)
catch
    nothing
end
mkpath("./output/$(out_dir)")

env, solver, func = stage!(test)

# using BenchmarkTools
PeriDyn.set_loglevel(0)
# print(env)
# env.material_blocks[2].general.deformed .= 1

# @btime PeriDyn.update_mat_acc!(env)
# @btime PeriDyn.update_mom_acc!(env)
# @btime PeriDyn.update_contact_acc!(env)
# reset_timer!(PeriDyn.timings); update_acc!(env); show(PeriDyn.timings)

save_state!("output/$(out_dir)/prerun.data", env)

println("Number of particles: ", size(env.y, 2))

function cprint(env)
    log_data(Stress_x=env.Out[:Stress_x][env.time_step])
    log_data(time=env.Out[:time][env.time_step])
end

env.cprint = cprint

# env.y[1:2, :] .*= 1.01

func(env, solver; out_dir=out_dir,
                        ext=:data,
                        filewrite_freq=10,
                        neigh_update_freq=10,
                        average_prop_freq=10,
                        append_date=false
                        )

y = vec(env.Out[:Stress_x])
x = vec(env.Out[:time])

using Plots

plot(x, y, linewidth=1, label=raw"S_x")
plot!([20/wv, 20/wv], [-4, 4])

xlabel!("time")
ylabel!("Stress_x")
savefig("output/$(out_dir)/figure.png")












