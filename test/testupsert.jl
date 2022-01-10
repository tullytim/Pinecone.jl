
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

@testset verbose = true "Test upsert()" begin
    testdict = Dict{String, Any}("genre"=>"documentary", "year"=>2019);
    meta = [Dict{String,Any}("foo"=>"bar"), Dict{String,Any}("bar"=>"baz")]
    testvector = Pinecone.PineconeVector("testid", v1, testdict)
 
    @testset "Regular upsert()" begin
       result = Pinecone.upsert(context, index, [testvector], "testnamespace")
       @test result !== nothing
       @test typeof(result) == String
       #test no namespace
 
       result = Pinecone.upsert(context, index, [testvector])
       
       @test result !== nothing
       @test typeof(result) == String
    end
    @testset "Upsert with invalid args (ArgumentError)" begin
       #test Arg checking exceptions
       @test_throws ArgumentError Pinecone.upsert(context, index, ["zipA"], [v1, v2])
       @test_throws ArgumentError Pinecone.upsert(context, index, ["zipA", "zipB"], [v2])
       @test_throws ArgumentError Pinecone.upsert(context, index, ["zipA", "zipB"], [v1, v2], [Dict{String,Any}("foo"=>"bar")])
       # test too many vectors on insert
       @test_throws ArgumentError Pinecone.upsert(context, index, ["zipA", "zipB"], [rand(Float32,10) for i in 1:1001])
       largevec = [testvector for i in 1:1001]
       @test_throws ArgumentError Pinecone.upsert(context, index, largevec)
       @test_throws ArgumentError Pinecone.upsert(context, index, largevec, "ns")
    end
 
    @testset "Upsert with zipped vectors and ids" begin
       result = Pinecone.upsert(context, index, ["zipA", "zipB"], [v1, v2])
       @test result !== nothing
       @test typeof(result) == String
 
       result = Pinecone.upsert(context, index, ["zipA", "zipB"], [v1, v2], meta)
       @test result !== nothing
       @test typeof(result) == String
 
       result = Pinecone.upsert(context, index, ["zipA", "zipB"], [v1, v2], meta, "mynamespace")
       @test result !== nothing
       @test typeof(result) == String
    end
 
    @testset "Large upsert()" begin
       context = Pinecone.init(APIKEY, CLOUDENV)
       largeindex = Pinecone.Index("testlargeindex")
       testrows= Vector{Pinecone.PineconeVector}()
       for i in 1:1000
          testvector = Pinecone.PineconeVector("testid_$i", rand(Float32, 10), testdict)
          push!(testrows, testvector)
       end      
       result = Pinecone.upsert(context, largeindex, testrows, "testnamespace")
       @test result !== nothing
       @test typeof(result) == String
    end
end