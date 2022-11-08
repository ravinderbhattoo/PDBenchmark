push!(LOAD_PATH,"../src/")

using Documenter, DocThemeIndigo
using PeriDyn, PDMesh, PDBenchmark

indigo = DocThemeIndigo.install(PDBenchmark)

makedocs(sitename="PDBenchmark",
        build="../docs",
        sidebar_sitename=nothing,
        modules=[PDBenchmark],
        format = Documenter.HTML(;
            prettyurls = false,
            assets=String[indigo]),
        pages = [
            "Home" => "index.md",
            "Table of contents" => "toc.md",
            "Examples" => "examples.md",
            "Index" => "list.md",
            "Autodocs" => "autodocs.md"
        ]
        )