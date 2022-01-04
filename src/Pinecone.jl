__precompile__(true)

module Pinecone

using JSON3
using StructTypes

export PineconeContext, PineconeIndex, PineconeVector, whoami, init, list_indexes, query, upsert, delete_index, describe_index_stats, create_index

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

"""
    init(apikey, environment)
Initialize the Pinecone environment using your API Key and a specific environment.
This returns a PineconeContext instance which you'll use for subsequent calls such as query() and upsert().
```julia
using Pinecone
context = Pinecone.init("abcd-123456-zyx", "us-west1-gcp")
```
"""
init(apikey::String, environment::String) = begin
    response = pineconeHTTPGet(pineconeMakeURLForController(environment, ENDPOINTWHOAMI), apikey)
    if response == nothing
        return nothing
    elseif response.status == 200
        rvdict = pineconeGetDict(String(response.body))
        return PineconeContext(api_key, environment, rvdict["project_name"])
    end
    nothing
end #init

# note no repsonse body from create, derive success from the HTTP 204
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
    response = pineconeHTTPPost(url, ctx, JSON3.write(postbody))
    response != nothing && response.status == 204 ? true : false
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
    response = pineconeHTTPPost(url, ctx, postbody)
    if response.status == 200
        return String(response.body)
    end
    nothing
end #upsert

query(ctx::PineconeContext, indexobj::PineconeIndex, queries::Vector{PineconeVector}, topk::Int64=10, includevalues::Bool=true, namespace=nothing) = begin
    rawvectors = Vector{Vector{Float64}}()
    for i in length(queries)
        push!(rawvectors, queries[i].values)
    end
    query(ctx, indexobj, rawvectors, topk, includevalues, namespace)
end

query(ctx::PineconeContext, indexobj::PineconeIndex, queries::Vector{Vector{Float64}}, topk::Int64=10, includevalues::Bool=true, namespace=nothing) = begin
    url = pineconeMakeURLForIndex(indexobj, ctx, ENDPOINTQUERYINDEX)
    body = Dict{String, Any}("topK"=>topk, "include_values"=>includevalues)
    body["queries"] =  [Dict{String, Any}("values"=>row) for row in queries]
    if namespace !== nothing
        body["namespace"] = namespace
    end
    postbody = JSON3.write(body)
    response = pineconeHTTPPost(url, ctx, postbody)
    if response == nothing
        return nothing
    elseif response.status == 200 || response.statuss == 400
        return String(response.body)
    end
    nothing
end #query


list_indexes(context::PineconeContext) = begin
    response = pineconeHTTPGet(pineconeMakeURLForController(context.cloudenvironment, ENDPOINTLISTINDEXES), context)
    if response.status == 200
        return String(response.body)
    end
end

whoami(context::PineconeContext) = begin
    response = pineconeHTTPGet(pineconeMakeURLForController(context.cloudenvironment, ENDPOINTWHOAMI), context)
    if response.status == 200
        return String(response.body)
    end
end

# We get back 204 on successful delete, otherwise 404 if index didn't exist
delete_index(ctx::PineconeContext, indexobj::PineconeIndex) = begin
    url = pineconeMakeURLForController(ctx.cloudenvironment, ENDPOINTDELETEINDEX * "/" * indexobj.indexname)
    response = pineconeHTTPDelete(url, ctx)
    response !== nothing && response.status == 204 ? true : false
end

describe_index_stats(ctx::PineconeContext, indexobj::PineconeIndex) = begin
    url = pineconeMakeURLForIndex(indexobj, ctx, ENDPOINTDESCRIBEINDEXSTATS)
    response = pineconeHTTPGet(url, ctx)
    if response.status == 200
        return String(response.body)
    end
end

end # module
