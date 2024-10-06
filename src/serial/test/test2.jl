# function test!(x::Vector{Int64})
#     # Directly use a lambda function that does not capture external state
#     increment! = (v) -> x[v] += 1

#     for i in 1:10
#         increment!(1)  # Note: `1` here is used for illustration; adjust as needed.
#     end  
# end

# # Initialize the vector
# x = Vector{Int64}(undef, 10)

# # Measure the time for the modified function
# @time test!(x)


function test(x)
    
    r = -10
    f = v -> x[v] = x[v-1- r] + 1
    for i ∈ 1:1000
        f(i)
    end
end
function t()
    x = Vector{Int64}(undef,1000000)
    @time test(x)
end
module x
end

t()