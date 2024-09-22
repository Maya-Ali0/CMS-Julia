
x = [fill(0,100) for i ∈ 1:1000]
function test(x)
    for i ∈ 1 :100
        temp = length( x[i])
        print(temp)
    end
end

@time test(x)