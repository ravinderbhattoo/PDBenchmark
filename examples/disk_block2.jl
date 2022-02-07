using Pkg; Pkg.activate(".")
import PDBenchmark
using PDMesh

Steps = 150
solver = PDBenchmark.NameParam(:qs, (Steps, 1.0), Dict(:filewrite_freq=>1, :neigh_update_freq=>1, :out_dir=>"DiskBlockVV2", :start_at=>0))
func = () -> begin changetype(Cuboid([-5 5; -5 5; 0 1]), out -> begin x=out[1]; sum((x[1:2, :] .- vec([-1.5, 0.0])).^2, dims=1) .< 1.0^2 end, 2) end
obj = () -> begin changetype(func(), out -> begin x=out[1]; sum((x[1:2, :] .- vec([1.5, 0.0])).^2, dims=1) .< 1.0^2 end, 2) end
geom = PDBenchmark.NameParam(obj, (), Dict(:resolution=>0.05, :rand_=>0.02))


Es = 20.0
nu = 0.2
K = Es/3/(1-2nu)
G = Es/2/(1+nu)
rho = 1000.0
horizon = 0.15
s = 0.05

gen_mat = PDBenchmark.NameParam(:GeneralMaterial, (horizon), Dict(:max_neigh=>300))

spc_mat = PDBenchmark.NameParam(:OrdinaryStateBasedSpecific, ([K, K, K], [G, G, G], [s, s, s], [rho, rho], ), Dict())

bc_f1 = x -> (vec(sum((x[1:2, :] .- vec([1.5, 0.0])).^2, dims=1) .< 1.0^2), [0.005, 0.005, 0], [1.5, 0.0, 0.0])
bc_f2 = x -> (vec(sum((x[1:2, :] .- vec([-1.5, 0.0])).^2, dims=1) .< 1.0^2), [0.005, 0.005, 0], [-1.5, 0.0, 0.0])

bc = [PDBenchmark.NameParam(:ScaleBC, (bc_f1,)), PDBenchmark.NameParam(:ScaleBC, (bc_f2,))]
RM = [PDBenchmark.NameParam(:LinearRepulsionModel, (Es, ), Dict(:blocks=>(1,), :distanceX=>3, :max_neighs=>200))]

f = env -> begin
    # env.Params = Dict("left" => (env.y[1,:] .< 2))
    # env.Out = Dict("Force" => zeros(3, Steps))
    # env.Collect! = (Params, Out, step) -> Out["Force"][:, step] = sum(env.f[:,Params["left"]], dims=2)
end

test = PDBenchmark.Test(solver, geom, gen_mat, spc_mat, bc, RM, f)

PDBenchmark.run(test)