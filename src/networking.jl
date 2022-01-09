using HTTP
using JSON3

const HEADER_API_KEY = "Api-Key"
const HEADER_CONTENT_TYPE = "Content-Type"
const CONTENT_TYPE_JSON = "Content-Type: application/json"

#return HTTP response object
pineconeHTTPGet(url::String, ctx::Pinecone.PineconeContext) = begin
    try 
        HTTP.request("GET", url,[HEADER_API_KEY=>ctx.apikey]);
    catch e
        dumpexception(e)
    end
end

#return parsed JSON3 obj
pineconeHTTPGet(url::String, apikey::String) = begin
    try 
        HTTP.request("GET", url,[HEADER_API_KEY=>apikey]);
    catch e
        dumpexception(e)
    end
end

pineconeHTTPPost(url::String, ctx::Pinecone.PineconeContext, postbody::String="") = begin
    headers = Dict{String, Any}(HEADER_API_KEY=>ctx.apikey, HEADER_CONTENT_TYPE=>CONTENT_TYPE_JSON);
    try 
        HTTP.request("POST", url, headers, postbody);
    catch e
        dumpexception(e)
    end
end

pineconeHTTPDelete(url::String, ctx::Pinecone.PineconeContext) = begin
    headers = Dict{String, Any}(HEADER_API_KEY=>ctx.apikey);
    try
        HTTP.request("DELETE", url, headers);
    catch e
        dumpexception(e)
    end
end

pineconeHTTPPatch(url::String, ctx::Pinecone.PineconeContext, postbody::String="") = begin
    headers = Dict{String, Any}(HEADER_API_KEY=>ctx.apikey, HEADER_CONTENT_TYPE=>CONTENT_TYPE_JSON);
    try
        HTTP.request("PATCH", url, headers, postbody);
    catch e
        dumpexception(e)
    end
end

pineconeGetDict(jsonstring::String) = begin
    JSON3.read(jsonstring)
end

pineconeMakeURLForController(environment::String, endpoint::String) = begin
    "https://controller." * environment * ".pinecone.io/" * endpoint
end

# TODO: Fix URL with userid
pineconeMakeURLForIndex(index::Pinecone.PineconeIndex, ctx::Pinecone.PineconeContext, endpoint::String) = begin
    "https://" * index.indexname * "-" * ctx.projectname * ".svc." * ctx.cloudenvironment * ".pinecone.io/" * endpoint
end

dumpexception(e) = println("Error communicating with Pinecone service.  Exception is: \n", e)