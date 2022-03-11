using Test 
using JSON3 
using Pinecone

APIKEY = ENV["PINECONE_API_KEY"]
context = Pinecone.init(APIKEY, "us-west1-gcp")

TESTINDEX = "filter-example"
NAMESPACE = "mynamespace"

testdict = Dict{String, Any}("genre"=>"documentary", "year"=>2019);
v1 = [0.3,0.11,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3]
v2 = [0.9, 0.8, 0.7, 0.6, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]


@testset verbose = true "Test query()" begin
    testvector = Pinecone.PineconeVector("testid", v1, testdict)
    index = Pinecone.Index(TESTINDEX)
    #meta = [Dict{String,Any}("foo"=>"bar"), Dict{String,Any}("bar"=>"baz")]
    testvector = Pinecone.PineconeVector("testid", v1, testdict)
    testvector2 = Pinecone.PineconeVector("testid2", v2, testdict)

    result = Pinecone.upsert(context, index, [testvector, testvector2], "")
    result = Pinecone.upsert(context, index, [testvector, testvector2], NAMESPACE)
    #basic test for results
    result = Pinecone.query(context, index, [testvector], 4)
    @test result !== nothing
    @test typeof(result) == String
    rvjson = JSON3.read(result)
    @test haskey(rvjson, "results")
    @test length(rvjson["results"]) > 0

    #basic test for results with a namespace
    result = Pinecone.query(context, index, [testvector], 4, NAMESPACE)
    @test result !== nothing
    @test typeof(result) == String
    rvjson = JSON3.read(result)
    @test haskey(rvjson, "results")
    @test length(rvjson["results"]) > 0

    #test asking for values 
    result = Pinecone.query(context, index, [v1, v1], 4, "", true)
    @test result !== nothing
    @test typeof(result) == String
    rvjson = JSON3.read(result)
    @test haskey(rvjson, "results")
    @test length(rvjson["results"]) > 0
    @test haskey(rvjson["results"][1]["matches"][1], "values")
    @test length(rvjson["results"][1]["matches"][1]["values"]) > 0

      #test asking for values but with namespace
      result = Pinecone.query(context, index, [v1, v1], 4, NAMESPACE, true)
      @test result !== nothing
      @test typeof(result) == String
      rvjson = JSON3.read(result)
      @test haskey(rvjson, "results")
      @test length(rvjson["results"]) > 0
      @test haskey(rvjson["results"][1]["matches"][1], "values")
      @test length(rvjson["results"][1]["matches"][1]["values"]) > 0

    #test no values returned
    result = Pinecone.query(context, index, [v1, v1], 4, "", false)
    @test result !== nothing
    @test typeof(result) == String
    rvjson = JSON3.read(result)
    @test haskey(rvjson, "results")
    @test length(rvjson["results"]) > 0
    @test haskey(rvjson["results"][1]["matches"][1], "values")
    @test length(rvjson["results"][1]["matches"][1]["values"]) == 0

        #test no values returned with namespace
        result = Pinecone.query(context, index, [v1, v1], 4, NAMESPACE, false)
        @test result !== nothing
        @test typeof(result) == String
        rvjson = JSON3.read(result)
        @test haskey(rvjson, "results")
        @test length(rvjson["results"]) > 0
        @test haskey(rvjson["results"][1]["matches"][1], "values")
        @test length(rvjson["results"][1]["matches"][1]["values"]) == 0

     #test metadata returned but values not
     result = Pinecone.query(context, index, [v1, v1], 4, "", false, true)
     @test result !== nothing
     @test typeof(result) == String
     rvjson = JSON3.read(result)
     @test haskey(rvjson, "results")
     @test length(rvjson["results"]) > 0
     @test haskey(rvjson["results"][1]["matches"][1], "metadata")
     @test length(rvjson["results"][1]["matches"][1]["metadata"]) > 0

          #test metadata returned but values not with namespace
          result = Pinecone.query(context, index, [v1, v1], 4, NAMESPACE, false, true)
          @test result !== nothing
          @test typeof(result) == String
          rvjson = JSON3.read(result)
          @test haskey(rvjson, "results")
          @test length(rvjson["results"]) > 0
          @test haskey(rvjson["results"][1]["matches"][1], "metadata")
          @test length(rvjson["results"][1]["matches"][1]["metadata"]) > 0

    #test metadata returned and values returned
    result = Pinecone.query(context, index, [v1, v1], 4, "", true, true)
    @test result !== nothing
    @test typeof(result) == String
    rvjson = JSON3.read(result)
    @test haskey(rvjson, "results")
    @test length(rvjson["results"]) > 0
    @test haskey(rvjson["results"][1]["matches"][1], "metadata")
    @test length(rvjson["results"][1]["matches"][1]["metadata"]) > 0

    #test metadata returned and values returned with namespace
    result = Pinecone.query(context, index, [v1, v1], 4, NAMESPACE, true, true)
    @test result !== nothing
    @test typeof(result) == String
    rvjson = JSON3.read(result)
    @test haskey(rvjson, "results")
    @test length(rvjson["results"]) > 0
    @test haskey(rvjson["results"][1]["matches"][1], "metadata")
    @test length(rvjson["results"][1]["matches"][1]["metadata"]) > 0

    #test metadata not returned but values returned
    result = Pinecone.query(context, index, [v1, v1], 4, "", true, false)
    @test result !== nothing
    @test typeof(result) == String
    rvjson = JSON3.read(result)
    @test haskey(rvjson, "results")
    @test length(rvjson["results"]) > 0
    @test !haskey(rvjson["results"][1]["matches"][1], "metadata")

      #test metadata not returned but values returned with namespace
      result = Pinecone.query(context, index, [v1, v1], 4, NAMESPACE, true, false)
      @test result !== nothing
      @test typeof(result) == String
      rvjson = JSON3.read(result)
      @test haskey(rvjson, "results")
      @test length(rvjson["results"]) > 0
      @test !haskey(rvjson["results"][1]["matches"][1], "metadata")

    @testset "Test Filters" begin
      #...means the "genre" takes on both values.
      moviemeta = [Dict{String, Any}("genre"=>["comedy","documentary"]), Dict{String, Any}("genre"=>["comedy","documentary"])]
      result = Pinecone.upsert(context, index, ["zipA", "zipB"], [[0.1, 0.2, 0.3, 0.4, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3],
[0.9, 0.8, 0.7, 0.6, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]], moviemeta, "mynamespace")
      filter = """{
        "genre": {
          "\$in": [
            "comedy",
            "documentary",
            "drama"
          ]
        },
        "year": {
          "\$eq": 2019
        }
      }"""
      result = Pinecone.query(context, index, [v1], 4, "mynamespace", true, true, JSON3.read(filter, Dict{String, Any}))
      println("result is: ", result)
      rvjson = JSON3.read(result)
      @test haskey(rvjson, "results")
      @test length(rvjson["results"]) > 0
      @test length(rvjson["results"][1]["matches"]) > 0

      #changing to filter to match nothing, now checking that.  Should get no matches since no 'action' in the moviemeta
      filter = """{
        "genre": {
          "\$in": [
            "action"
          ]
        },
        "year": {
          "\$eq": 2019
        }
      }"""
      result = Pinecone.query(context, index, [v1], 4, "mynamespace", true, true, JSON3.read(filter, Dict{String, Any}))
      println("result is: ", result)
      rvjson = JSON3.read(result)
      @test haskey(rvjson, "results")
      @test length(rvjson["results"]) > 0
      @test length(rvjson["results"][1]["matches"]) == 0
    end

    result = Pinecone.query(context, index, [v1, v1], 4)
    @test result !== nothing
    @test typeof(result) == String
    #should get nothing here w/ this bogus namespace
    result = Pinecone.query(context, index, [v1, v1], 4, "bogusempty", true)
    #the bogus namespace returns HTTP 400 but with JSON body.  query() returns nothing so check
    rvjson = JSON3.read(result)
    resultsarr = rvjson["results"];
    @test length(resultsarr) == 2
    #now returns empty results w/ matches that'll have empty array, make sure bogus query is empty
    @test length(resultsarr[1]["matches"]) == 0
 
    println("***************** Test query() topK *****************")
    # test topk exceeded
    @test_throws ArgumentError Pinecone.query(context, index, [testvector], 10001)
 
    println("***************** Test query() topk exceeded include results*************")
    # test topk exceeded when values included in return results
    @test_throws ArgumentError Pinecone.query(context, index, [testvector], 10000, "", true)
    
    # test topk exceeded with alternate query form
    @test_throws ArgumentError Pinecone.query(context, index, [v1], 10001)
    # test topk exceeded when values included in return results
    @test_throws ArgumentError Pinecone.query(context, index, [v1], 10000, "", true)

    # max top k when including data or metadata is 1000, test for 1001 results
    # test topk exceeded when values included in return results with includesvalues=true
    @test_throws ArgumentError Pinecone.query(context, index, [v1], 1001, "", true, false)
    # test topk exceeded when values included in return results with includesmeta=true
    @test_throws ArgumentError Pinecone.query(context, index, [v1], 1001, "", false, true)
 
 end