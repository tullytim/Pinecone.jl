module Pinecone

using JSON3 
using StructTypes

export PineconeContext, PineconeIndex, PineconeVector, whoami, init, list_indexes, query, upsert, delete_index, describe_index_stats, create_index, fetch, delete

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
    values::Array{<:AbstractFloat}
    metadata::Dict{String, Any}
end
Base.show(io::IO, vec::PineconeVector) = print(io, "PineconeVector is id: ", vec.id, " values: ", vec.values, " meta: ", vec.metadata)
# Make PineconeVector type JSON3 writable per https://quinnj.github.io/JSON3.jl/stable/#Read-JSON-into-a-type
StructTypes.StructType(::Type{PineconeVector}) = StructTypes.UnorderedStruct()

include("v3.jl");
include("networking.jl");

const ENDPOINTWHOAMI = "actions/whoami"
const ENDPOINTLISTINDEXES = "databases"
const ENDPOINTDESCRIBEINDEXSTATS = "describe_index_stats"
const ENDPOINTDELETEINDEX = "databases"
const ENDPOINTQUERYINDEX = "query"
const ENDPOINTUPSERT = "vectors/upsert"
const ENDPOINTCREATEINDEX = "databases"
const ENDPOINTFETCH = "vectors/fetch"
const ENDPOINTDELETE = "vectors/delete"
const ENDPOINTSCALEINDEX = "databases"
const MAX_UPSERT_VECTORS = 1000
const MAX_FETCH = 1000
const MAX_TOPK = 10000
const MAX_TOPK_WITH_META = 1000
const MAX_TOPK_WITH_DATA = 1000
const MAX_DIMS = 10000
const MAX_DELETE = 1000


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
function init(apikey::String, environment::String)
    response = pineconeHTTPGet(pineconeMakeURLForController(environment, ENDPOINTWHOAMI), apikey)
    
    rvdict = pineconeGetDict(String(response.body))
    return PineconeContext(apikey, environment, rvdict["project_name"])
