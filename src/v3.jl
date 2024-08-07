export PineconeContextv3, PineconeIndexv3, Serverless, Status

struct PineconeContextv3
    apikey::String
end
Base.show(io::IO, ctx::PineconeContextv3) = print(io, ctx.apikey)
struct Serverless
    cloud::String
    region::String
end

@kwdef struct PodSpec
    environment::String
    podtype::String
    ## TBD
end

struct Status
    ready::Bool
    state::String
end

struct PineconeIndexv3
    dimension::Int
    host::String
    metric::String
    name::String
    spec::Dict{String, Serverless}
    status::Status
end
Base.show(io::IO, index::PineconeIndexv3) = print(io, "PineconeIndex connected to ", index.name)

StructTypes.StructType(::Type{PineconeIndexv3}) = StructTypes.UnorderedStruct()
StructTypes.StructType(::Type{Status}) = StructTypes.UnorderedStruct()
StructTypes.StructType(::Type{Serverless}) = StructTypes.UnorderedStruct()

pineconeMakeURLForIndex(index::Pinecone.PineconeIndexv3, endpoint::String) = begin
    "https://"*index.host *"/"* endpoint
end

pineconeMakeURLForIndex(indexname::String) = begin
    "https://api.pinecone.io/indexes/$indexname"
end

pineconeMakeURLForIndex() = begin
    "https://api.pinecone.io/indexes"
end

# note no repsonse body from create, derive success from the HTTP 204
"""
   create_index(ctx::PineconeContext, indexname::String, dimension::Int64; metric::String="cosine", pods::Int64=1, replicas::Int64=1, shards::Int64=1, podtype::String="p1")

Creates an index with a given PineconeContext, which can be accessed by a call to init(), the name of the index, and the number of dimensions.

This function returns a JSON blob as a string, or nothing if it failed. Do recommend using JSON3 to parse the blob.

# Example
```julia
context = Pinecone.init("abcd-123456-zyx", "us-west1-gcp")
result = Pinecone.create_index(context, testindexname, 10, metric="euclidean", replicas=2, shards=1)
```
"""
function create_index(ctx::PineconeContextv3, indexname::String, dimension::Int, metric::String="cosine", cloud::String="aws", region::String="us-east-1")
    dimension = dimension
    if(dimension > MAX_DIMS)
        throw(ArgumentError("Creating index larger than max dimension size of " * string(MAX_DIMS)))
    end
    metric = metric
    if(metric != "cosine" && metric != "dotproduct" && metric != "euclidean")
        throw(ArgumentError("Invalid index type.  Type must be one of 'euclidean', 'cosine', or 'dotproduct'."))
    end
    body = Dict("dimension"=>dimension,
                "metric"=>metric,
                "name"=>indexname,
                "spec"=>Dict(
                    "serverless"=>Dict(
                        "cloud"=>cloud,
                        "region"=>region
                    )
                )
                )
    url = pineconeMakeURLForIndex()
    response = pineconeHTTPPost(url, ctx.apikey, JSON3.write(body))
end

"""
    init(apikey::String, environment::String)

Initialize the Pinecone environment using your API Key and a specific environment.

This returns a PineconeContext instance which you'll use for subsequent calls such as query() and upsert().
Your API Key and the cloud environment for your indexes are easily found in the Pinecone console.
On failure returns nothing.

# Example
```julia
using Pinecone
context = Pinecone.init("abcd-123456-zyx", "us-west1-gcp")
```
"""

function init_v3(apikey::String)
    return PineconeContextv3(apikey)
end

function list_index_objects(ctx::PineconeContextv3)
    response = pineconeHTTPGet("https://api.pinecone.io/indexes", ctx.apikey)
    ## do better here
    indexes = JSON3.read(String(response.body), Dict{Symbol, Any})[:indexes]
    a = JSON3.write(indexes)
    JSON3.read(JSON3.write(indexes), Vector{PineconeIndexv3})
end


"""
    list_indexes(context::PineconeContext)

Returns a JSON array listing indexes for a given account, which is indicated by the PineconeContext instance passed in.

# Example
```julia-repl
julia> context = Pinecone.init("asdf-1234-zyxv", "us-west1-gcp")
Pinecone.list_indexes(context)
["example-index", "filter-example"]
```
"""
list_indexes(ctx::PineconeContextv3) = map(x->x.name, list_index_objects(ctx))


"""
    Index(indexname::String)

Returns a PineconeIndex type which is used for query() and upsert() of data against a specific index.

# Example
```julia-repl
julia> Pinecone.Index("my-index")
PineconeIndex connected to my-index
```
"""

function Index(ctx::PineconeContextv3, indexname::String)
    url = pineconeMakeURLForIndex(indexname)
    response = pineconeHTTPGet(url, ctx.apikey)
    return JSON3.read(String(response.body), PineconeIndexv3)
end

function describe_index_stats(ctx::PineconeContextv3, indexobj::PineconeIndexv3)
    url = pineconeMakeURLForIndex(indexobj, ENDPOINTDESCRIBEINDEXSTATS)
    response = pineconeHTTPGet(url, ctx.apikey)
    return String(response.body)
end

