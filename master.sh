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

# Check if sudo is available
has_sudo() {
    command_exists sudo && sudo -n true 2>/dev/null
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
    
    # Add conda to PATH and reload environment
    echo 'export PATH="$HOME/miniconda/bin:$PATH"' >> ~/.bashrc
    export PATH="$HOME/miniconda/bin:$PATH"
    
    # Initialize conda
    $HOME/miniconda/bin/conda init bash
    
    # Source bashrc to reload environment
    source ~/.bashrc 2>/dev/null || true
    
    echo -e "${GREEN}✓ Miniconda installed successfully${NC}"
    echo -e "${YELLOW}Conda is now available in your PATH${NC}"
fi

# Install Cloudflared
echo -e "\n${YELLOW}Checking Cloudflared...${NC}"
if command_exists cloudflared; then
    echo -e "${GREEN}✓ Cloudflared is already installed${NC}"
    cloudflared --version
else
    echo -e "${RED}✗ Cloudflared not found. Installing...${NC}"
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -O cloudflared.deb
    if command_exists dpkg; then
        if has_sudo; then
            sudo dpkg -i cloudflared.deb
        else
            dpkg -i cloudflared.deb
        fi
    else
        # Alternative installation for systems without dpkg
        if has_sudo; then
            sudo wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /usr/local/bin/cloudflared
            sudo chmod +x /usr/local/bin/cloudflared
        else
            wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /usr/local/bin/cloudflared
            chmod +x /usr/local/bin/cloudflared
        fi
    fi
    rm -f cloudflared.deb
    echo -e "${GREEN}✓ Cloudflared installed successfully${NC}"
fi

# Install FFmpeg
echo -e "\n${YELLOW}Checking FFmpeg...${NC}"
if command_exists ffmpeg; then
    echo -e "${GREEN}✓ FFmpeg is already installed${NC}"
    ffmpeg -version | head -1
else
    echo -e "${RED}✗ FFmpeg not found. Installing...${NC}"
    if command_exists apt; then
        if has_sudo; then
            sudo apt update && sudo apt install -y ffmpeg
        else
            apt update && apt install -y ffmpeg
        fi
    elif command_exists yum; then
        if has_sudo; then
            sudo yum install -y ffmpeg
        else
            yum install -y ffmpeg
        fi
    else
        echo -e "${RED}✗ Package manager not found. Please install FFmpeg manually.${NC}"
    fi
    echo -e "${GREEN}✓ FFmpeg installed successfully${NC}"
fi

echo -e "\n${GREEN}=== Installation Complete! ===${NC}"
echo -e "${YELLOW}Note: Conda has been added to your PATH. You can now use conda commands.${NC}"
echo -e "${YELLOW}If conda command is not working, run: export PATH=\"\$HOME/miniconda/bin:\$PATH\"${NC}"

# Test conda availability
if command_exists conda; then
    echo -e "${GREEN}✓ Conda is ready to use!${NC}"
    conda --version
else
    echo -e "${YELLOW}⚠ Conda may need manual PATH setup. Run: export PATH=\"\$HOME/miniconda/bin:\$PATH\"${NC}"
fi
