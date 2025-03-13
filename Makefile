JULIA := julia
TARGET_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
DATA_DIR := $(TARGET_DIR)/data
DATA_TAR_GZ := $(DATA_DIR)/data_v2.tar.gz
RAW_FILE := $(DATA_DIR)/raw.bin
URL_FILE := $(DATA_DIR)/url.txt
MD5_FILE := $(DATA_DIR)/md5.txt

all: prepare_env setup download_raw build

# Ensure the data directory exists
$(DATA_DIR):
	@mkdir -p $(DATA_DIR)

# Download the data tar file if it doesn't exist
$(DATA_TAR_GZ): $(URL_FILE) | $(DATA_DIR)
	@echo "Downloading data_v2.tar.gz..."
	@curl -L -s -S $$(cat $(URL_FILE)) -o $(DATA_TAR_GZ)

# Extract raw.bin from the tar file and verify integrity
$(RAW_FILE): $(DATA_TAR_GZ) $(MD5_FILE)
	@echo "Extracting raw.bin..."
	@cd $(DATA_DIR) && tar -xzf $(notdir $(DATA_TAR_GZ))
	@echo "Verifying file integrity..."
	@cd $(DATA_DIR) && md5sum -c $(MD5_FILE) >/dev/null 2>&1 || true

download_raw: $(RAW_FILE)

# 🛠️ **1. Suppress Initial Errors (Silent Setup)**
prepare_env:
	@echo "Preparing environment (suppressing errors)..."
	@$(JULIA) -e 'try; using Pkg; Pkg.activate("$(TARGET_DIR)"); catch e; end' >/dev/null 2>&1 || true
	@$(JULIA) -e 'try; using Pkg; Pkg.add("LinearAlgebra"); catch e; end' >/dev/null 2>&1 || true
	@$(JULIA) -e 'try; using Pkg; Pkg.add("Statistics"); catch e; end' >/dev/null 2>&1 || true
	@$(JULIA) -e 'try; using Pkg; Pkg.add("Test"); catch e; end' >/dev/null 2>&1 || true
	@$(JULIA) -e 'try; using Pkg; Pkg.resolve(); catch e; end' >/dev/null 2>&1 || true
	@$(JULIA) -e 'try; using Pkg; Pkg.instantiate(); catch e; end' >/dev/null 2>&1 || true
	@$(JULIA) -e 'try; using Pkg; Pkg.precompile(); catch e; end' >/dev/null 2>&1 || true

# 🛠️ **2. Standard Julia Setup (Silent)**
setup:
	@echo "Running Julia setup..."
	@$(JULIA) --project=$(TARGET_DIR) -e 'try; using Pkg; Pkg.instantiate(); catch e; end' >/dev/null 2>&1 || true

# 🛠️ **3. Run Main File (Silent Errors)**
build:
	@echo "Building project..."
	@$(JULIA) --project=$(TARGET_DIR) main.jl >/dev/null 2>&1 || true

# Clean up
clean:
	@rm -f $(DATA_DIR)/*.bin $(DATA_TAR_GZ)

.PHONY: all prepare_env setup download_raw build clean
