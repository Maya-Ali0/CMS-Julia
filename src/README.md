# Patatrack Standalone Application/Julia README

## Steps to Run the Julia Code

### **1. Install Julia**
If Julia is not installed, download and install it from [Julia's official website](https://julialang.org/downloads/).

Alternatively, if you have the tarball:
```bash
tar -xvzf julia-*.tar.gz
sudo mv julia-x.y.z /opt/julia
sudo ln -s /opt/julia/bin/julia /usr/local/bin/julia
```
Verify installation:
```bash
julia --version
```

### **2. Set Up the Project**
Clone the project repository (if applicable):
```bash
git clone <repo-url>
cd <project-folder>
```

Ensure dependencies are installed:
```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

### **3. Run the Project**
To execute the main script:
```bash
make
```
Alternatively, you can manually run:
```bash
julia --project=. main.jl <args>
```

### **4. Common Errors and Fixes**

#### **Error: `Package StaticArrays is required but does not seem to be installed`**
**Fix:** Run the following command to install dependencies:
```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

#### **Error: Stuck at `Precompiling project...`**
**Fix:**
- Cancel the process using `Ctrl + C`.
- Remove stale compiled files:
  ```bash
  rm -rf ~/.julia/compiled/
  ```
- Try running precompilation manually:
  ```bash
  julia --project=. -e 'using Pkg; Pkg.precompile()'
  ```
- If the issue persists, remove all cached packages:
  ```bash
  rm -rf ~/.julia/packages/*
  rm -rf ~/.julia/clones/*
  ```
  Then re-instantiate dependencies:
  ```bash
  julia --project=. -e 'using Pkg; Pkg.instantiate()'
  ```

#### **Error: `Failed to fetch packages (404 Not Found)`**
**Fix:** Update package sources and retry:
```bash
julia --project=. -e 'using Pkg; Pkg.update()'
```

#### **Error: Makefile Issues**
If `make` does not ensure dependencies are installed, update the `Makefile`:
```make
all: setup run

run:
	$(JULIA) $(JULIA_FLAGS) $(SCRIPT) $(ARGS)

setup:
	$(JULIA) $(JULIA_FLAGS) -e 'using Pkg; Pkg.instantiate()'
```

### **5. Debugging Tips**
- Check system resources:
  ```bash
  htop
  free -h
  ```
- Run Julia in safe mode:
  ```bash
  julia --startup-file=no
  ```
- Enable detailed error tracking:
  ```bash
  julia --project=. -e 'using Pkg; Pkg.precompile()' --track-allocation=user
  ```

### **6. Additional Notes**
- Always ensure Julia is installed and up-to-date.
- If issues persist, try reinstalling Julia.
- For system-wide issues, check logs using:
  ```bash
  tail -n 50 ~/.julia/logs/repl_history.jl
  ```

If you encounter new issues, update this README with their fixes!

