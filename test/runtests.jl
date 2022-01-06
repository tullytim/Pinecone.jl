using Test
using Pinecone
using JSON3

GOODAPIKEY = ENV["PINECONE_API_KEY"]
CLOUDENV="us-west1-gcp"
TESTINDEX = "filter-example"

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
   @test typeof(pineconevector.values) == Vector{Float64}
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

@testset "Test whoami()" begin
   println("TEST WITH APIKEY: ", GOODAPIKEY)
   context = Pinecone.init(GOODAPIKEY, CLOUDENV)
   result = Pinecone.whoami(context)
   @test result !== nothing
   @test typeof(result) == String
end

@testset "Test list_indexes()" begin
   context = Pinecone.init(GOODAPIKEY, CLOUDENV)
   result = Pinecone.list_indexes(context)
   println("list_indexes() result: ", result)
   @test result !== nothing
   @test typeof(result) == String
   parsed = JSON3.read(result)
   @test length(parsed) >= 0
end

@testset "Test describe_index_stats()" begin
   context = Pinecone.init(GOODAPIKEY, CLOUDENV)
   index = PineconeIndex(TESTINDEX)
   result = Pinecone.describe_index_stats(context, index)
   println("result was $result")
   @test result !== nothing
   @test typeof(result) == String
   parsed = JSON3.read(result)
   @test haskey(parsed, "namespaces") == true
   @test haskey(parsed, "dimension") == true
end

@testset verbose = true "Create/Delete" begin
   context = Pinecone.init(GOODAPIKEY, CLOUDENV)
   testindexname = "unittestindex"
   @testset "Create" begin
      #delete in case already present from previous failure
      result = Pinecone.delete_index(context, Pinecone.Index(testindexname))
      #sleep to wait for delete to go thru, backend takes a bit
      sleep(10)
      indexconfig = Dict{String, Any}("k_bits"=>512, "hybrid"=>true)
      result = Pinecone.create_index(context, testindexname, 10, metric="euclidean", indextype="approximated",replicas=2, shards=1, indexconfig=indexconfig)
      println("CREATE(): ", result)
      @test result == true
   end
   @testset "Delete" begin
      result = Pinecone.delete_index(context, Pinecone.Index(testindexname))
      println("DELETE(): ", result)
      @test result == true
   end
end

@testset verbose = true "Test fetch()" begin
   context = Pinecone.init(GOODAPIKEY, CLOUDENV)
   index = PineconeIndex(TESTINDEX)
   testdict = Dict{String, Any}("genre"=>"documentary", "year"=>2019);
   testvector = Pinecone.PineconeVector("testid", [0.3,0.11,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3], testdict)
   testvector2 = Pinecone.PineconeVector("testid2", [0.3,0.11,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3], testdict)
   Pinecone.upsert(context, index, [testvector, testvector2], "testnamespace")
   result = Pinecone.fetch(context, index, ["testid", "testid2"], "testnamespace")
   println("**FETCH result: $result")
   @test result !== nothing
   @test typeof(result) == String
end

@testset verbose = true "Test query()" begin
   testdict = Dict{String, Any}("genre"=>"documentary", "year"=>2019);
   testvector = Pinecone.PineconeVector("testid", [0.3,0.11,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3], testdict)
   context = Pinecone.init(GOODAPIKEY, CLOUDENV)
   index = PineconeIndex(TESTINDEX)
   result = Pinecone.query(context, index, [testvector], 4)
   @test result !== nothing
   @test typeof(result) == String
   result = Pinecone.query(context, index,  
   [[0.2, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3], [0.2, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]], 4)
   @test result !== nothing
   @test typeof(result) == String
      #should get nothing here w/ this bogus namespace
   result = Pinecone.query(context, index,  
   [[0.2, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3], [0.2, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]], 4, true, "bogusempty")
   println("query() with namepsace result: $result")
   #the bogus namespace returns HTTP 400 but with JSON body.  query() returns nothing so check
   @test result == nothing
end

@testset verbose = true "Test upsert()" begin
   testdict = Dict{String, Any}("genre"=>"documentary", "year"=>2019);
   context = Pinecone.init(GOODAPIKEY, CLOUDENV)
   index = PineconeIndex(TESTINDEX)
   meta = [Dict{String,Any}("foo"=>"bar"), Dict{String,Any}("bar"=>"baz")]

   @testset "Regular upsert()" begin
      testvector = Pinecone.PineconeVector("testid", [0.3,0.11,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3], testdict)

      result = Pinecone.upsert(context, index, [testvector], "testnamespace")

      @test result !== nothing
      @test typeof(result) == String
      #test no namespace

      result = Pinecone.upsert(context, index, [testvector])
      
      @test result !== nothing
      @test typeof(result) == String
   end
   @testset "Upsert with invalid args (ArgumentError)" begin
      #test Arg checking exceptions
      @test_throws ArgumentError Pinecone.upsert(context, index, ["zipA"], [[0.1, 0.2, 0.3, 0.4, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3], [0.9, 0.8, 0.7, 0.6, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]])
      @test_throws ArgumentError Pinecone.upsert(context, index, ["zipA", "zipB"], [[0.9, 0.8, 0.7, 0.6, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]])
      @test_throws ArgumentError Pinecone.upsert(context, index, ["zipA", "zipB"], [[0.1, 0.2, 0.3, 0.4, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3], [0.9, 0.8, 0.7, 0.6, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]],
      [Dict{String,Any}("foo"=>"bar")] )
   end

   @testset "Upsert with zipped vectors and ids" begin
      result = Pinecone.upsert(context, index, ["zipA", "zipB"], [[0.1, 0.2, 0.3, 0.4, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3], [0.9, 0.8, 0.7, 0.6, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]])
      @test result !== nothing
      @test typeof(result) == String

      result = Pinecone.upsert(context, index, ["zipA", "zipB"], [[0.1, 0.2, 0.3, 0.4, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3], [0.9, 0.8, 0.7, 0.6, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]], meta)
      @test result !== nothing
      @test typeof(result) == String

      result = Pinecone.upsert(context, index, ["zipA", "zipB"], [[0.1, 0.2, 0.3, 0.4, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3], [0.9, 0.8, 0.7, 0.6, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]], meta, "mynamespace")
      @test result !== nothing
      @test typeof(result) == String
   end

   @testset "Large upsert()" begin
      context = Pinecone.init(GOODAPIKEY, CLOUDENV)
      largeindex = PineconeIndex("testlargeindex")
      testrows= Vector{PineconeVector}()
      for i in 1:1000
         testvector = Pinecone.PineconeVector("testid_$i", rand(Float64, 10), testdict)
         push!(testrows, testvector)
      end      
      result = Pinecone.upsert(context, largeindex, testrows, "testnamespace")
      @test result !== nothing
      @test typeof(result) == String
   end
end