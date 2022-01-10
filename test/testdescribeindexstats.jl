using Test 
using JSON3 
using Pinecone

APIKEY = ENV["PINECONE_API_KEY"]
CLOUDENV="us-west1-gcp"

context = Pinecone.init(APIKEY, CLOUDENV)

INDEX = "filter-example"
NAMESPACE = "mynamespace"
index = Pinecone.Index(INDEX);

@testset "Test describe_index_stats()" begin
    context = Pinecone.init(APIKEY, CLOUDENV)
    index = PineconeIndex(INDEX)
    result = Pinecone.describe_index_stats(context, index)
    @test result !== nothing
    @test typeof(result) == String
    parsed = JSON3.read(result)
    @test haskey(parsed, "namespaces") == true
    @test haskey(parsed, "dimension") == true
 end