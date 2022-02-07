using Pkg; Pkg.activate(".")
import PDBenchmark
using PDMesh

Steps = 1500
solver = PDBenchmark.NameParam(:vv, (Steps), Dict(:filewrite_freq=>10, :neigh_update_freq=>10, :out_dir=>"DiskBlockVV", :start_at=>0))
obj = () -> begin changetype(Cuboid([-5 5; -5 5; 0 3]), out -> begin x=out[1]; sum((x[1:2, :] .- vec([-2, 0.0])).^2, dims=1) .< 1.0^2 end, 2) end
geom = PDBenchmark.NameParam(obj, (), Dict(:resolution=>0.2, :rand_=>0.02))


Es = 20
nu = 0.2
K = Es/3/(1-2nu)
G = Es/2/(1+nu)
rho = 1000.0
horizon = 0.6
s = 0.05

gen_mat = PDBenchmark.NameParam(:GeneralMaterial, (horizon), Dict(:max_neigh=>300))

spc_mat = PDBenchmark.NameParam(:OrdinaryStateBasedSpecific, ([K, K, K], [G, G, G], [s, s, s], [rho, rho], ), Dict())

bc_f1 = x -> (vec(sum((x[1:2, :] .- vec([-2, 0.0])).^2, dims=1) .< 1.0^2), [0.0005, 0.0005, 0], [-2.0, 0.0, 0.0])

bc = [PDBenchmark.NameParam(:ScaleBC, (bc_f1,))]
RM = [PDBenchmark.NameParam(:LinearRepulsionModel, (Es,), Dict(:blocks=>(1,), :distanceX=>3, :max_neighs=>200))]

f = env -> begin
    # env.Params = Dict("left" => (env.y[1,:] .< 2))
    # env.Out = Dict("Force" => zeros(3, Steps))
    # env.Collect! = (Params, Out, step) -> Out["Force"][:, step] = sum(env.f[:,Params["left"]], dims=2)
end

test = PDBenchmark.Test(solver, geom, gen_mat, spc_mat, bc, RM, f)


PDBenchmark.run(test)