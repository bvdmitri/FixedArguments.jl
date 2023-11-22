using FixedArgumentsCallable
using Documenter

DocMeta.setdocmeta!(FixedArgumentsCallable, :DocTestSetup, :(using FixedArgumentsCallable); recursive=true)

makedocs(;
    modules=[FixedArgumentsCallable],
    authors="Bagaev Dmitry <bvdmitri@gmail.com> and contributors",
    repo="https://github.com/bvdmitri/FixedArgumentsCallable.jl/blob/{commit}{path}#{line}",
    sitename="FixedArgumentsCallable.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://bvdmitri.github.io/FixedArgumentsCallable.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/bvdmitri/FixedArgumentsCallable.jl",
    devbranch="main",
)
