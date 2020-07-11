using Documenter, AlgebraOfGraphics, Literate, Glob
# avoid font caching warning in docs
import Pkg
Pkg.pkg"add https://github.com/JuliaPlots/CairoMakie.jl#pv/update"
using AbstractPlotting, CairoMakie, MakieLayout
CairoMakie.activate!()
scatter(rand(10), rand(10))

# generate examples
GENERATED = joinpath(@__DIR__, "src", "generated")
SOURCE_FILES = Glob.glob("*.jl", GENERATED)
foreach(fn -> Literate.markdown(fn, GENERATED), SOURCE_FILES)

makedocs(
         sitename="Algebra of Graphics",
         pages = Any[
                     "index.md",
                     "generated/tutorial.md",
                     "generated/internals.md",
                    ]
        )

deploydocs(
    repo = "github.com/JuliaPlots/AlgebraOfGraphics.jl.git",
    push_preview = true
)
