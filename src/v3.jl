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

function list_indexes(ctx::PineconeContextv3)
    objs = list_index_objects(ctx)
    map(x->x.name, objs)
end

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

function delete_index(ctx::PineconeContextv3, indexname::String)
    url = pineconeMakeURLForIndex(indexname)
    response = pineconeHTTPDelete(url, ctx.apikey)
end

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

