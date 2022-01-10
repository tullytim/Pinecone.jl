using Test 
using JSON3 
using Pinecone

APIKEY = ENV["PINECONE_API_KEY"]
CLOUDENV="us-west1-gcp"

context = Pinecone.init(APIKEY, CLOUDENV)

INDEX = "filter-example"
NAMESPACE = "mynamespace"
index = Pinecone.Index(INDEX);

testdict = Dict{String, Any}("genre"=>"documentary", "year"=>2019);
v1 = [0.3,0.11,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3]
v2 = [0.9, 0.8, 0.7, 0.6, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]


@testset "PineconeIndex Type Tests" begin
    pineconeindex = PineconeIndex(TESTINDEX)
    @test typeof(pineconeindex) == PineconeIndex
    @test pineconeindex.indexname == TESTINDEX
    pineconeindex = Pinecone.Index(TESTINDEX)
    @test typeof(pineconeindex) == PineconeIndex
    @test pineconeindex.indexname == TESTINDEX
    println("PineconeIndex is ", pineconeindex)
 end;
 
 @testset "PineconeContext Type Tests" begin
    KEY = "asdf-asdfadfs-adsfafds"
    ENV = "us.east.gcp"
    PROJECT = "testproject"
    pineconecontext = PineconeContext(KEY, ENV, PROJECT)
    #testing print out for codecov
    println("pineconecontext is ", pineconecontext)
    @test typeof(pineconecontext) == PineconeContext
    @test pineconecontext.apikey == KEY
    @test pineconecontext.cloudenvironment == ENV
    @test pineconecontext.projectname == PROJECT
 end
 
 @testset "PineconeVector Type Tests" begin
    VID = "vectorid"
    VALUES = [0.1, 0.2, 0.3, 0.4]
    META = Dict{String, Any}("foo"=>"bar", "key"=>"value", "numeric"=>1234)
    pineconevector = PineconeVector(VID, VALUES, META)
    @test typeof(pineconevector) == PineconeVector
    @test pineconevector.id == VID
    @test length(pineconevector.values) == 4
    @test length(pineconevector.metadata) == 3
    @test typeof(pineconevector.metadata) == Dict{String,Any}
    #testing print out for codecov
    println("pineconevector is ", pineconevector)
 end
 
 @testset "Test Init" begin
    #make a bogus init() call, should return nothing
    BADAPIKEY = "zzzz123456"
    context = Pinecone.init(BADAPIKEY, "badcloud")
 
    @test context == nothing
 
    #now check for proper setup
    goodcontext = Pinecone.init(GOODAPIKEY, CLOUDENV)
    @test goodcontext != nothing
    @test typeof(goodcontext) == PineconeContext
 end