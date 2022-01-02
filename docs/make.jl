using Documenter
using Pinecone

makedocs(
    sitename = "Pinecone.jl",
    format = Documenter.HTML(prettyurls = false),
    pages = [
        "Introduction" => "index.md",
        "API" => "api.md"
    ]
)

deploydocs(
    repo = "github.com/tullytim/Pinecone.jl.git",
    devbranch = "main"
)
