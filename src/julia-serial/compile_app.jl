using PackageCompiler

create_app(".", "compile/bin";
    executables=["main.jl" => "julia_main"],
    precompile_execution_file="run_main.jl",
    cpu_target="native",
    force=true,
    filter_stdlibs=true,
    include_lazy_artifacts=true
)

println("Compilation complete! Executable is in compile/bin/julia-main.exe")
