# using Pkg; Pkg.activate(".")
# Pkg.develop(url="../../PeriDyn")
# Pkg.develop(url="../../PDMaterialPoints")

using PDBenchmark

Es = 100
nu = 0.2
K = Es/3/(1-2nu)
G = Es/2/(1+nu)
rho = 1000.0
cs = 0.15
reso = 0.1
horizon = 3*reso

C = 18K/(pi*horizon^4)

gen_mat = TParam(:GeneralMaterial, (horizon), Dict(:max_neigh=>200))

spc_mat = TParam(:OrdinaryStateBasedSpecific, ([K], [G], [cs], [rho], ), Dict())

test = PDBenchmark._3PointBending(;gen_mat=gen_mat, spc_mat=spc_mat, resolution=reso, solver_=:vv, out_dir="Flexure3PointOSB_vv")

env = PDBenchmark.run!(test)

y = env.Out["Force"][1, :]
x = vec(env.Out["Displacement"])

using Plots

plot(x, y, marker=4, linewidth=1, label=raw"F_x")
xlabel!("Displacement")
ylabel!("Force")
savefig("./output/osb_vv.png")
