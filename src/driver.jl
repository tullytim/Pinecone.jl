include("Pinecone.jl")

import .Pinecone

pinecone_context = Pinecone.init("b268803a-7861-467c-ade4-f3c96c4ef20b", "us-west1-gcp")
println("Context obj is $pinecone_context")
#pinecone_index = Pinecone.Index("filter-example");
pinecone_index = Pinecone.Index("test1");
println("Index obj is $pinecone_index");

testdict = Dict{String, Any}("genre"=>"documentary", "year"=>2019);
testvector = Pinecone.PineconeVector("testid", [0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3], testdict)


@time Pinecone.whoami(pinecone_context)
@time Pinecone.list_indexes(pinecone_context)
#=
Pinecone.describe_index_stats(pinecone_context, pinecone_index)


@time Pinecone.upsert(pinecone_context, pinecone_index, [testvector], "testnamespace")
#test no namespace
@time Pinecone.upsert(pinecone_context, pinecone_index, [testvector])


@time Pinecone.query(pinecone_context, pinecone_index,  
[[0.2, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3], [0.2, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]], 4)
@time Pinecone.jess()


Pinecone.describe_index_stats(pinecone_context, pinecone_index)

indexconfig = Dict{String, Any}("k_bits"=>512, "hybrid"=>true)
Pinecone.create_index(pinecone_context, "testindex5", 10, metric="euclidean", indextype="approximated",replicas=2, shards=1, indexconfig=Dict{String,Any}("k_bits"=>512, "hybrid"=>true))
sleep(10)
=#
Pinecone.delete_index(pinecone_context, Pinecone.Index("testindex5"))