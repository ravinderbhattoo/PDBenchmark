using Pkg; Pkg.activate(".")
import PDBenchmark

test = PDBenchmark.BarTensileQS()
env = PDBenchmark.run(test)

y = env.Out["Force"][1, :]
x = 1:length(y)

using Plots

plot(x, y, marker=4, linewidth=6, label=raw"F_x")
xlabel!("Steps")
ylabel!("Force")
savefig("./output/plot.png")