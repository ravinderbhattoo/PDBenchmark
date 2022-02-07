using Documenter, DocThemeIndigo
using PeriDyn, PDMesh, PDBenchmark

indigo = DocThemeIndigo.install(PDBenchmark)

makedocs(sitename="PDBenchmark", 
        modules=[PDBenchmark],
        format = Documenter.HTML(;
            prettyurls = false,
            assets=String[indigo]),
        pages = [
            "Home" => "pdbench.md",
            "Table of contents" => "toc.md",
            "Examples" => "examples.md",
            "Index" => "index.md",
            "Autodocs" => "autodocs.md"
        ]
        )