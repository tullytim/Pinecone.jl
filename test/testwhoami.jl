using Test
using Pinecone
using JSON3

# API Key from GitHub secrets
GOODAPIKEY = ENV["PINECONE_API_KEY"]
CLOUDENV="us-west1-gcp"
TESTINDEX = "filter-example"

v1 = [0.3,0.11,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3]
v2 = [0.9, 0.8, 0.7, 0.6, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]

@testset "Test whoami()" begin
   println("TEST WITH APIKEY: ", GOODAPIKEY)
   context = Pinecone.init(GOODAPIKEY, CLOUDENV)
   result = Pinecone.whoami(context)
   @test result !== nothing
   @test typeof(result) == String
end