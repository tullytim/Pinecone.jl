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
init(apikey::String, environment::String) = begin
    response = pineconeHTTPGet(pineconeMakeURLForController(environment, ENDPOINTWHOAMI), apikey)
    if response == nothing
        return nothing
    elseif response.status == 200
        rvdict = pineconeGetDict(String(response.body))
        return PineconeContext(apikey, environment, rvdict["project_name"])
    end
    nothing
end #init

# note no repsonse body from create, derive success from the HTTP 204
"""
    create_index(ctx::PineconeContext, indexname::String, dimension::Int64; metric::String="euclidean", indextype::String="", replicas::Int64=0, shards::Int64=1, indexconfig=Dict{String, Any}())

Creates an index with a given PineconeContext, which can be accessed by a call to init(), the name of the index, and the number of dimensions.

Note that there are other parameters for the distance metric, indextype, number of replicas and shards as well as the indexconfig. 
This function returns a JSON blob as a string, or nothing if it failed. Do recommend using JSON3 to parse the blob.

# Example
```julia
context = Pinecone.init("abcd-123456-zyx", "us-west1-gcp")
result = Pinecone.create_index(context, testindexname, 10, metric="euclidean", indextype="approximated",replicas=2, shards=1, indexconfig=indexconfig)
```
"""
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

"""
    Index(indexname::String)

Returns a PineconeIndex type which is used for query() and upsert() of data against a specific index. 

# Example
```julia-repl
julia> Pinecone.Index("my-index")
PineconeIndex connected to my-index
```
"""
Index(indexname::String) = begin
    PineconeIndex(indexname);
end #Index

"""
    upsert(ctx::PineconeContext, indexobj::PineconeIndex, vectors::Vector{PineconeVector}, namespace::String="")

upserts a Julia Vector of type PineconeVector using the given PineconeContext and PineconeIndex with an optional namespace (Defaults to not being applied to query if not passed.)
On success returns a JSON blob as a String type, and nothing if it fails. 
This function returns a JSON blob as a string, or nothing if it failed. Do recommend using JSON3 to parse the blob.

# Example
```julia-repl
julia> testvector = Pinecone.PineconeVector("testid", [0.3,0.11,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3])
context = Pinecone.init(GOODAPIKEY, CLOUDENV)
index = PineconeIndex(TESTINDEX)
result = Pinecone.upsert(context, index, [testvector], "testnamespace")
```
"""
upsert(ctx::PineconeContext, indexobj::PineconeIndex, vectors::Vector{PineconeVector}, namespace::String="") = begin
    url = pineconeMakeURLForIndex(indexobj, ctx, ENDPOINTUPSERT)
    body = Dict{String, Any}("vectors" => vectors)
    if namespace !== nothing && namespace != ""
        body["namespace"] = namespace
    end
    postbody = JSON3.write(body)
    response = pineconeHTTPPost(url, ctx, postbody)
    if response.status == 200
        return String(response.body)
    end
    nothing
end #upsert

"""
    query(ctx::PineconeContext, indexobj::PineconeIndex, queries::Vector{PineconeVector}, topk::Int64=10, includevalues::Bool=true, namespace::String="")

Query an index using the given context that match ``queries`` passed in.  The ``PineconeVector`` that is queries is a simple ``PineconeVector`` as described above.
Note there is an another version of ``query()`` that takes in a ``Vector{Vector{Float64}}`` for the ``queries`` parameter.  Functionally equivalent.
Returns JSON blob as a ``String`` with the results on success, ``nothing`` on failure.

topk is an optional parameter which defaults to 10 if not specified.  Do recommend using JSON3 to parse the blob.


# Example
```julia-repl
julia> testdict = Dict{String, Any}("genre"=>"documentary", "year"=>2019);
julia> pinecone_context = Pinecone.init("abcdef-1234-zyxv", "us-west1-gcp")
abcdef-1234-zyxv / us-west1-gcp / 1c9c2f3
julia> pinecone_index = Pinecone.Index("filter-example");
julia> testvector = Pinecone.PineconeVector("testid", [0.3,0.11,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3], testdict)
PineconeVector is id: testid values: [0.3, 0.11, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.4, 0.3]meta: Dict{String, Any}("genre" => "documentary", "year" => 2019)
julia> Pinecone.query(pinecone_context, pinecone_index, [testvector], 4)
"{\"results\":[{\"matches\":[{\"id\":\"testid\",\"score\":3.98966023e-07,\"values\":[0.3,0.11,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3]},{\"id\":\"C\",\"score\":0.0461001098,\"values\":[0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.3]}
],\"namespace\":\"\"}]}"
```
"""
query(ctx::PineconeContext, indexobj::PineconeIndex, queries::Vector{PineconeVector}, topk::Int64=10, includevalues::Bool=true, namespace::String="") = begin
    rawvectors = Vector{Vector{Float64}}()
    for i in length(queries)
        push!(rawvectors, queries[i].values)
    end
    query(ctx, indexobj, rawvectors, topk, includevalues, namespace)
