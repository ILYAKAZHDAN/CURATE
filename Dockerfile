## CURATE Dockerfile ##
# This Dockerfile contains the instructions code for building a Docker image that
# carries out the installation of the required packages for running CURATE.

# 1) Selects a base image from mambaorg/micromamba:1.5.10
# This creates a minimal Linux-based system (Debian distribution) with micromamba
# as the package manager for installing the required packages.
FROM mambaorg/micromamba:1.5.10

# 2) Creates a new conda environment named 'pipeline' and installs the required packages.
# The packages are installed from the conda-forge and bioconda channels using micromamba.
# Then, it cleans up the cache to save space.
RUN micromamba create -y -n CURATE_env \
    -c conda-forge -c bioconda \
    fastp \
    trimmomatic \
    bowtie2 \
    fastqc \
    blast \
    entrez-direct \
    star \
    samtools \
    && micromamba clean --all --yes

# 3) Sets the PATH environment variable to make all tools available for execution
ENV PATH=/opt/conda/envs/CURATE_env/bin:$PATH

# 4) Sets the default working directory inside the container
# This is where the pipeline will be executed
WORKDIR /work

# 5) Sets the default command to run if the user doesn't specify it
# Defaults to an interactive shell in the Terminal, allowing the user
# to decide what to do inside the container
CMD ["bash"]