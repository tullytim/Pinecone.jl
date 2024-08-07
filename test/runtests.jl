using Test
using Pinecone
using JSON3

include("testcreatedelete.jl")
include("testwhoami.jl")
include("testtypes.jl")
include("testlistindexes.jl")
include("testdescribeindexstats.jl")
include("testdelete.jl")
include("testfetch.jl")
include("testquery.jl")
include("testupsert.jl")
include("testscale.jl")
include("v3.jl")

println("*************DONE**************")
