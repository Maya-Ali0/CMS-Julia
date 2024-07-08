include("source.jl")


reg::ProductRegistry = ProductRegistry(1,Set{UInt64}(),Dict{DataType, Tuple{UInt64, UInt64}}())

testing::Source = Source(1,1,reg,true)

