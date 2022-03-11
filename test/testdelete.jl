using Test 
using JSON3 
using Pinecone

APIKEY = ENV["PINECONE_API_KEY"]
CLOUDENV="us-west1-gcp"

context = Pinecone.init(APIKEY, CLOUDENV)

INDEX = "filter-example"
NAMESPACE = "mynamespace"
index = Pinecone.Index(INDEX);

testdict = Dict{String, Any}("genre"=>"documentary", "year"=>2019);
v1 = [0.3,0.11,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3]
v2 = [0.9, 0.8, 0.7, 0.6, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]

ns = "deletenamespace"
context = Pinecone.init(APIKEY, CLOUDENV)
index = PineconeIndex(INDEX)
meta = [Dict{String,Any}("foo"=>"bar"), Dict{String,Any}("bar"=>"baz")]

# first clean up everything in our namespace

result = Pinecone.delete(context, index, String[], true, "")

@testset verbose = true "Test delete()" begin  
    #insert some dummy data to be deleted and then sleep to wait for any indexing
    result = Pinecone.upsert(context, index, ["zipA", "zipB"], [v1, v2], meta, ns)
    @test result !== nothing
    @test typeof(result) == String
    sleep(10)
 
    result = Pinecone.fetch(context, index, ["zipA", "zipB"], ns)
 
    #delete zipA and test to see if zipB still there
    Pinecone.delete(context, index, ["zipA"], false, ns)
    @test result !== nothing
    @test typeof(result) == String
 
    result = Pinecone.fetch(context, index, ["zipB"], ns)
    @test result !== nothing
    @test typeof(result) == String
    obj = JSON3.read(result)
    #make sure zipB still there
    @test haskey(obj, "vectors") == true
    vectors = obj["vectors"]
    @test haskey(vectors, "zipB") == true
 
    # first clean up everything in our namespace
    result = Pinecone.delete(context, index, String[], true, ns)
    @test result !== nothing
    @test typeof(result) == String
 
    #reinsert with no namespace
    #insert and test same steps w/ empty namespace
    result = Pinecone.upsert(context, index, ["zipA", "zipB"], [v1, v2], meta)
    @test result !== nothing
    @test typeof(result) == String
    result = Pinecone.fetch(context, index, ["zipA", "zipB"])
    @test result !== nothing
    @test typeof(result) == String
 
    @test_throws ArgumentError Pinecone.delete(context, index, ["testid" for i in 1:1001], true, ns)
 end