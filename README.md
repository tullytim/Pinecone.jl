# Pinecone.jl

*Pinecone client for Julia*

[![CI](https://github.com/tullytim/Pinecone.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/tullytim/Pinecone.jl/actions/workflows/CI.yml)
[![codecov](https://codecov.io/gh/tullytim/Pinecone.jl/branch/main/graph/badge.svg?token=9KN1APH5F5)](https://codecov.io/gh/tullytim/Pinecone.jl)
## Installation

The package can be installed with Julia's package manager,
either by using the Pkg REPL mode (press `]` to enter):
```
pkg> add Pinecone
```
or by using Pkg functions
```julia
julia> using Pkg
julia> Pkg.add("Pinecone")
```
## Project Status
The package is tested against Julia 1.6 on Linux, macOS and Windows.

## Contributing and Questions

Contributions are very welcome, as are feature requests and suggestions.

## Quickstart and Client Examples

The package is a nearly faithful implementation of the native [`Pinecone Python lib`](https://www.pinecone.io/docs/quickstart/).  To get started
simply call 
```julia
using Pinecone
pinecone_context = Pinecone.init(apikey, environment) 
```
which returns a PineconeContext that you'll use for subsequent calls.  apikey is clearly the Pinecone api key you get when you signup, environmens is
the cloud environment for Pinecone that is likely something like "us-west1-gcp". The list of supported environments (and growing):
1. us-west1-gcp
2. eu-west1-gcp
3. us-east-1-aws

From there, you can make function calls similar to what you do in the Python lib.  If you're going to make a call to do something with a specific
index, you'll want to get a pointer to that index using the following:
```julia
julia> pinecone_index = Pinecone.Index("my-index-name");
PineconeIndex connected to my-index-name
```
You can then use the context and index "pointers" to make all the necessary API calls, such as:
```julia
#List all indexes for a specific api key (derived from the pinecone_context) object
julia> Pinecone.list_indexes(pinecone_context)
PineconeIndex connected to my-index-name

#Describe Index using the given context and index pointers
julia> Pinecone.describe_index_stats(pinecone_context, pinecone_index)
{"namespaces":{"":{"vectorCount":5},"testnamespace":{"vectorCount":2},"test_namespace":{"vectorCount":1}},"dimension":10}
```
### Interacting With Vector Data
A Pinecone vector is abstracted away with a very simple PineconeVector type.  This type takes 3 parameters:
1. Vector id (String)
2. An Array Array{Float64} representing your dimensions
3. Metadata which is a Julia Dict{String, Any} associated with the dimension data

Here's a very simple example used to create a PineconeVector that will be used with querying data (coming next)
```julia
julia> testdict = Dict{String, Any}("genre"=>"documentary", "year"=>2019);
julia> testvector = Pinecone.PineconeVector("testid", [0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3], testdict)
PineconeVector is id: testid values: [0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.4, 0.3]meta: Dict{String, Any}("genre" => "documentary", "year" => 2019)
```

PineconeVector is used both querying and upserting data.  In the upsert example, the 3rd param is an Vector{PineconeVector} that is the data to be upserted.
```julia
#upsert data using Vector{PineconeVector}
Pinecone.upsert(pinecone_context, pinecone_index, [testvector], "testnamespace")

#query data using Vector{Vector{Float64}} as the third argument
json = Pinecone.query(pinecone_context, pinecone_index,  
[[0.2, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3], [0.2, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]], 4)

#query data using Vector{PineconeVector} as the third argument
julia> Pinecone.query(pinecone_context, pinecone_index, [testvector, testvector2], 4)
```
The format for the query result is a JSON string:
```json
{"results":[{"matches":[{"id":"C","score":0.0100002466,"values":[0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.3]},{"id":"testid","score":0.0561002381,"values":[0.3,0.11,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3]},{"id":"B","score":0.09000016,"values":[0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2]},{"id":"E","score":0.130000129,"values":[0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4]}],"namespace":""},{"matches":[{"id":"C","score":0.0100002466,"values":[0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.3]},{"id":"testid","score":0.0561002381,"values":[0.3,0.11,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3]},{"id":"B","score":0.09000016,"values":[0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2]},{"id":"E","score":0.130000129,"values":[0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4]}],"namespace":""}]}
```

You can also ask for specific vectors by their id (as specified in the PineconeVector) using the ``fetch()`` function.
In the example below, we will ask for two specific vectors: "testid" and "testid2", which are passed in as an array of strings.
Note that namespace is required.

```julia
Pinecone.fetch(pinecone_context, pinecone_index, ["testid", "testid2"], "testnamespace")
PineconeIndex connected to my-index-name
```

This will return a JSON string:
```json
{"vectors":{"testid":{"id":"testid","values":[0.3,0.11,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3],"metadata":{"genre":"documentary","year":2019}},"testid2":{"id":"testid2","values":[0.3,0.11,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3],"metadata":{"genre":"documentary","year":2019}}},"namespace":"testnamespace"}
```

### Creating/Deleting Indexes
Although you can easily create/delete indexes in the Pinecone console, there may be many times where you need to do this programatically.
Here's a very simple example of how to create an index named "testindex5" with 10 dimensions.  This gives you an index with a single shard  and no additional replicas that will perform approximate nearest neighbor (ANN) search using cosine similarity by default.
```julia
Pinecone.create_index(pinecone_context, "testindex5", 10)
```
There are many optional parameters for create_index().  In the example below, we will create a hybrid index with more replicas.  The ybrid index is created by passing in the indexconfig.  This is discussed at length in the actual Pinecone API docs.
```julia
Pinecone.create_index(pinecone_context, "testindex5", 10, metric="euclidean", indextype="approximated",replicas=2, shards=1, indexconfig=Dict{String,Any}("k_bits"=>512, "hybrid"=>true))
```

Deleting an index is fairly straightforward.  In this example, we will delete the index we created above, named "testindex5"
```julia
Pinecone.delete_index(pinecone_context, Pinecone.Index("testindex5"))
```
