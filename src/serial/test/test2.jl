module B
    include("test1.jl")
    using .A:testing
    
    struct test2
        z::testing
    end
end


