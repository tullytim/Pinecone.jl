__precompile__(true)

module Pinecone

using JSON3
using StructTypes

export PineconeContext, PineconeIndex, whoami, init, list_indexes, query, upsert, delete_index, describe_index_stats, create_index, jess

struct PineconeContext
    apikey::String
    cloudenvironment::String
    projectname::String
end
Base.show(io::IO, ctx::PineconeContext) = print(io, ctx.apikey, " / ", ctx.cloudenvironment, " / ", ctx.projectname)

struct PineconeIndex
    indexname::String
end
Base.show(io::IO, index::PineconeIndex) = print(io, "PineconeIndex connected to ", index.indexname) 

struct PineconeVector
    id::String
    values::Array{Float64}
    metadata::Dict{String, Any}
end
Base.show(io::IO, vec::PineconeVector) = print(io, "PineconeVector is id: ", vec.id, " values: ", vec.values, "meta: ", vec.metadata)
# Make PineconeVector type JSON3 writable per https://quinnj.github.io/JSON3.jl/stable/#Read-JSON-into-a-type
StructTypes.StructType(::Type{PineconeVector}) = StructTypes.UnorderedStruct()

include("networking.jl");

const ENDPOINTWHOAMI = "actions/whoami"
const ENDPOINTLISTINDEXES = "databases"
const ENDPOINTDESCRIBEINDEXSTATS = "describe_index_stats"
const ENDPOINTDELETEINDEX = "databases"
const ENDPOINTQUERYINDEX = "query"
const ENDPOINTUPSERT = "vectors/upsert"
const ENDPOINTCREATEINDEX = "databases"

function __init__()
    nothing
end


init(api_key::String, environment::String) = begin
    rvdict = pineconeHTTPGet(pineconeMakeURLForController(environment, ENDPOINTWHOAMI), api_key)
    println("init says we are " * rvdict["project_name"])
    @assert(!isempty(rvdict["project_name"]))
    PineconeContext(api_key, environment, rvdict["project_name"])
end #init

create_index(ctx::PineconeContext, indexname::String, dimension::Int64; metric::String="euclidean", indextype::String="", replicas::Int64=0, shards::Int64=1, indexconfig=Dict{String, Any}()) = begin
    println("Creating index $indexname with metric $metric replicas $replicas, shards $shards")
    url = pineconeMakeURLForController(ctx.cloudenvironment, ENDPOINTCREATEINDEX)
    postbody = Dict{String, Any}("name"=>indexname, "dimension"=>dimension, "metric"=>metric, "replicas"=>replicas, "shards"=>shards)
    if indextype !== ""
        postbody["index_type"] = indextype
    end
    if length(indexconfig) > 0
        postbody["index_config"] = indexconfig
    end
    pineconeHTTPPost(url, ctx, JSON3.write(postbody))
end  #create_index

Index(indexname::String) = begin
    PineconeIndex(indexname);
end #Index

upsert(ctx::PineconeContext, indexobj::PineconeIndex, vectors::Vector{PineconeVector}, namespace=nothing) = begin
    url = pineconeMakeURLForIndex(indexobj, ctx, ENDPOINTUPSERT)
    body = Dict{String, Any}("vectors" => vectors)
    if namespace !== nothing
        body["namespace"] = namespace
    end
    postbody = JSON3.write(body)
    println("upsert body is $postbody")
    pineconeHTTPPost(url, ctx, postbody)
end #upsert

query(ctx::PineconeContext, indexobj::PineconeIndex, queries::Vector{Vector{Float64}}, topk::Int64=10, includevalues::Bool=true, namespace=nothing) = begin
    url = pineconeMakeURLForIndex(indexobj, ctx, ENDPOINTQUERYINDEX)
    body = Dict{String, Any}("topK"=>topk, "include_values"=>includevalues)
    body["queries"] =  [Dict{String, Any}("values"=>row) for row in queries]
    if namespace !== nothing
        body["namespace"] = namespace
    end
    postbody = JSON3.write(body)
    pineconeHTTPPost(url, ctx, postbody)
end #query

list_indexes(context::PineconeContext) = pineconeHTTPGet(pineconeMakeURLForController(context.cloudenvironment, ENDPOINTLISTINDEXES), context)

whoami(context::PineconeContext) = pineconeHTTPGet(pineconeMakeURLForController(context.cloudenvironment, ENDPOINTWHOAMI), context)

delete_index(ctx::PineconeContext, indexobj::PineconeIndex) = begin
    url = pineconeMakeURLForController(ctx.cloudenvironment, ENDPOINTDELETEINDEX * "/" * indexobj.indexname)
    pineconeHTTPDelete(url, ctx)
end

describe_index_stats(ctx::PineconeContext, indexobj::PineconeIndex) = begin
    url = pineconeMakeURLForIndex(indexobj, ctx, ENDPOINTDESCRIBEINDEXSTATS)
    pineconeHTTPGet(url, ctx)
end
jess() = println("my wife")

end # module
