# Pinecone.jl

*Pinecone client for Julia*

[![CI](https://github.com/tullytim/Pinecone.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/tullytim/Pinecone.jl/actions/workflows/CI.yml)

## Installation

The package can be installed with Julia's package manager,
either by using the Pkg REPL mode (press `]` to enter):
```
pkg> add Pinecone
```
or by using Pkg functions
```julia
julia> using Pkg; Pkg.add("Pinecone")
```

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
the cloud environment for Pinecone that is likely something like "us-west1-gcp". 
From there, you can make function calls similar to what you do in the Python lib.  If you're going to make a call to do something with a specific
index, you'll want to get a pointer to that index using the following:
```julia
pinecone_index = Pinecone.Index("my-index-name");
```
You can then use the context and index "pointers" to make all the necessary API calls, such as:
```julia
#List all indexes for a specific api key (derived from the pinecone_context) object
json = Pinecone.list_indexes(pinecone_context)
#Describe Index using the given context and index pointers
json = Pinecone.describe_index_stats(pinecone_context, pinecone_index)
```
### Interacting With Vector Data
A Pinecone vector is abstracted away with a very simple PineconeVector type.  This type takes 3 parameters:
1. Vector id (String)
2. An Array Array{Float64} representing your dimensions
3. Metadata which is a Julia Dict{String, Any} associated with the dimension data

Here's a very simple example used to create a PineconeVector that will be used with querying data (coming next)
```julia
testdict = Dict{String, Any}("genre"=>"documentary", "year"=>2019);
testvector = Pinecone.PineconeVector("testid", [0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.4,0.3], testdict)
```

PineconeVector is used both querying and upserting data.  In the upsert example, the 3rd param is an Vector{PineconeVector} that is the data to be upserted.
```julia
#upsert data using Vector{PineconeVector}
Pinecone.upsert(pinecone_context, pinecone_index, [testvector], "testnamespace")

#query data using Vector{Vector{Float64}} as the third argument
json = Pinecone.query(pinecone_context, pinecone_index,  
[[0.2, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3], [0.2, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]], 4)
```
