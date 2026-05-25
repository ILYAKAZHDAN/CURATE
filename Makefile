### ------------------- ###
### Makefile for CURATE ###
### ------------------- ###

# PLEASE NOTE!
# This file provides the recipe for downloading and setting up the dependencies for CURATE
# By default, it installs the packages via "conda", but also supports "mamba"-based environments.
# If you would like to manage CURATE and its dependencies using "mamba", please use the following commands:

# $ make PKG_manager=mamba --> Install CURATE and its dependencies
# $ make uninstall PKG_manager=mamba --> Uninstall CURATE and its dependencies
# $ make update PKG_manager=mamba --> Update the packages
# $ make test PKG_manager=mamba --> Test the installation status of all packages

### CAUTION! You should NOT modify any part of this file, parameters or code! ###

###### PARAMETERS ######

# CURATE's base environment name for $(PKG_manager)
env=CURATE_env

# The environment YML file; contains the instructions for all the required packages.
env_file=env.yml

# Executable CURATE .sh file (using a wildcard it will match the latest version of CURATE)
ex_file=$$(ls CURATE_*.sh | sort -V | tail -1)

# Default package manager (unless specified otherwise by the user)
PKG_manager ?= conda

###### CODE BELOW ######

### (1) Install ###
# - Installs CURATE's dependencies
# - Makes CURATE executable by adding it to the PATH environment variable ("../env/bin/")
#   -s creates the link
#   -f forces an overwrite to the link, pointing it to a new target
install:
	@test -n "$(ex_file)" || (echo "Error >> Could not find any CURATE_vX.X.sh file! Please make sure it exists - it's required for the installation." && exit 1)
	@command -v $(PKG_manager) >/dev/null 2>&1 || (echo "ERROR >> Could not find $(PKG_manager). Please install it from: https://github.com/conda-forge/miniforge" && exit 1)

	@if $(PKG_manager) env list | grep -q "$(env)"; then \
		echo "Error >> CURATE and its dependencies are already installed! To prevent overwriting, this Makefile will stop here."; \
		echo "         You may re-install them by executing: \"make uninstall\", followed by \"make\""; \
		exit 1; \
	fi

	@test -f $(env_file) || (echo "Error >> Could not find '$(env_file)'. Please make sure it exists and then try again." && exit 1)
	@echo "CURATE >> Installing and setting up CURATE and its dependencies via '$(PKG_manager)' ..."
	@$(PKG_manager) env create -n $(env) -f $(env_file) -y
	@make test

	@echo "CURATE >> Adding '$(ex_file)' to the PATH environment variables..."
	@$(PKG_manager) run -n $(env) bash -c 'ln -sf "$(PWD)/$(ex_file)" "$$CONDA_PREFIX/bin/curate"'
	@chmod +x "$(PWD)/$(ex_file)"
	@echo "CURATE >> CURATE has been successfully installed!"
	@echo "          Activate the environment by: '$(PKG_manager) activate $(env)'"
	@echo "          Get started by executing: 'curate' or './$(ex_file)'"

### (2) Update ###
# - Updates CURATE's dependencies; then tests that all dependencies were installed
# - Updates CURATE's environment variable in PATH
update:
	@test -n "$(ex_file)" || (echo "Error >> Could not find any CURATE_vX.X.sh file! Please make sure it exists - it's required for the installation." && exit 1)
	@command -v $(PKG_manager) >/dev/null 2>&1 || (echo "ERROR >> Could not find $(PKG_manager). Please install it from: https://github.com/conda-forge/miniforge" && exit 1)
	@$(PKG_manager) env list | grep -q "$(env)" || (echo "Error >> CURATE and its dependencies are NOT installed yet. Please install them by executing: \"make\"" && exit 1)
	@test -f $(env_file) || (echo "Error >> Could not find '$(env_file)'. Please make sure it exists and then try again." && exit 1)
	@test -n "$(ex_file)" || (echo "Error >> Could not find any CURATE_vX.X.sh file! Please make sure it exists - it's required for the update." && exit 1)

	@echo "CURATE >> Updating '$(ex_file)' in the PATH environment variables..."
	@$(PKG_manager) run -n $(env) bash -c 'ln -sf "$(PWD)/$(ex_file)" "$$CONDA_PREFIX/bin/curate"'

	@echo "CURATE >> Updating CURATE's dependencies..."
	@$(PKG_manager) env update -n $(env) -f $(env_file) -y --prune
	@echo "CURATE >> Update is complete. Making sure that all required packages are installed ..."
	@test

### (3) Test ###
# Tests and makes sure that all CURATE's dependencies are installed.
test:
	@command -v $(PKG_manager) >/dev/null 2>&1 || (echo "ERROR >> Could not find $(PKG_manager). Please install it from: https://github.com/conda-forge/miniforge" && exit 1)
	@$(PKG_manager) env list | grep -q "$(env)" || (echo "Error >> CURATE and its dependencies are NOT installed yet. Please install them by executing: \"make\"" && exit 1)
	@echo "CURATE >> Testing and checking that all CURATE dependencies are installed..."
	@missing=0
	@for package in samtools bowtie2 fastp curl jq star; do \
		$(PKG_manager) run -n $(env) $$package --version >/dev/null 2>&1 || { echo "* Missing package: $$package"; missing=$$((missing+1)); }; \
	done; \
	$(PKG_manager) run -n $(env) bash -c 'ls $$CONDA_PREFIX/share/trimmomatic*/trimmomatic*.jar' >/dev/null 2>&1 || { echo "* Missing package: trimmomatic"; missing=$$((missing+1)); }; \
	if [[ $$missing -gt 0 ]]; then \
  		echo "Error >> Failed to install $$missing dependencies. Please install all of them before running CURATE or execute: \"make\"."; \
  		exit 1; \
  	fi \

	@echo "CURATE >> Successfully installed all packages!"

### (4) Uninstall ###
# - Removes CURATE's dependencies
# - Remove CURATE's environment variable from PATH
uninstall:
	@command -v $(PKG_manager) >/dev/null 2>&1 || (echo "ERROR >> Could not find $(PKG_manager). Please install it from: https://github.com/$(PKG_manager)-forge/miniforge" && exit 1)
	@$(PKG_manager) env list | grep -q "$(env)" || (echo "Error >> CURATE and its dependencies are NOT installed yet. Please install them by executing: \"make\"" && exit 1)

	@echo "CURATE >> Removing '$(ex_file)' from the PATH environment variables..."
	@$(PKG_manager) run -n $(env) bash -c 'rm -f "$$CONDA_PREFIX/bin/curate"'

	@echo "CURATE >> Uninstalling CURATE and its dependencies from '$(PKG_manager)'..."
	@$(PKG_manager) env remove -n $(env) -y
	@echo "CURATE >> CURATE has been successfully uninstalled!"

# If the user doesn't provide any argument to "make", run "install" and "test" by default
all: install test