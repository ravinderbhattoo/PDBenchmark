using Pkg
Pkg.activate("examples")
Pkg.instantiate()

println("Number of threads: ", Threads.nthreads())

using Revise
using PDBenchmark
using PeriDyn

Es = 70 # GPa
nu = 0.15 # Poisson's ratio
K = Es/3/(1-2nu) # Bulk modulus
G = Es/2/(1+nu) # Shear modulus
rho = 2800.0 # kg/m^3
cs = 0.05 # critical stretch
resolution = 0.2 # mm
horizon = 3*resolution
# C = 18K/(pi*horizon^4)

gen_mat = TParam(GeneralMaterial, (horizon), Dict(:max_neigh=>200))
spc_mat = TParam(BondBasedSpecific, ([K], [cs], [rho], ), Dict())
# spc_mat = TParam(OrdinaryStateBasedSpecific, ([K], [cs], [rho], ), Dict())

solver = DSVelocityVerlet()
# solver = QSDrag(1.0e-2, 1.0e-2)

test = IndentationTest(;gen_mat=gen_mat,
                    spc_mat=spc_mat,
                    resolution=resolution,
                    angle = 90.0,
                    solver=solver,
                    steps=20000
                    )

out_dir="IndentationTestBrittle/$(spc_mat.name)/$(typeof(solver))"
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
    log_data(Fz_ind=env.Out[:Force][3, env.time_step])
    log_data(z_ind=env.Out[:Displacement][env.time_step])
end

env.cprint = cprint

# env.y[1:2, :] .*= 1.01

func(env, solver; out_dir=out_dir,
                        ext=:data,
                        filewrite_freq=100,
                        neigh_update_freq=100,
                        average_prop_freq=10,
                        append_date=false
                        )

# y = env.Out[:Force][1, :]
# x = vec(env.Out[:Displacement])

# using Plots


# plot(x, y, linewidth=1, label=raw"F_x")
# xlabel!("Displacement")
# ylabel!("Force")
# savefig("output/$(out_dir)/figure.png")