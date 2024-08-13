@testset "v3 API tests" begin
    ctx = Pinecone.init_v3(ENV["PINECONE_API_KEY"])
    Pinecone.create_index(ctx, "my-index", 2, "euclidean");sleep(5)
    @test Set(Pinecone.list_indexes(ctx))  == Set(["my-index", "test-index"])
    i = Pinecone.Index(ctx, "my-index")
    @testset "index obj" begin
        @test i.dimension == 2
        @test i.metric == "euclidean"
        @test i.name == "my-index"
        @test i.spec == Dict("serverless"=>Serverless(
            "aws",
            "us-east-1"
        ))
        @test i.status == Status(
            true,
            "Ready"
        )
    end
    stats = JSON3.read(Pinecone.describe_index_stats(ctx, i), Dict)
    @test stats["namespaces"] == Dict()
    @test stats["dimension"] == 2
    @test stats["indexFullness"] == 0
    @test stats["totalVectorCount"] == 0

    testdict = Dict{String, Any}("genre"=>"documentary", "year"=>2019);
    testvector = Pinecone.PineconeVector("testid", [0.3, 0.3], testdict)
    Pinecone.upsert(ctx, i, [testvector], "testnamespace")
    sleep(5)
    stats = JSON3.read(Pinecone.describe_index_stats(ctx, i), Dict)
    @test stats["namespaces"] == Dict("testnamespace"=>Dict{String, Any}("vectorCount" => 1))
    @test stats["dimension"] == 2
    @test stats["indexFullness"] == 0
    @test stats["totalVectorCount"] == 1

    fetches = JSON3.read(Pinecone.fetch(ctx, i, ["testid"], "testnamespace"), Dict)
    @test fetches["namespace"] == "testnamespace"
    @test fetches["vectors"] == Dict(
        "testid" => Dict(
            "id"=>"testid",
            "metadata"=>Dict(
                "genre" => "documentary",
                "year"=>2019
            ),
            "values"=>[
                0.3,
                0.3
            ]
        )
    )
    #@info JSON3.read(Pinecone.query(ctx, i, testvector, 2, "testnamespace", true, true), Dict)
    delete(ctx, i, ["testid"], false, "testnamespace")
    stats = JSON3.read(Pinecone.describe_index_stats(ctx, i), Dict)
    sleep(5)
    @test stats["namespaces"] == Dict()
    @test stats["dimension"] == 2
    @test stats["indexFullness"] == 0
    @test stats["totalVectorCount"] == 0
    delete_index(ctx, "my-index")
    sleep(5)
    @test Set(Pinecone.list_indexes(ctx))  == Set(["test-index"])
end
