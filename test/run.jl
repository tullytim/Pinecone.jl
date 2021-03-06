using Test
include("../src/Pinecone.jl")

@testset "PineconeIndex Type Tests" begin
   TESTINDEX = "test"
   pineconeindex = Pinecone.PineconeIndex(TESTINDEX)
   @test typeof(pineconeindex) == Pinecone.PineconeIndex
   @test pineconeindex.indexname == TESTINDEX
end;

@testset "PineconeContext Type Tests" begin
   KEY = "asdf-asdfadfs-adsfafds"
   ENV = "us.east.gcp"
   PROJECT = "testproject"
   pineconecontext = Pinecone.PineconeContext(KEY, ENV, PROJECT)
   @test typeof(pineconecontext) == Pinecone.PineconeContext
   @test pineconecontext.apikey == KEY
   @test pineconecontext.cloudenvironment == ENV
   @test pineconecontext.projectname == PROJECT
end

@testset "PineconeVector Type Tests" begin
   VID = "vectorid"
   VALUES = [0.1, 0.2, 0.3, 0.4]
   META = Dict{String, Any}("foo"=>"bar", "key"=>"value", "numeric"=>1234)
   pineconevector = Pinecone.PineconeVector(VID, VALUES, META)
   @test typeof(pineconevector) == Pinecone.PineconeVector
   @test pineconevector.id == VID
   @test length(pineconevector.values) == 4
   @test typeof(pineconevector.values) == Vector{Float64}
   @test length(pineconevector.metadata) == 3
   @test typeof(pineconevector.metadata) == Dict{String,Any}
end