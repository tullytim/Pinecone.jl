using HTTP
using JSON3

const HEADER_API_KEY = "Api-Key"
const HEADER_CONTENT_TYPE = "Content-Type"
const CONTENT_TYPE_JSON = "Content-Type: application/json"

pineconeHTTPGet(url::String, ctx::Pinecone.PineconeContext) = begin
    r = HTTP.request(:GET, url,[HEADER_API_KEY=>ctx.apikey]);
    pineconeGetDict(String(r.body))
end

pineconeHTTPGet(url::String, apikey::String) = begin
    r = HTTP.request(:GET, url,[HEADER_API_KEY=>apikey]);
    pineconeGetDict(String(r.body))
end

pineconeHTTPPost(url::String, ctx::Pinecone.PineconeContext, postbody::String="") = begin
    headers = Dict{String, Any}(HEADER_API_KEY=>ctx.apikey, HEADER_CONTENT_TYPE=>CONTENT_TYPE_JSON);
    println("**** HEADERS: ***", headers)
    println("****BODY: ***", postbody)
    r = HTTP.request(:POST, url, headers, postbody);
    print(String(r))
end

pineconeHTTPDelete(url::String, ctx::Pinecone.PineconeContext) = begin
    println("DEL URL: ", url)
    headers = Dict{String, Any}(HEADER_API_KEY=>ctx.apikey);
    println("**** HEADERS: ***", headers)
    r = HTTP.request(:DELETE, url, headers);
end

pineconeGetDict(jsonstring::String) = begin
    println("**** Will parse: $jsonstring")
    JSON3.read(jsonstring)
end

pineconeMakeURLForController(environment::String, endpoint::String) = begin
    rv =  "https://controller." * environment * ".pinecone.io/" * endpoint
    println("URL: " * rv)
    rv
end

# TODO: Fix URL with userid
pineconeMakeURLForIndex(index::Pinecone.PineconeIndex, ctx::Pinecone.PineconeContext, endpoint::String) = begin
    rv =  "https://" * index.indexname * "-" * ctx.projectname * ".svc." * ctx.cloudenvironment * ".pinecone.io/" * endpoint
    println("URL: " * rv);
    rv
end