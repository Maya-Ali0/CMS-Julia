JULIA := julia
DATA_DIR := ../../data
DATA_TAR_GZ := $(DATA_DIR)/data_v2.tar.gz
RAW_FILE := $(DATA_DIR)/raw.bin
URL_FILE := $(DATA_DIR)/url.txt
MD5_FILE := $(DATA_DIR)/md5.txt
COMPILED_DIR := lib/julia-serial
EXECUTABLE := julia-serial

julia-serial: prepare_deps download_raw
	@echo "Compiling application with PackageCompiler..."
	@$(JULIA) compile_app.jl
	@cp $(COMPILED_DIR)/bin/cms_executable ./$(EXECUTABLE)
	@chmod +x ./$(EXECUTABLE)
	@echo "Compilation complete! You can now run ./$(EXECUTABLE)"

prepare_deps:
	@echo "Installing PackageCompiler and required packages..."
	@$(JULIA) -e 'using Pkg; Pkg.add("PackageCompiler")'
	@$(JULIA) prepare_compiler_deps.jl

download_raw: $(RAW_FILE)

$(DATA_DIR):
	@mkdir -p $(DATA_DIR)

$(DATA_TAR_GZ): $(URL_FILE) | $(DATA_DIR)
	@echo "Downloading data archive..."
	@curl -L -s -S $$(cat $(URL_FILE)) -o $(DATA_TAR_GZ)

$(RAW_FILE): $(DATA_TAR_GZ) $(MD5_FILE)
	@echo "Extracting raw.bin..."
	@cd $(DATA_DIR) && tar -xzf $(notdir $(DATA_TAR_GZ))
	@echo "Verifying integrity..."
	@cd $(DATA_DIR) && md5sum -c $(notdir $(MD5_FILE))

clean:
	@rm -rf $(COMPILED_DIR)
	@rm -f $(EXECUTABLE)
	@rm -f $(DATA_DIR)/*.bin $(DATA_TAR_GZ)

.PHONY: julia-serial prepare_deps download_raw clean
