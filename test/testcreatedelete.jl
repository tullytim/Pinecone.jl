using Test
using JSON3
#using Pinecone
include("../src/Pinecone.jl")

APIKEY = ENV["PINECONE_API_KEY"]
CLOUDENV = "us-west1-gcp"

context = Pinecone.init(APIKEY, CLOUDENV)

INDEX = "filter-example"
NAMESPACE = "mynamespace"
testindexname = "unittestindex"

index = Pinecone.Index(INDEX);

@testset verbose = true "Create/Delete" begin

	@testset "Create" begin
		#delete in case already present from previous failure
		indexes = Pinecone.list_indexes(context)
		if (occursin.(testindexname, indexes))
			print("found stale index for testing, deleting: ", testindexname)
			Pinecone.delete_index(context, Pinecone.Index(testindexname))
		end
		result = Pinecone.create_index(context, testindexname, 10, metric = "cosine", pods = 1, replicas = 2, shards = 1)
		println("CREATE(): ", result)
		@test result != nothing

		#max dims is 10000, check you cannot create 10001
		@test_throws ArgumentError Pinecone.create_index(context, testindexname, 10001)
		#broken pod type
		@test_throws ArgumentError Pinecone.create_index(context, "shouldfail", 10, metric = "euclidean", pods = 1, replicas = 2, shards = 1, podtype = "fail")
		#bad pods
		@test_throws ArgumentError Pinecone.create_index(context, "shouldfail", 10, metric = "euclidean", pods = 0, replicas = 2, shards = 1, podtype = "p1")
		#bad shards
		@test_throws ArgumentError Pinecone.create_index(context, "shouldfail", 10, metric = "euclidean", pods = 1, replicas = 2, shards = 0, podtype = "p1")
		#bad pods and shards
		@test_throws ArgumentError Pinecone.create_index(context, "shouldfail", 10, metric = "euclidean", pods = 0, replicas = 2, shards = 0, podtype = "p1")
		#bad metric
		@test_throws ArgumentError Pinecone.create_index(context, "shouldfail", 10, metric = "badmetric", pods = 1, replicas = 2, shards = 1, podtype = "p1")

	end
	@testset "Delete" begin
		indexes = Pinecone.list_indexes(context)

		if (occursin.(testindexname, indexes))
			print("found stale index for testing, deleting: ", testindexname)
			result = Pinecone.delete_index(context, Pinecone.Index(testindexname))
			@test result != nothing
		end

	end
end
