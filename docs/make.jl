using Documenter, YAXArrayBase

makedocs(
    modules = [YAXArrayBase],
    format = Documenter.HTML(; prettyurls = get(ENV, "CI", nothing) == "true"),
    authors = "Fabian Gans",
    sitename = "YAXArrayBase.jl",
    pages = Any["index.md"]
    # strict = true,
    # clean = true,
    # checkdocs = :exports,
)

deploydocs(
    repo = "github.com/meggart/YAXArrayBase.jl.git",
    push_preview = true
)
