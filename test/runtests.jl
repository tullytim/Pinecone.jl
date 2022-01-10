using Test
using Pinecone
using JSON3

# API Key from GitHub secrets
GOODAPIKEY = ENV["PINECONE_API_KEY"]
CLOUDENV="us-west1-gcp"
TESTINDEX = "filter-example"

v1 = [0.3,0.11,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3]
v2 = [0.9, 0.8, 0.7, 0.6, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]

@testset "PineconeIndex Type Tests" begin
   pineconeindex = PineconeIndex(TESTINDEX)
   @test typeof(pineconeindex) == PineconeIndex
   @test pineconeindex.indexname == TESTINDEX
   pineconeindex = Pinecone.Index(TESTINDEX)
   @test typeof(pineconeindex) == PineconeIndex
   @test pineconeindex.indexname == TESTINDEX
   println("PineconeIndex is ", pineconeindex)
end;

@testset "PineconeContext Type Tests" begin
   KEY = "asdf-asdfadfs-adsfafds"
   ENV = "us.east.gcp"
   PROJECT = "testproject"
   pineconecontext = PineconeContext(KEY, ENV, PROJECT)
   #testing print out for codecov
   println("pineconecontext is ", pineconecontext)
   @test typeof(pineconecontext) == PineconeContext
   @test pineconecontext.apikey == KEY
   @test pineconecontext.cloudenvironment == ENV
   @test pineconecontext.projectname == PROJECT
end

@testset "PineconeVector Type Tests" begin
   VID = "vectorid"
   VALUES = [0.1, 0.2, 0.3, 0.4]
   META = Dict{String, Any}("foo"=>"bar", "key"=>"value", "numeric"=>1234)
   pineconevector = PineconeVector(VID, VALUES, META)
   @test typeof(pineconevector) == PineconeVector
   @test pineconevector.id == VID
   @test length(pineconevector.values) == 4
   @test length(pineconevector.metadata) == 3
   @test typeof(pineconevector.metadata) == Dict{String,Any}
   #testing print out for codecov
   println("pineconevector is ", pineconevector)
end

@testset "Test Init" begin
   #make a bogus init() call, should return nothing
   BADAPIKEY = "zzzz123456"
   context = Pinecone.init(BADAPIKEY, "badcloud")

   @test context == nothing

   #now check for proper setup
   goodcontext = Pinecone.init(GOODAPIKEY, CLOUDENV)
   @test goodcontext != nothing
   @test typeof(goodcontext) == PineconeContext
end

@testset "Test whoami()" begin
   println("TEST WITH APIKEY: ", GOODAPIKEY)
   context = Pinecone.init(GOODAPIKEY, CLOUDENV)
   result = Pinecone.whoami(context)
   @test result !== nothing
   @test typeof(result) == String
end

@testset "Test list_indexes()" begin
   context = Pinecone.init(GOODAPIKEY, CLOUDENV)
   result = Pinecone.list_indexes(context)
   println("list_indexes() result: ", result)
   @test result !== nothing
   @test typeof(result) == String
   parsed = JSON3.read(result)
   @test length(parsed) >= 0
end

@testset "Test describe_index_stats()" begin
   context = Pinecone.init(GOODAPIKEY, CLOUDENV)
   index = PineconeIndex(TESTINDEX)
   result = Pinecone.describe_index_stats(context, index)
   println("result was $result")
   @test result !== nothing
   @test typeof(result) == String
   parsed = JSON3.read(result)
   @test haskey(parsed, "namespaces") == true
   @test haskey(parsed, "dimension") == true
end

@testset verbose = true "Create/Delete" begin
   context = Pinecone.init(GOODAPIKEY, CLOUDENV)
   testindexname = "unittestindex"
   @testset "Create" begin
      #delete in case already present from previous failure
      result = Pinecone.delete_index(context, Pinecone.Index(testindexname))
      #sleep to wait for delete to go thru, backend takes a bit
      sleep(10)
      indexconfig = Dict{String, Any}("k_bits"=>512, "hybrid"=>true)
      result = Pinecone.create_index(context, testindexname, 10, metric="euclidean", indextype="approximated",replicas=2, shards=1, indexconfig=indexconfig)
      println("CREATE(): ", result)
      @test result == true

      #max dims is 10000, check you cannot create 10001
      @test_throws ArgumentError Pinecone.create_index(context, testindexname, 10001)
   end
   @testset "Delete" begin
      result = Pinecone.delete_index(context, Pinecone.Index(testindexname))
      println("DELETE(): ", result)
      @test result == true
   end
end

@testset verbose = true "Test delete()" begin
   ns = "deletenamespace"
   context = Pinecone.init(GOODAPIKEY, CLOUDENV)
   index = PineconeIndex(TESTINDEX)
   meta = [Dict{String,Any}("foo"=>"bar"), Dict{String,Any}("bar"=>"baz")]

   # first clean up everything in our namespace
   result = Pinecone.delete(context, index, ["zipA", "zipB"], true, ns)

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
   result = Pinecone.delete(context, index, ["zipA", "zipB"], true, ns)
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

include("testfetch.jl")
include("testquery.jl")
include("testupsert.jl")
include("testscale.jl")

println("DONE")