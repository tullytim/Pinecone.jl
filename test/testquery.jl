using Test 
using JSON3 
using Pinecone

APIKEY = ENV["PINECONE_API_KEY"]
context = Pinecone.init(APIKEY, "us-west1-gcp")

INDEX = "filter-example"
NAMESPACE = "mynamespace"
index = Pinecone.Index(INDEX);

testdict = Dict{String, Any}("genre"=>"documentary", "year"=>2019);
v1 = [0.3,0.11,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3]
v2 = [0.9, 0.8, 0.7, 0.6, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]


@testset verbose = true "Test query()" begin
    testdict = Dict{String, Any}("genre"=>"documentary", "year"=>2019);
    testvector = Pinecone.PineconeVector("testid", v1, testdict)
    context = Pinecone.init(GOODAPIKEY, CLOUDENV)
    index = Pinecone.Index(TESTINDEX)
    result = Pinecone.query(context, index, [testvector], 4)
    @test result !== nothing
    @test typeof(result) == String
    result = Pinecone.query(context, index, [v1, v1], 4)
    @test result !== nothing
    @test typeof(result) == String
       #should get nothing here w/ this bogus namespace
    result = Pinecone.query(context, index, [v1, v1], 4, "bogusempty", true)
    #the bogus namespace returns HTTP 400 but with JSON body.  query() returns nothing so check
    @test result == nothing
 
    println("***************** Test query() topK *****************")
    # test topk exceeded
    @test_throws ArgumentError Pinecone.query(context, index, [testvector], 10001)
 
    println("***************** Test query() topk exceeded include results*************")
    # test topk exceeded when values included in return results
    @test_throws ArgumentError Pinecone.query(context, index, [testvector], 10000, "", true)
    
    # test topk exceeded with alternate query form
    @test_throws ArgumentError Pinecone.query(context, index, [v1], 10001)
    # test topk exceeded when values included in return results
    @test_throws ArgumentError Pinecone.query(context, index, [v1], 10000, "", true)
    # test topk exceeded when values included in return results with includesvalues=true
    @test_throws ArgumentError Pinecone.query(context, index, [v1], 10001, "", true, false)
    # test topk exceeded when values included in return results with includesmeta=true
    @test_throws ArgumentError Pinecone.query(context, index, [v1], 10001, "", false, true)
 
 
    result = Pinecone.query(context, index, [testvector], 1000, "", true)
    @test result != nothing
    @test typeof(result) == String
    result = Pinecone.query(context, index, [testvector], 1000, "", true, false)
    @test result != nothing
    @test typeof(result) == String
    result = Pinecone.query(context, index, [testvector], 1000, "", false, true)
    @test result != nothing
    @test typeof(result) == String
 end