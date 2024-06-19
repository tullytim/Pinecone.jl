using HTTP
using JSON3
using Pinecone

const HEADER_API_KEY = "Api-Key"
const HEADER_CONTENT_TYPE = "Content-Type"
const CONTENT_TYPE_JSON = "Content-Type: application/json"

function dohttp(method, url, headers, body::String="")
    HTTP.request(method, url, headers, body)
end

pineconeHTTPGet(url::String, ctx::Pinecone.PineconeContext) = begin
    dohttp("GET", url,[HEADER_API_KEY=>ctx.apikey])
end

pineconeHTTPGet(url::String, apikey::String) = begin
    dohttp("GET", url,[HEADER_API_KEY=>apikey]);
end

pineconeHTTPPost(url::String, apikey::String, postbody::String="") = begin
    headers = Dict{String, Any}(HEADER_API_KEY=>apikey, HEADER_CONTENT_TYPE=>CONTENT_TYPE_JSON);
    dohttp("POST", url, headers, postbody);
end

pineconeHTTPPost(url::String, ctx::Pinecone.PineconeContext, postbody::String="") = begin
    headers = Dict{String, Any}(HEADER_API_KEY=>ctx.apikey, HEADER_CONTENT_TYPE=>CONTENT_TYPE_JSON);
    dohttp("POST", url, headers, postbody);
end

pineconeHTTPDelete(url::String, apikey::String) = begin
    headers = Dict{String, Any}(HEADER_API_KEY=>apikey);
    dohttp("DELETE", url, headers);
end

pineconeHTTPDelete(url::String, ctx::Pinecone.PineconeContext) = begin
    headers = Dict{String, Any}(HEADER_API_KEY=>ctx.apikey);
    dohttp("DELETE", url, headers);
end

pineconeHTTPPatch(url::String, ctx::Pinecone.PineconeContext, postbody::String="") = begin
    headers = Dict{String, Any}(HEADER_API_KEY=>ctx.apikey, HEADER_CONTENT_TYPE=>CONTENT_TYPE_JSON);
    dohttp("PATCH", url, headers, postbody);
end

pineconeGetDict(jsonstring::String) = begin
    JSON3.read(jsonstring)
end

pineconeMakeURLForController(environment::String, endpoint::String) = begin
    "https://controller." * environment * ".pinecone.io/" * endpoint
end

pineconeMakeURLForIndex(index::Pinecone.PineconeIndex, ctx::Pinecone.PineconeContext, endpoint::String) = begin
    "https://" * index.indexname * "-" * ctx.projectname * ".svc." * ctx.cloudenvironment * ".pinecone.io/" * endpoint
end
