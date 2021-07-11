using Pkg; Pkg.activate(".")
Pkg.develop(url="../PeriDyn")
Pkg.develop(url="../PDMesh")

using PDBenchmark

Es = 10
nu = 0.2
K = Es/3/(1-2nu)
G = Es/2/(1+nu)
rho = 1000.0
cs = 0.15
reso = 0.1
horizon = 3*reso

C = 18K/(pi*horizon^4)

gen_mat = PDBenchmark.NameParam(:GeneralMaterial, (horizon), Dict(:max_neigh=>200))

spc_mat = PDBenchmark.NameParam(:BondBasedSpecific, ([C], [cs], [rho], ), Dict())

test = PDBenchmark.TensileBar(;gen_mat=gen_mat, spc_mat=spc_mat, resolution=reso, solver_=:qs, file_prefix="TensileBarBB_qs")

env = PDBenchmark.run!(test)

y = env.Out["Force"][1, :]
x = vec(env.Out["Displacement"])

using Plots

plot(x, y, marker=4, linewidth=1, label=raw"F_x")
xlabel!("Displacement")
ylabel!("Force")
savefig("./output/bb_qs.png")