#!/bin/bash

# Print message about the installation process
echo " "
echo "Installer V12, 2024 July 25"
echo "Installation process of RSS selector and LRSS selector..."
echo " "
echo "---------------------- "
echo "Downloading software..."

if [ -e "Optimal_Representative_Strain.zip" ]; then
    echo "The file Optimal_Representative_Strain.zip is present in the folder, unzipping..."
else
    echo "The file Optimal_Representative_Strain.zip is not present in the folder, downloading and unzipping..."
    wget https://probiogenomics.unipr.it/sw/optimal_representative_strain/Optimal_Representative_Strain.zip
fi


unzip Optimal_Representative_Strain.zip
rm Optimal_Representative_Strain.zip

echo " "
echo "This installer will copy all the requested software in $HOME/Documents/Optimal_Representative_Strain/ and will install all dependencies in a dedicated miniconda environment named RSS_selector"
read -r -p "Press any key to continue..." key
echo " "


echo " "
echo "---------------------- "
echo "Directory set-up..."

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Copying environmental databases
mkdir -p $HOME/Documents/
mkdir -p $HOME/Documents/Optimal_Representative_Strain/
cp -r Environmental_Databases $HOME/Documents/Optimal_Representative_Strain/Environmental_Databases
cp -r ORS $HOME/Documents/Optimal_Representative_Strain/ORS
cp -r LAORS $HOME/Documents/Optimal_Representative_Strain/LAORS
echo " "
echo "$HOME/Documents/Optimal_Representative_Strain/Environmental_Databases has been created."

# Add the scripts to PATH
echo 'export PATH=$PATH:$HOME/Documents/Optimal_Representative_Strain/ORS' >> ~/.bashrc
echo 'export PATH=$PATH:$HOME/Documents/Optimal_Representative_Strain/LAORS' >> ~/.bashrc
source ~/.bashrc

# Dependencies
echo " "
echo "---------------------- "
echo "Dependencies set-up..."

# Install conda if not already installed
if ! command_exists conda; then
    echo "Conda not found. Installing Miniconda..."
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O Miniconda3-latest-Linux-x86_64.sh
    bash Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda3
    eval "$($HOME/miniconda3/bin/conda shell.bash hook)"
    conda init
else
    echo "Conda is already installed."
    eval "$(conda shell.bash hook)"
fi

# Create conda environment
ENV_NAME="RSS_selector"
if ! conda env list | grep -q $ENV_NAME; then
    conda create -y -n $ENV_NAME python=3.8
    echo "Conda environment '$ENV_NAME' created."
else
    echo "Conda environment '$ENV_NAME' already exists."
fi

# Activate conda environment
conda activate $ENV_NAME

# Install dependencies using conda

conda install -y -c conda-forge biopython PySimpleGUI
conda install -y -c bioconda instrain bowtie2 bwa hmmer prokka fastani=1.32 mash=2.2 gsl=2.5 mummer prodigal skani drep checkm-genome centrifuge cd-hit


# CheckM database setup
if [ ! -d "$HOME/Documents/Optimal_Representative_Strain/CheckM_database" ]; then
    cd $HOME/Documents/Optimal_Representative_Strain/
    mkdir CheckM_database
    cd CheckM_database
    wget https://data.ace.uq.edu.au/public/CheckM_databases/checkm_data_2015_01_16.tar.gz
    tar -xvzf checkm_data_2015_01_16.tar.gz
    checkm data setRoot $HOME/Documents/Optimal_Representative_Strain/CheckM_database
    echo "CheckM database setup completed."
else
    echo "CheckM database already exists."
fi

# Biopearl dependencies
if ! command_exists bioperl; then
    sudo apt-get -y install libdatetime-perl libxml-simple-perl libdigest-md5-perl git default-jre bioperl
    sudo apt-get -y install libbio-searchio-hmmer-perl
    sudo apt-get -y install ncbi-tools-bin
else
    echo "Biopearl dependencies are already installed."
fi

# Setup Prokka database
if ! command_exists prokka; then
    sudo apt-get -y install prokka
    default_db_dir=$(prokka --help 2>&1 | grep -- '--dbdir' | awk -F"'" '{print $2}')
    mkdir -p $default_db_dir
    rm -R $default_db_dir
    cp -R $HOME/Documents/Optimal_Representative_Strain/software/prokka/db $default_db_dir
    chmod a+wrx $default_db_dir
    prokka --setupdb
else
    echo "Prokka is already installed."
fi

# Setup Diamond aligner
sudo apt-get -y install diamond-aligner

echo " "
echo "---------------------- "
echo "Installation complete"

# Deactivate conda environment
conda deactivate

