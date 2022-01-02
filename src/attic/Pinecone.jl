__precompile__(false)

module Pinecone

using PyCall
#using Pkg
#Pkg.status()

const pinecone_py = PyNULL()

function __init__()
    copy!(pinecone_py, pyimport("pinecone"))
    nothing
end

#pinecone_py = pyimport_conda("pinecone", PKG)
init(api_key, environment="us-west1-gcp") = begin
    println("Calling init with api_key $api_key and env $environment")
    pinecone_py.init(api_key, environment)
end #init

create_index(index_name, index_type, dimension, metric="euclidean") = begin
    println("Creating index $index_name")

end  #create_index

Index(index_name) = begin
    return pinecone_py.Index(index_name)
end #Index

upsert(index_obj, vectors) = begin
    cols = ["A", "B", "C", "D", "E"]
    vs = [
        repeat([0.1], outer=10),
        repeat([0.2], outer=10),
        repeat([0.3], outer=10),
        repeat([0.4], outer=10),
        repeat([0.5], outer=10)
    ]
    println(vs);
    index_obj.upsert(vectors=collect(zip(cols, vs)))
end #upsert

query(index_obj) = begin
    println(index_obj);
    index_obj.query()
end #query

list_indexes() = begin
    pinecone_py.list_indexes();
end #list_indexes

whoami() = pinecone_py.whoami()

delete_index(index_name) = begin
    pinecone_py.delete_index(index_name);
end #delete_index

describe_index_stats(index_obj) = begin
    index_obj.describe_index_stats()
end

end # module
