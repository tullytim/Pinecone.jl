using Test 
using JSON3 
using Pinecone

APIKEY = ENV["PINECONE_API_KEY"]
CLOUDENV="us-west1-gcp"

context = Pinecone.init(APIKEY, CLOUDENV)

INDEX = "filter-example"
NAMESPACE = "mynamespace"
index = Pinecone.Index(INDEX);

@testset verbose = true "Create/Delete" begin
    testindexname = "unittestindex"
    @testset "Create" begin
       #delete in case already present from previous failure
       result = Pinecone.delete_index(context, Pinecone.Index(testindexname))
       #sleep to wait for delete to go thru, backend takes a bit 
       sleep(10)
       indexconfig = Dict{String, Any}("k_bits"=>512, "hybrid"=>true)
       result = Pinecone.create_index(context, testindexname, 10, metric="euclidean", indextype="approximated",pods=1,replicas=2, shards=1, indexconfig=indexconfig)
       println("CREATE(): ", result)
       @test result == true
 
       #max dims is 10000, check you cannot create 10001
       @test_throws ArgumentError Pinecone.create_index(context, testindexname, 10001)
       #broken pod type
       @test_throws ArgumentError Pinecone.create_index(context, "shouldfail", 10, metric="euclidean", indextype="approximated",pods=1,replicas=2, shards=1, podtype="fail", indexconfig=indexconfig)
       #bad pods
       @test_throws ArgumentError Pinecone.create_index(context, "shouldfail", 10, metric="euclidean", indextype="approximated",pods=0,replicas=2, shards=1, podtype="p1", indexconfig=indexconfig)
       #bad shards
       @test_throws ArgumentError Pinecone.create_index(context, "shouldfail", 10, metric="euclidean", indextype="approximated",pods=1,replicas=2, shards=0, podtype="p1", indexconfig=indexconfig)
       #bad pods and shards
       @test_throws ArgumentError Pinecone.create_index(context, "shouldfail", 10, metric="euclidean", indextype="approximated",pods=0,replicas=2, shards=0, podtype="p1", indexconfig=indexconfig)
       #bad metric
       @test_throws ArgumentError Pinecone.create_index(context, "shouldfail", 10, metric="badmetric", indextype="approximated",pods=1,replicas=2, shards=1, podtype="p1", indexconfig=indexconfig)

      end
    @testset "Delete" begin
       result = Pinecone.delete_index(context, Pinecone.Index(testindexname))
       println("DELETE(): ", result)
       @test result == true
    end
 end