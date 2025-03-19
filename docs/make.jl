using windc_household_model
using Documenter

DocMeta.setdocmeta!(windc_household_model, :DocTestSetup, :(using windc_household_model); recursive=true)


const _PAGES = [
    "Introduction" => ["index.md"],
    "Data Overview" => ["set_overview.md", "parameter_overview.md"],
]


makedocs(;
    modules=[windc_household_model],
    authors="Mitch Phillipson",
    sitename="WiNDC Household",
    format=Documenter.HTML(;
        canonical="https://julia-mpsge.github.io/windc_household_model.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=_PAGES
)

deploydocs(;
    repo = "github.com/julia-mpsge/windc_household_model.jl",
    devbranch = "main",
    branch = "gh-pages"
)

#deploydocs(
#    repo = "https://github.com/uw-windc/WiNDC.jl",
#    target = "build",
#    branch = "gh-pages",
#    versions = ["stable" => "v^", "v#.#" ],
#)