using PDMaterialPoints
using PeriDyn
using Unitful

##############################################################################
# Simulation Material
##############################################################################
resolution = 1.0u"mm"

obj = Cuboid([0 100; 0 100; 0 5]u"mm")

f = out -> begin 
x = out[:x]
@. (x[1, :] - 50u"mm")^2 + (x[2, :] - 50u"mm")^2 < (10u"mm")^2
end 

obj = delete(obj, f)

out = create(obj, resolution=resolution, rand_=0.05)



y0, v0, x, volume, type = unpack(out)

horizon = 3*resolution

gen_mat = GeneralMaterial(y0, v0, x, volume, type, horizon; max_neigh=200)

Es = 1.0e1u"GPa"
nu = 0.15 # for bond based peridynamics
K = Es/3/(1-2nu)
G = Es/2/(1+nu)
rho = 2440.0u"kg/m^3"

cs = 0.1
εy = 0.5*cs
σy = Es * εy

print("σy: ", σy, "\n")

# spc_mat = BondBasedSpecific([K], [cs], [rho])

spc_mat = ElastoPlasticSolidSpecific([K], [G], [cs], [rho], [σy])

mat = PeridynamicsMaterial(gen_mat, spc_mat)

##############################################################################
# Boundary condition
##############################################################################

mask = vec(x[1, :] .< 5.0u"mm" )
BC1 = FixBC(mask)

mask = vec(x[1, :] .> 95.0u"mm" )
velocity = 0.001
rate = [velocity, 0, 0]u"mm/ms"
BC2 = MoveBC(mask, rate)

BCs = [BC1, BC2]

##############################################################################
# Solver
##############################################################################
solver = DSVelocityVerlet()
# solver = QSDrag(1, 1.0e-1; x_tol=1.0e-3, f_tol=1.0e-5)
Steps, fwf, nuf = 8000, 100, 10

##############################################################################
# Simulation Env
##############################################################################
dt = 1u"ms" 
env = Env(1, [mat], [], BCs, dt)


out_dir=joinpath(homedir(), "Downloads", reduce(*, "Platewithhole"), "$(mat.name)", "$(typeof(solver))")

run!([env], Steps, solver;
        filewrite_freq=fwf, neigh_update_freq=nuf, 
        out_dir=out_dir, start_at=0, ext=:data)

println("Simulation Finished. :)")













 