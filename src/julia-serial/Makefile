JULIA := JULIA
DATA_DIR := ../../data
TARGET_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
DATA_TAR_GZ := $(DATA_DIR)/data_v2.tar.gz
RAW_FILE := $(DATA_DIR)/raw.bin
URL_FILE := $(DATA_DIR)/url.txt
MD5_FILE := $(DATA_DIR)/md5.txt
COMPILED_DIR := lib/julia-serial
EXECUTABLE := julia-serial

julia-serial: $(EXECUTABLE)

$(EXECUTABLE): prepare_deps download_raw
	@echo "Compiling application with PackageCompiler..."
	@$(JULIA) --project=$(TARGET_DIR) compile_app.jl
	@cp $(COMPILED_DIR)/bin/cms_executable ./$(EXECUTABLE)
	@chmod +x ./$(EXECUTABLE)
	@echo "Compilation complete! You can now run ./$(EXECUTABLE)"

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
	@rm -f $(EXECUTABLE)
	# @rm -f $(DATA_DIR)/raw.bin
	@rm -f $(DATA_TAR_GZ)

.PHONY: julia-serial prepare_deps download_raw clean
