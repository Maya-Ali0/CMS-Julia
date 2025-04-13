include("main.jl")
ARGS = ["--maxEvents", "10", "--warmupEvents", "5"]

if abspath(PROGRAM_FILE) == @__FILE__
    exit(julia_main())
end
