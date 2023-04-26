using Test 
using JSON3 
#using Pinecone
include("../src/Pinecone.jl")

APIKEY = ENV["PINECONE_API_KEY"]
context = Pinecone.init(APIKEY, "us-west1-gcp")

INDEX = "drivertest3"
NAMESPACE = "mynamespace"
index = Pinecone.Index(INDEX);

testdict = Dict{String, Any}("genre"=>"documentary", "year"=>2019);
testvector = Pinecone.PineconeVector("testid", [0.3,0.11,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3], testdict)
testvector2 = Pinecone.PineconeVector("testid2", [0.3,0.12,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3], testdict)
tvraw1 = [0.3,0.12,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3]

@testset "Fetch Test" begin
    rv = Pinecone.upsert(context, index, [testvector, testvector2])
    rvjson = JSON3.read(rv)
    @test rvjson["upsertedCount"] == 2

    rv = Pinecone.upsert(context, index, [testvector, testvector2],  NAMESPACE)
    rvjson = JSON3.read(rv)
    @test rvjson["upsertedCount"] == 2

    rv = Pinecone.fetch(context, index, ["testid"], NAMESPACE)
    @JSON3.pretty(rv)

    rvjson = JSON3.read(rv)
    @test haskey(rvjson, "vectors")
    @test haskey(rvjson, "namespace")
    @test rvjson.namespace == NAMESPACE
    @test haskey(rvjson["vectors"], "testid")

    # Fetch with namespace defaulting to "" in the method
    rv = Pinecone.fetch(context, index, ["testid"])
    rvjson = JSON3.read(rv)
    @test haskey(rvjson, "vectors")
    @test haskey(rvjson, "namespace")
    @test rvjson.namespace == ""
    @test haskey(rvjson["vectors"], "testid")

    # Fetch with empty string namespace
    rv = Pinecone.fetch(context, index, ["testid"], "")
    rvjson = JSON3.read(rv)
    @test haskey(rvjson, "vectors")
    @test haskey(rvjson, "namespace")
    @test rvjson.namespace == ""
    @test haskey(rvjson["vectors"], "testid")

    #test exceeded max ids
    @test_throws ArgumentError Pinecone.fetch(context, index, ["testid" for i in 1:1001])
    
end