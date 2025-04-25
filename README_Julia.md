# Patatrack Julia Serial Implementation

This is a Julia implementation of the Patatrack benchmark for CMS pixel reconstruction.

## Prerequisites

- Julia 1.11.5 or later
- Required Julia packages (installed automatically)
- Data files (downloaded automatically)

## Installation

1. **Install Julia**:
   - Download from [Julia's official website](https://julialang.org/downloads/)
   - Or use Juliaup: `curl -fsSL https://install.julialang.org | sh`
   - Set Julia 1.11.5 as default: `juliaup add 1.11.5 && juliaup default 1.11.5`

2. **Clone the repository**:
   ```bash
   git clone https://github.com/Maya-Ali0/CMS-Julia.git
   cd CMS-Julia
   ```

3. **Setup the environment**:
   ```bash
   cd src/julia-serial
   make julia-serial
   ```
   This will:
   - Install required Julia packages
   - Download and extract the necessary data files

## Running the code

Run the code from the `CMS-Julia/src/julia-serial` directory:
```bash
./julia-serial.sh
```

### Command Line Options

```
Usage: ./julia-serial [--numberOfStreams NS] [--warmupEvents WE] [--maxEvents ME] [--runForMinutes RM]
       [--data PATH] [--validation] [--histogram] [--empty]

Options:
  --numberOfStreams    Number of concurrent events (default 0 = numberOfThreads)
  --warmupEvents       Number of events to process before starting the benchmark (default 0)
  --maxEvents          Number of events to process (default -1 for all events in the input file)
  --runForMinutes      Continue processing the set of 1000 events until this many minutes have passed
                       (default -1 for disabled; conflicts with --maxEvents)
  --data               Path to the 'data' directory (default 'data' in the directory of the executable)
  --validation         Run (rudimentary) validation at the end
  --histogram          Produce histograms at the end
  --empty              Ignore all producers (for testing only)
```

## Examples

Process 100 events with validation:
```bash
./julia-serial --maxEvents 100 --validation
```

Run for 5 minutes with 8 streams:
```bash
./julia-serial --runForMinutes 5 --numberOfStreams 8
```

## Troubleshooting

### Common Issues

1. **Permission denied when running ./julia-serial**:
   ```bash
   cd src/julia-serial
   chmod +x julia-serial
   ./julia-serial
   ```

2. **Package installation fails**:
   ```bash
   cd src/julia-serial
   julia --project=. -e 'using Pkg; Pkg.instantiate()'
   ```

3. **Precompilation gets stuck**:
   ```bash
   rm -rf ~/.julia/compiled/
   cd src/julia-serial
   julia --project=. -e 'using Pkg; Pkg.precompile()'
   ```

4. **Data download fails**:
   ```bash
   cd src/julia-serial
   make clean
   make download_raw
   ```

## Building a Standalone Application - Work in progress

To create a standalone application:
```bash
cd src/julia-serial
julia --project=. compile_app.jl
```
The executable will be created in `src/julia-serial/compile/bin/julia_main.exe`.
