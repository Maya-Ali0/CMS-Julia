function potato()
    return 1 
end
module A
    using Main:potato
v = fill(5,5)
x = potato()
end

print(A.v)
print(A.x)