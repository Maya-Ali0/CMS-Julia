using PackageCompiler

create_app(".", "lib/julia-serial";
    executables=["main.jl" => "cms_executable"],
    include_transitive_dependencies=true,
    precompile_execution_file="main.jl",
    cpu_target="native",
    force=true,
    filter_stdlibs=true
)

println("Compilation complete! Executable is in lib/julia-serial/bin/cms_executable")