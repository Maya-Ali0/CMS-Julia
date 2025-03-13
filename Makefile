JULIA := julia
TARGET_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
DATA_DIR := $(TARGET_DIR)/data
DATA_TAR_GZ := $(DATA_DIR)/data_v2.tar.gz  # Changed to match url.txt content
RAW_FILE := $(DATA_DIR)/raw.bin
URL_FILE := $(DATA_DIR)/url.txt
MD5_FILE := $(DATA_DIR)/md5.txt

all: setup download_raw build

# Ensure the data directory exists
$(DATA_DIR):
    mkdir -p $(DATA_DIR)

# Download the data tar file if it doesn't exist
$(DATA_TAR_GZ): $(URL_FILE) | $(DATA_DIR)
    @echo "Downloading data_v2.tar.gz..."
    curl -L -s -S $$(cat $(URL_FILE)) -o $(DATA_TAR_GZ)

# Extract raw.bin from the tar file and verify integrity
$(RAW_FILE): $(DATA_TAR_GZ) $(MD5_FILE)
    @echo "Extracting raw.bin..."
    cd $(DATA_DIR) && tar -xzf $(notdir $(DATA_TAR_GZ))
    @echo "Verifying file integrity..."
    cd $(DATA_DIR) && md5sum -c $(MD5_FILE)

download_raw: $(RAW_FILE)

# Install project dependencies
setup:
    $(JULIA) --project=$(TARGET_DIR) -e 'using Pkg; Pkg.instantiate()'

# Run the Julia project
build:
    $(JULIA) --project=$(TARGET_DIR) main.jl

# Clean up downloaded and extracted files
clean:
    rm -f $(DATA_DIR)/*.bin $(DATA_TAR_GZ)

.PHONY: all download_raw build clean setup