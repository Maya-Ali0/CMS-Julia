using Pkg

Pkg.activate(".")

deps = [
    "ArgParse",
    "BenchmarkTools",
    "CUDA",
    "Dagger",
    "Dates",
    "Printf",
    "InteractiveUtils",
    "DataStructures"
]

for dep in deps
    try
        println("Ensuring dependency: $dep")
        Pkg.add(dep)
    catch e
        println("Failed to add $dep: $e")
    end
end

Pkg.resolve()
Pkg.precompile()
