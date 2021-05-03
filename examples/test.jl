using Pkg; Pkg.activate(".")
import PDBenchmark

rho = 1000.0
horizon = 0.3
s = 0.5
gen_mat = PDBenchmark.NameParam(:GeneralMaterial, (rho, horizon, s), Dict())

Es = 20
nu = 0.2
K = Es/3/(1-2nu)
G = Es/2/(1+nu)
spc_mat = PDBenchmark.NameParam(:OrdinaryStateBasedSpecific, (K, G), Dict())

test = PDBenchmark.BarTensileQS(; gen_mat=gen_mat, spc_mat=spc_mat)
env = PDBenchmark.run(test)

y = env.Out["Force"][1, :]
x = 1:length(y)

using Plots

plot(x, y, marker=4, linewidth=6, label=raw"F_x")
xlabel!("Steps")
ylabel!("Force")
savefig("./output/plot.png")