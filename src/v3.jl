struct PineconeContextv3
    apikey::String
end
Base.show(io::IO, ctx::PineconeContextv3) = print(io, ctx.apikey)
abstract type AbstractSpec end

struct ServerLess <: AbstractSpec
    cloud::String
    region::String
end

@kwdef struct PodSpec <: AbstractSpec
    environment::String
    podtype::String
    ## TBD
end

struct PineconeIndexv3
    dimension::Int
    host::String
    metric::String
    name::String
    spec::Dict{String, ServerLess}
    status::Status
end
Base.show(io::IO, index::PineconeIndexv3) = print(io, "PineconeIndex connected to ", index.name)

StructTypes.StructType(::Type{PineconeIndexv3}) = StructTypes.UnorderedStruct()
StructTypes.StructType(::Type{Status}) = StructTypes.UnorderedStruct()
StructTypes.StructType(::Type{ServerLess}) = StructTypes.UnorderedStruct()

pineconeMakeURLForIndex(index::Pinecone.PineconeIndexv3, endpoint::String) = begin
    "https://"*index.host *"/"* endpoint
end

pineconeMakeURLForIndex(indexname::String) = begin
    "https://api.pinecone.io/indexes/$indexname"
end

pineconeMakeURLForIndex() = begin
    "https://api.pinecone.io/indexes"
end

function create_index(ctx::PineconeContextv3, spec::PineconeIndexv3)
    dimension = index.dimension
    if(dimension > MAX_DIMS)
        throw(ArgumentError("Creating index larger than max dimension size of " * string(MAX_DIMS)))
    end
    metric = index.metric
    if(metric != "cosine" && metric != "dotproduct" && metric != "euclidean")
        throw(ArgumentError("Invalid index type.  Type must be one of 'euclidean', 'cosine', or 'dotproduct'."))
    end
    spec = index.spec
    if spec isa PodSpec
        if(spec.pods <= 0)
            throw(ArgumentError("Number of pods must be > 0."))
        end
        if(spec.shards <= 0)
            throw(ArgumentError("Number of shards must be > 0."))
        end
        if(spec.podtype != "p1" && spec.podtype != "s1")
            throw(ArgumentError("Illegal pod type.  Must be p1 or s1."))
        end
    end
    url = pineconeMakeURLForIndex()
    response = pineconeHTTPPost(url, ctx, JSON3.write(index))
end
