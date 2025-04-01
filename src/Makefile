ARGS ?=
JULIA := julia
TARGET_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PROJECT_ROOT := $(shell dirname $(TARGET_DIR))
DATA_DIR := $(PROJECT_ROOT)/data
DATA_TAR_GZ := $(DATA_DIR)/data_v2.tar.gz
RAW_FILE := $(DATA_DIR)/raw.bin
URL_FILE := $(DATA_DIR)/url.txt
MD5_FILE := $(DATA_DIR)/md5.txt
COMPILED_DIR := $(TARGET_DIR)/lib/julia-serial
EXECUTABLE := cms_executable

julia-serial: prepare_compiler prepare_env setup download_raw
	@echo "Ensuring required packages..."
	@$(JULIA) --project=$(TARGET_DIR) prepare_compiler_deps.jl
	@echo "Compiling application with PackageCompiler..."
	@$(JULIA) --project=$(TARGET_DIR) compile_app.jl
	@cp $(COMPILED_DIR)/bin/cms_executable ./$(EXECUTABLE)
	@chmod +x ./$(EXECUTABLE)
	@echo "Compilation complete! You can now run ./$(EXECUTABLE)"

prepare_compiler:
	@echo "Setting up PackageCompiler..."
	@$(JULIA) -e 'using Pkg; Pkg.add("PackageCompiler")' >/dev/null 2>&1 || true

run-compiled: $(COMPILED_DIR)/bin/cms_executable
	@echo "Running compiled application..."
	@$(COMPILED_DIR)/bin/cms_executable $(ARGS)

all: prepare_env setup download_raw build

$(DATA_DIR):
	@mkdir -p $(DATA_DIR)

$(DATA_TAR_GZ): $(URL_FILE) | $(DATA_DIR)
	@echo "Downloading data_v2.tar.gz..."
	@curl -L -s -S $$(cat $(URL_FILE)) -o $(DATA_TAR_GZ)

$(RAW_FILE): $(DATA_TAR_GZ) $(MD5_FILE)
	@echo "Extracting raw.bin..."
	@cd $(DATA_DIR) && tar -xzf $(notdir $(DATA_TAR_GZ))
	@echo "Verifying file integrity..."
	@cd $(DATA_DIR) && md5sum -c $(MD5_FILE) >/dev/null 2>&1 || true

download_raw: $(RAW_FILE)

prepare_env:
	@echo "Preparing environment..."
	@$(JULIA) -e 'try; using Pkg; Pkg.activate("$(TARGET_DIR)"); catch e; end' >/dev/null 2>&1 || true
	@$(JULIA) -e 'try; using Pkg; Pkg.add("LinearAlgebra"); catch e; end' >/dev/null 2>&1 || true
	@$(JULIA) -e 'try; using Pkg; Pkg.add("Statistics"); catch e; end' >/dev/null 2>&1 || true
	@$(JULIA) -e 'try; using Pkg; Pkg.add("Test"); catch e; end' >/dev/null 2>&1 || true
	@$(JULIA) -e 'try; using Pkg; Pkg.resolve(); catch e; end' >/dev/null 2>&1 || true
	@$(JULIA) -e 'try; using Pkg; Pkg.instantiate(); catch e; end' >/dev/null 2>&1 || true
	@$(JULIA) -e 'try; using Pkg; Pkg.precompile(); catch e; end' >/dev/null 2>&1 || true

setup:
	@echo "Running Julia setup..."
	@$(JULIA) --project=$(TARGET_DIR) -e 'try; using Pkg; Pkg.instantiate(); catch e; end' >/dev/null 2>&1 || true

build:
	@echo "Building project..."
	# @$(JULIA) --project=$(TARGET_DIR) main.jl
	@./serial.sh $(ARGS)

clean: clean-compiled
	@$(RMFILE) $(DATA_DIR)/*.bin $(DATA_TAR_GZ) 2>nul || true
	@$(RMFILE) ./$(EXECUTABLE) 2>nul || true

clean-compiled:
	@$(RM) $(COMPILED_DIR) 2>nul || true

.PHONY: all prepare_env setup download_raw build clean julia-serial run-compiled clean-compiled prepare_compiler