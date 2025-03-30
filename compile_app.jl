using PackageCompiler

create_app(".", "compiled_cms";
    executables=["main.jl" => "cms_executable"],
    include_transitive_dependencies=true,
    precompile_execution_file="main.jl",
    cpu_target="native",
    force=true
)

println("Compilation complete! Executable is in compiled_cms/bin/cms_executable")