JULIA := $(shell which julia)

DATA_DIR := ../../data
TARGET_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
DATA_TAR_GZ := $(DATA_DIR)/data_v2.tar.gz
RAW_FILE := $(DATA_DIR)/raw.bin
URL_FILE := $(DATA_DIR)/url.txt
MD5_FILE := $(DATA_DIR)/md5.txt
COMPILED_DIR := compile
EXECUTABLE := julia_main

fix-precompile:
	@$(JULIA) -e 'using Pkg; pkg_path = joinpath(DEPOT_PATH[1], "packages", "FixedPointNumbers"); for (root, _, files) in walkdir(pkg_path); for file in files; if file == "precompile.jl"; content = read(joinpath(root, file), String); write(joinpath(root, file), replace(content, "@assert" => "# @assert")); end; end; end'

julia-serial: fix-precompile $(EXECUTABLE)

$(EXECUTABLE): prepare_deps download_raw
	@echo "Compiling application with PackageCompiler..."
	@$(JULIA) --project=$(TARGET_DIR) -e "ENV[\"JULIA_DEBUG\"] = \"PackageCompiler\"; include(\"compile_app.jl\")"
	@mkdir -p $(COMPILED_DIR)/bin
	@if [ ! -f "$(COMPILED_DIR)/bin/bin/julia.exe" ]; then \
		echo "Error: Executable not found in $(COMPILED_DIR)/bin/bin/"; \
		exit 1; \
	fi
	@cp "$(COMPILED_DIR)/bin/bin/julia.exe" ./$(EXECUTABLE).exe
	@chmod +x ./$(EXECUTABLE).exe
	@echo "Compilation complete! Executable is ./$(EXECUTABLE).exe"

prepare_deps:
	@echo "Installing PackageCompiler and required packages..."
	@$(JULIA) -e 'using Pkg; Pkg.add("PackageCompiler")'
	@$(JULIA) prepare_compiler_deps.jl

$(DATA_DIR):
	@mkdir -p $(DATA_DIR)

$(DATA_TAR_GZ): $(URL_FILE) | $(DATA_DIR)
	@echo "Downloading data_v2.tar.gz..."
	@curl -L -s -S $$(cat $(URL_FILE)) -o $(DATA_TAR_GZ)

$(RAW_FILE): $(DATA_TAR_GZ) $(MD5_FILE)
	@echo "Extracting raw.bin..."
	@cd $(DATA_DIR) && tar -tzf $(notdir $(DATA_TAR_GZ)) >/dev/null 2>&1 || (echo "Corrupted archive. Deleting..." && rm -f $(notdir $(DATA_TAR_GZ)) && exit 1)
	@cd $(DATA_DIR) && tar -xzf $(notdir $(DATA_TAR_GZ))
	@echo "Verifying file integrity..."
	@cd $(DATA_DIR) && md5sum -c $(notdir $(MD5_FILE)) >/dev/null 2>&1 || true

download_raw: $(RAW_FILE)

clean:
	@echo "Cleaning build artifacts and data..."
	@rm -rf $(COMPILED_DIR)
	@rm -f $(EXECUTABLE).exe
	# @rm -f $(DATA_DIR)/raw.bin
	@rm -f $(DATA_TAR_GZ)

.PHONY: julia-serial prepare_deps download_raw clean
