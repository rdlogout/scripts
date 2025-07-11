#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Installation Script for Conda, Cloudflared, and FFmpeg ===${NC}"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Conda (Miniconda)
echo -e "\n${YELLOW}Checking Conda...${NC}"
if command_exists conda; then
    echo -e "${GREEN}✓ Conda is already installed${NC}"
    conda --version
else
    echo -e "${RED}✗ Conda not found. Installing Miniconda...${NC}"
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh
    bash ~/miniconda.sh -b -p $HOME/miniconda
    rm ~/miniconda.sh
    echo 'export PATH="$HOME/miniconda/bin:$PATH"' >> ~/.bashrc
    export PATH="$HOME/miniconda/bin:$PATH"
    $HOME/miniconda/bin/conda init bash
    echo -e "${GREEN}✓ Miniconda installed successfully${NC}"
fi

# Install Cloudflared
echo -e "\n${YELLOW}Checking Cloudflared...${NC}"
if command_exists cloudflared; then
    echo -e "${GREEN}✓ Cloudflared is already installed${NC}"
    cloudflared --version
else
    echo -e "${RED}✗ Cloudflared not found. Installing...${NC}"
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -O cloudflared.deb
    sudo dpkg -i cloudflared.deb
    rm cloudflared.deb
    echo -e "${GREEN}✓ Cloudflared installed successfully${NC}"
fi

# Install FFmpeg
echo -e "\n${YELLOW}Checking FFmpeg...${NC}"
if command_exists ffmpeg; then
    echo -e "${GREEN}✓ FFmpeg is already installed${NC}"
    ffmpeg -version | head -1
else
    echo -e "${RED}✗ FFmpeg not found. Installing...${NC}"
    sudo apt update
    sudo apt install -y ffmpeg
    echo -e "${GREEN}✓ FFmpeg installed successfully${NC}"
fi

echo -e "\n${GREEN}=== Installation Complete! ===${NC}"
echo -e "${YELLOW}Note: If Conda was just installed, you may need to restart your terminal or run 'source ~/.bashrc' to use conda commands.${NC}"
