using Pkg
Pkg.activate(".")

using Revise
# Pkg.develop(url="../PeriDyn")
# Pkg.develop(url="../PDMesh")

using PDBenchmark

PDBenchmark.set_multi_threading(true)

const Es = 100.0
const nu = 0.25 # for bond based peridynamics

K = Es/3/(1-2nu)
G = Es/2/(1+nu)

const rho = 2440.0

wv = sqrt(Es/rho)
println("Wave velocity: ", wv)

const cs = 0.5
const reso = 0.1
const horizon = 3*reso

time_step = 1.0 * reso / wv

C = 18K/(pi*horizon^4)

gen_mat = PDBenchmark.NameParam(:GeneralMaterial, (horizon), Dict(:max_neigh=>200))

spc_mat = PDBenchmark.NameParam(:BondBasedSpecific, ([C], [cs], [rho], ), Dict())

solver = :vv

st_st = Dict(
    :qs => Dict(
            :printevery => 1,
            :fwf => 1,
            :Steps => 20,
            :max_strain => 0.1,
            ),
    :vv => Dict(
            :printevery => 10,
            :fwf => 10,
            :Steps => 20000,
            :max_strain => 0.1
            )
    )

out_dir = "TensileBarBB_" * string(solver)

try
    foreach(rm, filter(endswith(".data"), readdir("./output/"*out_dir, join=true)))
catch
    nothing
end

test = PDBenchmark.TensileBar(;gen_mat=gen_mat, dt=time_step, st_st[solver]..., max_strain=0.1,
                                spc_mat=spc_mat, resolution=reso, solver_=solver, out_dir=out_dir, makeplot=true, trueE=Es)

env, solvef! = PDBenchmark.stage!(test)

solvef!(env)

y = env.Out["Stress_x"][1, :]
x = vec(env.Out["Strain_x"])

using Plots

plot(x, y, marker=4, linewidth=1, label=raw"F_x")
plot!([0.0, x[end]], [0.0, Es*x[end]], marker=4, linewidth=1, label=raw"F_x")
xlabel!("Strain_x")
ylabel!("Stress_x")
savefig("./output/bb_vv.png")















