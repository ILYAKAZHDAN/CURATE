### ------------------- ###
### Makefile for CURATE ###
### ------------------- ###

# This file provides the recipe for downloading and setting up the dependencies for CURATE
# By default, it installs the packages in a "mamba" virtual environment

### CAUTION! You should NOT modify any part of this file, parameters or code! ###

###### PARAMETERS ######

# CURATE's base environment name for mamba
env=CURATE_env 

# The environment YML file; contains the instructions for all the required packages.
env_file=env.yml 

# Executable CURATE .sh file (using a wildcard it will match the latest version of CURATE)
ex_file=$$(ls CURATE_*.sh | sort -V | tail -1)

###### CODE BELOW ######

### (1) Install ###
# - Installs CURATE's dependencies
# - Makes CURATE executable by adding it to the PATH environment variable ("../env/bin/")
#   -s creates the link
#   -f forces an overwrite to the link, pointing it to a new target
install:
	@test -n "$(ex_file)" || (echo "Error >> Could not find any CURATE_vX.X.sh file! Please make sure it exists - it's required for the installation." && exit 1)
	
	@if mamba env list | grep -q "$(env)"; then \
		echo "Error >> CURATE and its dependencies are already installed! To prevent overwriting, this Makefile will stop here."; \
		echo "         You may re-install them by executing: \"make uninstall\", followed by \"make\""; \
		exit 1; \
	fi

	@test -f $(env_file) || (echo "Error >> Could not find '$(env_file)'. Please make sure it exists and then try again." && exit 1)
	@echo "CURATE >> Installing and setting up CURATE and its dependencies ..."
	@mamba env create -n $(env) -f $(env_file) -y
	@make test

	@echo "CURATE >> Adding '$(ex_file)' to the PATH environment variables..."
	@ln -sf "$(PWD)/$(ex_file)" "$$CONDA_PREFIX/bin/curate"
	@chmod +x "$(PWD)/$(ex_file)"
	@echo "CURATE >> CURATE has been successfully installed!"
	@echo "          Get started by executing: 'curate' or './$(ex_file)'"

### (2) Update ###
# - Updates CURATE's dependencies; then tests that all dependencies were installed
# - Updates CURATE's environment variable in PATH
update:
	@test -n "$(ex_file)" || (echo "Error >> Could not find any CURATE_vX.X.sh file! Please make sure it exists - it's required for the installation." && exit 1)
	@command -v mamba >/dev/null 2>&1 || (echo "ERROR >> Could not find Mamba. Please install it from: https://github.com/conda-forge/miniforge" && exit 1)
	@mamba env list | grep -q "$(env)" || (echo "Error >> CURATE and its dependencies are NOT installed yet. Please install them by executing: \"make\"" && exit 1)
	@test -f $(env_file) || (echo "Error >> Could not find '$(env_file)'. Please make sure it exists and then try again." && exit 1)
	@test -n "$(ex_file)" || (echo "Error >> Could not find any CURATE_vX.X.sh file! Please make sure it exists - it's required for the update." && exit 1)
	@echo "CURATE >> Updating CURATE's dependencies..."
	@mamba env update -n $(env) -f $(env_file) -y --prune
	@echo "CURATE >> Update is complete. Making sure that all required packages are installed ..."
	@test

### (3) Test ###
# Tests and makes sure that all CURATE's dependencies are installed.
test:
	@command -v mamba >/dev/null 2>&1 || (echo "ERROR >> Could not find Mamba. Please install it from: https://github.com/conda-forge/miniforge" && exit 1)
	@mamba env list | grep -q "$(env)" || (echo "Error >> CURATE and its dependencies are NOT installed yet. Please install them by executing: \"make\"" && exit 1)
	@echo "CURATE >> Testing and checking that all CURATE dependencies are installed..."
	@missing=0
	@for package in samtools bowtie2 fastp curl jq star; do \
		mamba run -n $(env) $$package --version >/dev/null 2>&1 || { echo "* Missing package: $$package"; missing=$$((missing+1)); }; \
	done; \
	mamba run -n $(env) bash -c "ls $$CONDA_PREFIX/share/trimmomatic*/trimmomatic*.jar" >/dev/null 2>&1 || { echo "* Missing package: trimmomatic"; missing=$$((missing+1)); }; \
	if [[ $$missing -gt 0 ]]; then \
  		echo "Error >> Failed to install $$missing dependencies. Please install all of them before running CURATE or execute: \"make\"."; \
  		exit 1; \
  	fi \

	@echo "CURATE >> Successfully installed all packages!"

### (4) Uninstall ###
# - Removes CURATE's dependencies
# - Remove CURATE's environment variable from PATH
uninstall:
	@command -v mamba >/dev/null 2>&1 || (echo "ERROR >> Could not find Mamba. Please install it from: https://github.com/conda-forge/miniforge" && exit 1)
	@mamba env list | grep -q "$(env)" || (echo "Error >> CURATE and its dependencies are NOT installed yet. Please install them by executing: \"make\"" && exit 1)
	@echo "CURATE >> Uninstalling CURATE and its dependencies..."
	@mamba env remove -n $(env) -y

	@echo "CURATE >> Removing '$(ex_file)' from the PATH environment variables..."
	@rm -f "$$CONDA_PREFIX/bin/curate"
	@echo "CURATE >> CURATE has been successfully uninstalled!"

# If the user doesn't provide any argument to "make", run "install" and "test" by default
all: install test