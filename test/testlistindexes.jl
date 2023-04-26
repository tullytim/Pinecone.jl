using Test 
using JSON3 
#using Pinecone
include("../src/Pinecone.jl")

APIKEY = ENV["PINECONE_API_KEY"]
CLOUDENV="us-west1-gcp"

context = Pinecone.init(APIKEY, CLOUDENV)

INDEX = "filter-example"
NAMESPACE = "mynamespace"

@testset "Test list_indexes()" begin
    result = Pinecone.list_indexes(context)
    println("list_indexes() result: ", result)
    @test result !== nothing
    @test typeof(result) == String
    parsed = JSON3.read(result)
    @test length(parsed) >= 0
 end