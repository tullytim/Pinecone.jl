using JSON3

include("Pinecone.jl")

import .Pinecone

pinecone_context = Pinecone.init("b268803a-7861-467c-ade4-f3c96c4ef20b", "us-west1-gcp")
println("Context obj is $pinecone_context")
pinecone_index = Pinecone.Index("filter-example");

println("Index obj is $pinecone_index");

testdict = Dict{String, Any}("genre"=>"documentary", "year"=>2019);
testvector = Pinecone.PineconeVector("testid", [0.3,0.11,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3], testdict)


@time json = Pinecone.whoami(pinecone_context)
json = JSON3.read(json)
println("WHOAMI Parsed user_name: ", json.user_name)
@time json = Pinecone.list_indexes(pinecone_context)

@time json =Pinecone.describe_index_stats(pinecone_context, pinecone_index)
println("DESCRIBE INDEX(): ", json)


@time Pinecone.upsert(pinecone_context, pinecone_index, [testvector], "testnamespace")
#test no namespace
@time Pinecone.upsert(pinecone_context, pinecone_index, [testvector])


@time json = Pinecone.query(pinecone_context, pinecone_index, [testvector], 4)

@time json = Pinecone.query(pinecone_context, pinecone_index,  
[[0.2, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3], [0.2, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]], 4)

#=
println("Query() response: ", json)


indexconfig = Dict{String, Any}("k_bits"=>512, "hybrid"=>true)
response = Pinecone.create_index(pinecone_context, "testindex5", 10, metric="euclidean", indextype="approximated",replicas=2, shards=1, indexconfig=Dict{String,Any}("k_bits"=>512, "hybrid"=>true))
println("CREATE(): ", response)

sleep(5)

@time rv = Pinecone.delete_index(pinecone_context, Pinecone.Index("testindex5"))
println("DELETE(): ", rv)
@time rv = Pinecone.delete_index(pinecone_context, Pinecone.Index("bogusindex"))
println("DELETE(): ", rv)
=#