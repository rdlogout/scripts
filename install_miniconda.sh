#!/bin/bash

# Miniconda Installation Script for macOS
# This script checks if miniconda is installed and installs it if not present

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if conda is installed
check_conda() {
    if command -v conda &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to get system architecture
get_architecture() {
    arch=$(uname -m)
    case $arch in
        x86_64)
            echo "x86_64"
            ;;
        arm64)
            echo "arm64"
            ;;
        *)
            echo "x86_64"  # Default fallback
            ;;
    esac
}

# Function to initialize conda
initialize_conda() {
    print_info "Initializing conda for your shell..."
    
    # Default conda installation path
    local conda_path="$HOME/miniconda3/bin/conda"
    
    # Check if conda exists in the expected location
    if [[ ! -f "$conda_path" ]]; then
        # Try alternative locations
        local alt_paths=(
            "$HOME/miniconda3/condabin/conda"
            "/usr/local/miniconda3/bin/conda"
            "/opt/miniconda3/bin/conda"
        )
        
        for path in "${alt_paths[@]}"; do
            if [[ -f "$path" ]]; then
                conda_path="$path"
                break
            fi
        done
    fi
    
    if [[ -f "$conda_path" ]]; then
        # Initialize conda for zsh (default shell on macOS)
        if "$conda_path" init zsh &> /dev/null; then
            print_success "Conda initialized successfully for zsh"
        else
            print_warning "Failed to initialize conda for zsh"
        fi
        
        # Also initialize for bash as fallback
        if "$conda_path" init bash &> /dev/null; then
            print_success "Conda initialized successfully for bash"
        else
            print_warning "Failed to initialize conda for bash"
        fi
        
        # Source the shell configuration to make conda available immediately
        if [[ -f "$HOME/.zshrc" ]]; then
            print_info "Sourcing ~/.zshrc to activate conda..."
            # Note: This won't affect the current shell, but will be available in new shells
            print_success "Conda has been initialized! Please restart your terminal or run 'source ~/.zshrc' to activate conda"
        fi
        
        # Try to make conda available in current session
        if [[ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]]; then
            # shellcheck source=/dev/null
            source "$HOME/miniconda3/etc/profile.d/conda.sh"
            print_success "Conda activated in current session"
        fi
        
    else
        print_error "Could not find conda binary for initialization"
        print_info "Please manually run 'conda init' after restarting your terminal"
    fi
}

# Function to download and install miniconda
install_miniconda() {
    local arch=$(get_architecture)
    local installer_name="Miniconda3-latest-MacOSX-${arch}.sh"
    local download_url="https://repo.anaconda.com/miniconda/${installer_name}"
    local installer_path="/tmp/${installer_name}"
    
    print_info "Downloading Miniconda installer for macOS (${arch})..."
    
    # Download the installer
    if curl -fsSL "$download_url" -o "$installer_path"; then
        print_success "Miniconda installer downloaded successfully"
    else
        print_error "Failed to download Miniconda installer"
        exit 1
    fi
    
    # Make the installer executable
    chmod +x "$installer_path"
    
    # Run the installer
    print_info "Installing Miniconda..."
    print_info "Please follow the prompts in the installer"
    print_warning "When prompted, it's recommended to:"
    print_warning "1. Accept the license agreement"
    print_warning "2. Use the default installation location (or specify your preferred location)"
    print_warning "3. Allow the installer to initialize conda (answer 'yes' when asked)"
    
    bash "$installer_path"
    
    # Clean up the installer
    rm -f "$installer_path"
    
    print_success "Miniconda installation completed!"
    
    # Initialize conda automatically
    initialize_conda
    
    # Verify conda installation
    verify_conda_installation
}

# Function to verify conda installation
verify_conda_installation() {
    print_info "Verifying conda installation..."
    
    # Wait a moment for initialization to complete
    sleep 2
    
    # Try to detect conda in various ways
    local conda_found=false
    
    # Method 1: Check if conda command is available
    if command -v conda &> /dev/null; then
        conda_found=true
        print_success "Conda command is available in PATH"
        print_info "Conda version: $(conda --version)"
    else
        # Method 2: Try to source conda and check again
        if [[ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]]; then
            # shellcheck source=/dev/null
            source "$HOME/miniconda3/etc/profile.d/conda.sh"
            if command -v conda &> /dev/null; then
                conda_found=true
                print_success "Conda activated and available"
                print_info "Conda version: $(conda --version)"
            fi
        fi
    fi
    
    if [[ "$conda_found" == true ]]; then
        print_success "Conda installation and initialization completed successfully!"
        print_info "You can now use conda commands"
        print_info "Available environments:"
        conda info --envs 2>/dev/null || print_info "No additional environments found (base environment available)"
    else
        print_warning "Conda installation completed but may not be immediately available"
        print_info "Please restart your terminal or run 'source ~/.zshrc' to activate conda"
    fi
}

# Function to display conda information
display_conda_info() {
    print_info "Conda is already installed!"
    print_info "Conda version: $(conda --version)"
    print_info "Conda info:"
    conda info --envs
}

# Main script execution
main() {
    print_info "Checking for existing Miniconda installation..."
    
    if check_conda; then
        display_conda_info
    else
        print_info "Miniconda not found. Starting installation..."
        
        # Check if we're on macOS
        if [[ "$OSTYPE" != "darwin"* ]]; then
            print_error "This script is designed for macOS only"
            exit 1
        fi
        
        # Ask for user confirmation
        echo
        read -p "Do you want to install Miniconda? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_miniconda
        else
            print_info "Installation cancelled by user"
            exit 0
        fi
    fi
}

# Run the main function
main "$@" 