"""
    delete_index(ctx::PineconeContext, indexobj::PineconeIndex)

Deletes an index, returns true on successful response from Pinecone backend.

This delets a given Pinecone index, note that this is an asynch call and doesn't guarantee that on return that the index is actually deleted (yet).

# Example
```julia
Pinecone.delete_index(context, Pinecone.Index("index-to-delete"))
```
"""
function delete_index(ctx::PineconeContextv3, indexname::String)
    url = pineconeMakeURLForIndex(indexname)
    response = pineconeHTTPDelete(url, ctx.apikey)
end

"""
    upsert(ctx::PineconeContext, indexobj::PineconeIndex, vectors::Vector{PineconeVector}, namespace::String="")

upserts a Julia Vector of type PineconeVector using the given PineconeContext and PineconeIndex with an optional namespace (Defaults to not being applied to query if not passed.)
On success returns a JSON blob as a String type, and nothing if it fails.
This function returns a JSON blob as a string, or nothing if it failed. Do recommend using JSON3 to parse the blob.

# Example
```julia-repl
julia> testvector = Pinecone.PineconeVector("testid", [0.3,0.11,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3])
context = Pinecone.init("abcd-123456-zyx", "us-west1-gcp")
index = PineconeIndex("myindex")
result = Pinecone.upsert(context, index, [testvector], "testnamespace")
```
"""
function upsert(ctx::PineconeContextv3, indexobj::PineconeIndexv3, vectors::Vector{PineconeVector}, namespace::String="")
    if(length(vectors) > MAX_UPSERT_VECTORS)
        throw(ArgumentError("Max number of vectors per upsert is " * string(MAX_UPSERT_VECTORS)))
    end
    url = pineconeMakeURLForIndex(indexobj, ENDPOINTUPSERT)
    body = Dict{String, Any}("vectors" => vectors)
    if namespace !== nothing && namespace != ""
        body["namespace"] = namespace
    end
    postbody = JSON3.write(body)
    response = pineconeHTTPPost(url, ctx.apikey, postbody)
    return String(response.body)
end #upsert

"""
    delete(ctx::PineconeContext, indexobj::PineconeIndex, ids::Array{String}, deleteall::Bool, namespace::String)

Deletes vectors indexed by ``ids``.  **Warning:** The entire namespace for the vector will be deleted if deleteall=true

Returns JSON blob as ``String`` of empty object or nothing if fails.
# Example
```julia-repl
julia> context = Pinecone.init("asdf-1234-zyxv", "us-west1-gcp")
index = PineconeIndex("my-index")
Pinecone.delete(context, index, ["deleteme1", "deleteme2"], false, "timnamespace")
{}
```
"""
function delete(ctx::PineconeContextv3, indexobj::PineconeIndexv3, ids::Array{String}, deleteall::Bool=false, namespace::String="")
    if(length(ids) > MAX_DELETE)
        throw(ArgumentError("Max number of vectors per delete is " * string(MAX_DELETE)))
    end
    url = pineconeMakeURLForIndex(indexobj, ENDPOINTDELETE)
    postbody = Dict{String, Any}("ids"=>ids, "namespace"=>namespace, "deleteAll"=>deleteall)
    response = pineconeHTTPPost(url, ctx.apikey, JSON3.write(postbody))
    return String(response.body)
end

function fetch(ctx::PineconeContextv3, indexobj::PineconeIndexv3, ids::Array{String}, namespace::String="")
    if(length(ids) > MAX_FETCH)
        throw(ArgumentError("Max number of vectors per fetch is " * string(MAX_FETCH)))
    end
    renamedids = ["ids=$row" for row in ids]
    urlargs = "?" * join(renamedids, "&") * "&namespace=$namespace"
    url = pineconeMakeURLForIndex(indexobj, ENDPOINTFETCH) * urlargs
    response = pineconeHTTPGet(url, ctx.apikey)
    return String(response.body)
end

function query(ctx::PineconeContextv3, indexobj::PineconeIndexv3, queries::PineconeVector, topk::Int64=10, namespace::String="", includevalues::Bool=false, includemeta::Bool=false, filter::Dict{String, Any}=Dict{String,Any}())
    #rawvectors = [queries[i].values for i in 1:length(queries)]
    query(ctx, indexobj, queries.values, topk, namespace, includevalues, includemeta, filter)
end

function query(ctx::PineconeContextv3, indexobj::PineconeIndexv3, vector::Vector{T}, topk::Int64=10, namespace::String="", includevalues::Bool=false,
        includemeta::Bool=false, filter::Dict{String, Any}=Dict{String,Any}()) where {T<:AbstractFloat}
    if topk > MAX_TOPK
        throw(ArgumentError("topk larger than largest topk available of " * string(MAX_TOPK)))
    end
    if includevalues == true && topk > MAX_TOPK_WITH_DATA
        throw(ArgumentError("topk larger than largest topk available of " * string(MAX_TOPK_WITH_DATA) * " when including data in results"))
    end
    if includemeta == true && topk > MAX_TOPK_WITH_META
        throw(ArgumentError("topk larger than largest topk available of " * string(MAX_TOPK_WITH_META) * " when including meatadata in results"))
    end
    url = pineconeMakeURLForIndex(indexobj, ENDPOINTQUERYINDEX)
    body = Dict{String, Any}("topK"=>topk, "vector"=>vector, "includeValues"=>includevalues, "includeMetadata"=>includemeta, "namespace"=>namespace)
    if(length(filter) > 0)
        body["filter"] = filter;
    end
    postbody = JSON3.write(body)
    response = pineconeHTTPPost(url, ctx.apikey, postbody)
    return String(response.body)
end #query
