using Test 
using JSON3 
#using Pinecone
include("../src/Pinecone.jl")

APIKEY = ENV["PINECONE_API_KEY"]
CLOUDENV="us-west1-gcp"

context = Pinecone.init(APIKEY, CLOUDENV)

INDEX = "filter-example" #fixed
NAMESPACE = "mynamespace"

@testset "Test describe_index_stats()" begin
    context = Pinecone.init(APIKEY, CLOUDENV)
    result = Pinecone.describe_index_stats(context, Pinecone.Index(INDEX));
    @test result !== nothing
    @test typeof(result) == String
    parsed = JSON3.read(result)
    @test haskey(parsed, "namespaces") == true
    @test haskey(parsed, "dimension") == true
 end