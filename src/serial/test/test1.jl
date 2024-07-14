

# Output in a txt file
# opening file with .txt extension and in write mode
 
# let the ans be the output of a question
ans = "Hello World"
 
open("geek.txt", "w") do file
    write(file, ans)
end
