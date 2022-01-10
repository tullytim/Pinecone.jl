using Test 

#include("../src/Pinecone.jl")
using Pinecone

APIKEY = ENV["PINECONE_API_KEY"]
CLOUDENV="us-west1-gcp"

context = Pinecone.init(APIKEY, CLOUDENV)

INDEX = "filter-example"
NAMESPACE = "mynamespace"
index = Pinecone.Index(INDEX);

@testset "Scale Index()" begin
    context = Pinecone.init(APIKEY, CLOUDENV)
    index = Pinecone.Index(INDEX)
    @test_throws ArgumentError Pinecone.scale_index(context, index, -1)
    result = Pinecone.scale_index(context, index, 2)
    @test result !== nothing
    @test result == true
 end