end

"""
    query(ctx::PineconeContext, indexobj::PineconeIndex, queries::Vector{Vector{Float64}}, topk::Int64=10, includevalues::Bool=true, namespace=nothing)

Query an index using the given context that match ``queries`` passed in. Returns JSON blob as a ``String`` with the results on success, ``nothing`` on failure.
Note there is an alternate form for ``query()`` that takes in a ``Vector{PineconeVector}`` instead.  Functionally equivalent.
topk is an optional parameter which defaults to 10 if not specified.  Do recommend using JSON3 to parse the blob.


# Example
```julia-repl
julia> testdict = Dict{String, Any}("genre"=>"documentary", "year"=>2019);
julia> pinecone_context = Pinecone.init("abcdef-1234-zyxv", "us-west1-gcp")
abcdef-1234-zyxv / us-west1-gcp / 1c9c2f3
julia> pinecone_index = Pinecone.Index("filter-example");
julia> testvector = Pinecone.PineconeVector("testid", [0.3,0.11,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3], testdict)
PineconeVector is id: testid values: [0.3, 0.11, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.4, 0.3]meta: Dict{String, Any}("genre" => "documentary", "year" => 2019)
julia> Pinecone.query(pinecone_context, pinecone_index,  
[[0.2, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3], [0.2, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]], 4)
"{\"results\":[{\"matches\":[{\"id\":\"testid\",\"score\":3.98966023e-07,\"values\":[0.3,0.11,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3]},{\"id\":\"C\",\"score\":0.0461001098,\"values\":[0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.3]}
],\"namespace\":\"\"}]}"
```
"""
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
list_indexes(context::PineconeContext) = begin
    response = pineconeHTTPGet(pineconeMakeURLForController(context.cloudenvironment, ENDPOINTLISTINDEXES), context)
    if response.status == 200
        return String(response.body)
    end
end

""" 
    whoami(context::PineconeContext)

Returns JSON blob with information about your connection to Pinecone.

# Example
```julia-repl
julia> context = Pinecone.init("abcd-1234-zyxv", "us-west1-gcp")
Pinecone.whoami(context)
```
"""
whoami(context::PineconeContext) = begin
    response = pineconeHTTPGet(pineconeMakeURLForController(context.cloudenvironment, ENDPOINTWHOAMI), context)
    if response.status == 200
        return String(response.body)
    end
end

"""
    (ctx::PineconeContext, indexobj::PineconeIndex)

Deletes an index, returns true on successful response from Pinecone backend.

This delets a given Pinecone index, note that this is an asynch call and doesn't guarantee that on return that the index is actually deleted (yet).

# Example
```julia
Pinecone.delete_index(context, Pinecone.Index("index-to-delete"))
```
"""
delete_index(ctx::PineconeContext, indexobj::PineconeIndex) = begin
    url = pineconeMakeURLForController(ctx.cloudenvironment, ENDPOINTDELETEINDEX * "/" * indexobj.indexname)
    response = pineconeHTTPDelete(url, ctx)
    response !== nothing && response.status == 204 ? true : false
end

"""
    describe_index_stats(ctx::PineconeContext, indexobj::PineconeIndex)

Returns JSON blob as a String type describing a particular index.  Returns ``nothing`` on failure.

# Example
```julia 
context = Pinecone.init("abcde-1234-zyxv", "us-west1-gcp")
index = PineconeIndex("my-index")
Pinecone.describe_index_stats(context, index)
"namespaces":{"test_namespace":{"vectorCount":1},"testnamespace":{"vectorCount":1},"":{"vectorCount":5}},"dimension":10}
```
"""
describe_index_stats(ctx::PineconeContext, indexobj::PineconeIndex) = begin
    url = pineconeMakeURLForIndex(indexobj, ctx, ENDPOINTDESCRIBEINDEXSTATS)
    response = pineconeHTTPGet(url, ctx)
    if response.status == 200
        return String(response.body)
    end
end

end # module
