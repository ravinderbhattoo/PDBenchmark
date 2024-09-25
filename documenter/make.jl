using Pkg
Pkg.activate(".")

# function load_packages()
#     Pkg.add("Documenter")
#     Pkg.add("DocThemeIndigo")
#     Pkg.add("Revise")
#     Pkg.add("Dates")

#     Pkg.develop(path="../../PDMaterialPoints.jl/")
#     Pkg.develop(path="../../PeriDyn/")
#     Pkg.develop(path="../")
#     Pkg.instantiate()
# end

# try
#     load_packages()
# catch
#     @warn "Could not load packages. Re-doing..."
# finally
#     rm("Project.toml")
#     load_packages()
# end

using Revise
using Documenter, DocThemeIndigo
using PDBenchmark, PeriDyn
using Dates

indigo = DocThemeIndigo.install(PDBenchmark)

format = Documenter.HTML(;
    footer="Updated: $(mapreduce(x-> " "*x*" ", *, split(string(now()), "T")))",
    #"*string(Documenter.HTML().footer),
    prettyurls = get(ENV, "CI", nothing) == "true",
    # assets = [indigo],
    assets = ["assets/font.css", "assets/color.css"],
    size_threshold = 1024 * 1024 * 1 # MB

)

# format = Documenter.LaTeX(;platform="none")

function doit()
    makedocs(sitename="PDBenchmark",
        build = "../docs",
        format = format,
        modules=[PDBenchmark],
        pages = [
            "Home" => "index.md",
            "Table of Contents" => "toc.md",
            "Index" => "list.md",
            "Autodocs" => "autodocs.md"
        ]

    )
end


doit()

