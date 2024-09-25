# using Pkg; Pkg.activate("examples")

using Revise
using PDBenchmark
using PeriDyn

Es = 10
nu = 0.2
K = Es/3/(1-2nu)
G = Es/2/(1+nu)
rho = 10000.0
cs = 0.05
resolution= 0.1
horizon = 3*resolution

C = 18K/(pi*horizon^4)

gen_mat = TParam(GeneralMaterial, (horizon), Dict(:max_neigh=>200))

spc_mat = TParam(BondBasedSpecific, ([K], [cs], [rho], ), Dict())
# spc_mat = TParam(OrdinaryStateBasedSpecific, ([K], [cs], [rho], ), Dict())

solver = DSVelocityVerlet()

# solver = QSDrag(1.0e-2, 1.0e-1; x_tol=1.0e-6, f_tol=1.0e-5)

if_notched = false # false
if_4point = false # true
test = BeamBendingTest(;gen_mat=gen_mat, spc_mat=spc_mat, resolution=resolution,
                    solver=solver, notched=if_notched, _4point=if_4point, steps=10000)

testname="$(spc_mat.name)_$(typeof(solver))_4P_$(if_4point)_notch_$(if_notched)"
OUTDIR = joinpath(homedir(), "Downloads", "PDBenchmark", "FlexureTest", testname)                    

env = PDBenchmark.run!(test; out_dir=OUTDIR, ext=:data, average_prop_freq=100)

using Plots

y = env.Out[:Force][:, :]
x = vec(env.Out[:Displacement])

plot(x, y', linewidth=1, label=raw"F_z")
xlabel!("Displacement")
ylabel!("Force")

savefig(joinpath(OUTDIR, "force_displacement.png"))