end #init

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
function create_index(ctx::PineconeContext, indexname::String, dimension::Int64; metric::String="cosine", pods::Int64=1, replicas::Int64=1, shards::Int64=1, podtype::String="p1")
    if(dimension > MAX_DIMS)
        throw(ArgumentError("Creating index larger than max dimension size of " * string(MAX_DIMS)))
    end
    if(metric != "cosine" && metric != "dotproduct" && metric != "euclidean")
        throw(ArgumentError("Invalid index type.  Type must be one of 'euclidean', 'cosine', or 'dotproduct'."))
    end
    if(pods <= 0)
        throw(ArgumentError("Number of pods must be > 0."))
    end
    if(shards <= 0)
        throw(ArgumentError("Number of shards must be > 0."))
    end
    if(podtype != "p1" && podtype != "s1")
        throw(ArgumentError("Illegal pod type.  Must be p1 or s1."))
    end
    url = pineconeMakeURLForController(ctx.cloudenvironment, ENDPOINTCREATEINDEX)
    postbody = Dict{String, Any}("name"=>indexname, "dimension"=>dimension, "metric"=>metric, "replicas"=>replicas, "shards"=>shards, "pods"=>pods)
  
    response = pineconeHTTPPost(url, ctx, JSON3.write(postbody))
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
function Index(indexname::String)
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
context = Pinecone.init("abcd-123456-zyx", "us-west1-gcp")
index = PineconeIndex("myindex")
result = Pinecone.upsert(context, index, [testvector], "testnamespace")
```
"""
function upsert(ctx::PineconeContext, indexobj::PineconeIndex, vectors::Vector{PineconeVector}, namespace::String="")
    if(length(vectors) > MAX_UPSERT_VECTORS)
        throw(ArgumentError("Max number of vectors per upsert is " * string(MAX_UPSERT_VECTORS)))
    end
    url = pineconeMakeURLForIndex(indexobj, ctx, ENDPOINTUPSERT)
    body = Dict{String, Any}("vectors" => vectors)
    if namespace !== nothing && namespace != ""
        body["namespace"] = namespace
    end
    postbody = JSON3.write(body)
    response = pineconeHTTPPost(url, ctx, postbody)

    return String(response.body)
end #upsert

"""
    upsert(ctx::PineconeContext, indexobj::PineconeIndex, ids::Array{String}, vectors::Vector{Vector{T}}, meta::Array{Dict{String,Any}}=Dict{String,Any}[], namespace::String="") where {T<:AbstractFloat}

upserts an array of vectors into PineconeContext and PineconeIndex with an optional metadata
and namespace (Defaults to not being applied to query if not passed.)
On success returns a JSON blob as a String type, and nothing if it fails. 
This function returns a JSON blob as a string, or nothing if it failed. Do recommend using JSON3 to parse the blob.
If the length of ids and vectors is not equal, which it must be, ``ArgumentError`` is thrown.
If metadata is passed in, that will be tested for length equality with ids and vectors length, with ``ArgumentError`` also thrown is not aligned on length.
# Example
```julia-repl
julia> context = Pinecone.init("abcd-123456-zyx", "us-west1-gcp")
index = PineconeIndex("myindex")
meta = [Dict{String,Any}("foo"=>"bar"), Dict{String,Any}("bar"=>"baz")]
result = Pinecone.upsert(pinecone_context, pinecone_index, ["zipA", "zipB"], [[0.1, 0.2, 0.3, 0.4, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3],
[0.9, 0.8, 0.7, 0.6, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]], meta, "mynamespace")
```
"""

function upsert(ctx::PineconeContext, indexobj::PineconeIndex, ids::Array{String}, vectors::Vector{Vector{T}},
    meta::Array{Dict{String,Any}}=Dict{String,Any}[], namespace::String="") where {T<:AbstractFloat}
    numvectors = length(vectors)
    if(numvectors > MAX_UPSERT_VECTORS)
        throw(ArgumentError("Max number of vectors per upsert is " * string(MAX_UPSERT_VECTORS)))
    end
    numids = length(ids)
    nummeta = (meta !== nothing ? length(meta) : 0)
    if length(ids) !== numvectors 
        throw(ArgumentError("Length of ids does not match length of vectors: $numids vs $numvectors")) 
    end
    if nummeta > 0 && nummeta !== numids
        throw(ArgumentError("Length of ids does not match length of metadata: $numids vs $nummeta"))
    end
    pcvectors = [PineconeVector(ids[i], vectors[i], nummeta > 0 ? meta[i] : Dict{String,Any}()) for i in 1:numvectors]
    upsert(ctx, indexobj, pcvectors, namespace)
end

"""
   query(ctx::PineconeContext, indexobj::PineconeIndex, queries::Vector{PineconeVector}, topk::Int64=10, namespace::String="", includevalues::Bool=false, includemeta::Bool=false, filter::Dict{String, Any}=Dict{String,Any}())

Query an index using the given context that match ``queries`` passed in.  The ``PineconeVector`` that is queries is a simple ``PineconeVector`` as described above.
Note there is an another version of ``query()`` that takes in a ``Vector{Vector{<:AbstractFloat}}`` for the ``queries`` parameter.  Functionally equivalent.
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
function query(ctx::PineconeContext, indexobj::PineconeIndex, queries::PineconeVector, topk::Int64=10, namespace::String="", includevalues::Bool=false, includemeta::Bool=false, filter::Dict{String, Any}=Dict{String,Any}())
    #rawvectors = [queries[i].values for i in 1:length(queries)]
    query(ctx, indexobj, queries.values, topk, namespace, includevalues, includemeta, filter)
end

"""
   query(ctx::PineconeContext, indexobj::PineconeIndex, queries::Vector{Vector{T}}, topk::Int64=10, namespace::String="", includevalues::Bool=false, includemeta::Bool=false, filter::Dict{String, Any}=Dict{String,Any}()) where {T<:AbstractFloat}

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

function query(ctx::PineconeContext, indexobj::PineconeIndex, vector::Vector{T}, topk::Int64=10, namespace::String="", includevalues::Bool=false, 
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
    url = pineconeMakeURLForIndex(indexobj, ctx, ENDPOINTQUERYINDEX)
    body = Dict{String, Any}("topK"=>topk, "vector"=>vector, "includeValues"=>includevalues, "includeMetadata"=>includemeta, "namespace"=>namespace)
    if(length(filter) > 0)
        body["filter"] = filter;
    end
    
    postbody = JSON3.write(body)
    response = pineconeHTTPPost(url, ctx, postbody)
    return String(response.body)
end #query

"""
    fetch(ctx::PineconeContext, indexobj::PineconeIndex, ids::Array{String}, namespace::String)

Fetches vectors based on the vector ids for each vector, provided as the ``ids`` array for a given namespace.  .
Note that namespace is optional, and if not provided defaults to not using it to filter query results by namespace.
Returns JSON blob as ``String`` show below, or ``nothing`` on failure.
# Example
```julia-repl
julia> context = Pinecone.init("asdf-1234-zyxv", "us-west1-gcp")
index = PineconeIndex("my-index")
Pinecone.fetch(context, index, ["testid", "testid2"], "testnamespace")
{"vectors":{"testid":{"id":"testid","values":[0.3,0.11,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3],"metadata":{"year":2019,"genre":"documentary"}},
"testid2":{"id":"testid2","values":[0.3,0.11,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3],"metadata":{"genre":"documentary","year":2019}}},"namespace":"testnamespace"}
```
"""
function fetch(ctx::PineconeContext, indexobj::PineconeIndex, ids::Array{String}, namespace::String="")
    if(length(ids) > MAX_FETCH)
        throw(ArgumentError("Max number of vectors per fetch is " * string(MAX_FETCH)))
    end
    renamedids = ["ids=$row" for row in ids] 
    urlargs = "?" * join(renamedids, "&") * "&namespace=$namespace"
    url = pineconeMakeURLForIndex(indexobj, ctx, ENDPOINTFETCH) * urlargs
    response = pineconeHTTPGet(url, ctx)   
    return String(response.body)
end

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
function delete(ctx::PineconeContext, indexobj::PineconeIndex, ids::Array{String}, deleteall::Bool=false, namespace::String="")
    if(length(ids) > MAX_DELETE)
        throw(ArgumentError("Max number of vectors per delete is " * string(MAX_DELETE)))
    end
    renamedids = ["ids=$row" for row in ids] 
    urlargs = "?" * join(renamedids, "&") * "&deleteAll=" * string(deleteall) * "&namespace=$namespace"
    url = pineconeMakeURLForIndex(indexobj, ctx, ENDPOINTDELETE) * urlargs
    response = pineconeHTTPDelete(url, ctx)
        
    return String(response.body)
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
function list_indexes(context::PineconeContext)
    response = pineconeHTTPGet(pineconeMakeURLForController(context.cloudenvironment, ENDPOINTLISTINDEXES), context)
    return String(response.body)
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
function whoami(context::PineconeContext)
    response = pineconeHTTPGet(pineconeMakeURLForController(context.cloudenvironment, ENDPOINTWHOAMI), context)
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
function delete_index(ctx::PineconeContext, indexobj::PineconeIndex)
    url = pineconeMakeURLForController(ctx.cloudenvironment, ENDPOINTDELETEINDEX * "/" * indexobj.indexname)
    response = pineconeHTTPDelete(url, ctx)
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
function describe_index_stats(ctx::PineconeContext, indexobj::PineconeIndex)
    url = pineconeMakeURLForIndex(indexobj, ctx, ENDPOINTDESCRIBEINDEXSTATS)
    response = pineconeHTTPGet(url, ctx)
    return String(response.body)
end

"""
    scale_index(ctx::PineconeContext, indexobj::PineconeIndex, replicas::Int64)

Scales out the number of replicas for a given index.

# Example
```julia
context = Pinecone.init("abcde-1234-zyxv", "us-west1-gcp")
index = PineconeIndex("my-index")
result = Pinecone.scale_index(context, index, 2)
```
"""
function scale_index(ctx::PineconeContext, indexobj::PineconeIndex, replicas::Int64)
    if replicas < 0
        throw(ArgumentError("Number of replicas should be greater than 0"))
    end
    postbody = Dict{String, Any}("replicas"=>replicas)
    url = pineconeMakeURLForController(ctx.cloudenvironment, ENDPOINTSCALEINDEX) * "/" * indexobj.indexname
    response = pineconeHTTPPatch(url, ctx, JSON3.write(postbody))
    # we get back 204, docs say 200 but they're wrong
    # https://www.pinecone.io/docs/api/operation/scale_index/
end


end # module
