#!/bin/bash

# Wan2GP Setup and Launch Script
# This script automates the complete setup and launch of Wan2GP

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

print_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Configuration
WAN2GP_REPO="https://github.com/deepbeepmeep/Wan2GP.git"
CONDA_ENV_NAME="wan2gp"
PYTHON_VERSION="3.10.9"
TORCH_VERSION="2.7.0"
TORCH_INDEX_URL="https://download.pytorch.org/whl/test/cu124"
DEFAULT_PORT="7860"
WAN2GP_DIR="Wan2GP"

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
            print_info "Conda has been initialized! Please restart your terminal or run 'source ~/.zshrc' to activate conda"
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
    else
        print_warning "Conda installation completed but may not be immediately available"
        print_info "Please restart your terminal or run 'source ~/.zshrc' to activate conda"
    fi
}

# Function to install miniconda
install_miniconda() {
    print_step "Installing Miniconda..."
    
    # Check if we're on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is designed for macOS only"
        exit 1
    fi
    
    # Get system architecture
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
    
    # Run installer in batch mode if possible
    if bash "$installer_path" -b -p "$HOME/miniconda3"; then
        print_success "Miniconda installed successfully in batch mode"
    else
        print_info "Batch installation failed, running interactive installer..."
        bash "$installer_path"
    fi
    
    # Clean up the installer
    rm -f "$installer_path"
    
    print_success "Miniconda installation completed!"
    
    # Initialize conda automatically
    initialize_conda
    
    # Verify conda installation
    verify_conda_installation
    
    # Source conda to make it available in current session
    if [[ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]]; then
        source "$HOME/miniconda3/etc/profile.d/conda.sh"
    fi
}

# Function to setup conda environment
setup_conda_environment() {
    print_step "Setting up conda environment..."
    
    # Check if environment already exists
    if conda env list | grep -q "$CONDA_ENV_NAME"; then
        print_info "Environment $CONDA_ENV_NAME already exists. Activating..."
        conda activate "$CONDA_ENV_NAME"
    else
        print_info "Creating new conda environment: $CONDA_ENV_NAME"
        conda create -n "$CONDA_ENV_NAME" python="$PYTHON_VERSION" -y
        conda activate "$CONDA_ENV_NAME"
        print_success "Conda environment created and activated"
    fi
}

# Function to clone or update Wan2GP repository
setup_wan2gp_repo() {
    print_step "Setting up Wan2GP repository..."
    
    if [[ -d "$WAN2GP_DIR" ]]; then
        print_info "Wan2GP directory exists. Updating..."
        cd "$WAN2GP_DIR"
        git pull
        cd ..
    else
        print_info "Cloning Wan2GP repository..."
        git clone "$WAN2GP_REPO"
    fi
    
    print_success "Wan2GP repository ready"
}

# Function to install dependencies
install_dependencies() {
    print_step "Installing dependencies..."
    
    cd "$WAN2GP_DIR"
    
    # Install PyTorch
    print_info "Installing PyTorch $TORCH_VERSION..."
    pip install "torch==$TORCH_VERSION" torchvision torchaudio --index-url "$TORCH_INDEX_URL"
    
    # Install other requirements
    print_info "Installing requirements from requirements.txt..."
    pip install -r requirements.txt
    
    cd ..
    print_success "Dependencies installed successfully"
}

# Function to launch Wan2GP
launch_wan2gp() {
    print_step "Launching Wan2GP..."
    
    cd "$WAN2GP_DIR"
    
    # Check if wgp.py exists
    if [[ ! -f "wgp.py" ]]; then
        print_error "wgp.py not found in Wan2GP directory"
        exit 1
    fi
    
    # Set environment variable for port if supported
    export PORT="$DEFAULT_PORT"
    export GRADIO_SERVER_PORT="$DEFAULT_PORT"
    
    print_success "Starting Wan2GP on port $DEFAULT_PORT..."
    print_info "Access the interface at: http://localhost:$DEFAULT_PORT"
    print_info "Press Ctrl+C to stop the server"
    
    # Launch the application
    python wgp.py --port "$DEFAULT_PORT" || python wgp.py --server-port "$DEFAULT_PORT" || python wgp.py
}

# Function to check system requirements
check_system_requirements() {
    print_step "Checking system requirements..."
    
    # Check if we're on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_warning "This script is optimized for macOS. Some features may not work on other systems."
    fi
    
    # Check if git is installed
    if ! command -v git &> /dev/null; then
        print_error "Git is required but not installed. Please install git first."
        exit 1
    fi
    
    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        print_error "curl is required but not installed. Please install curl first."
        exit 1
    fi
    
    print_success "System requirements check passed"
}

# Function to display help
show_help() {
    echo "Wan2GP Setup and Launch Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -p, --port PORT         Set the port for Wan2GP (default: 7860)"
    echo "  --i2v                   Launch in image-to-video mode"
    echo "  --skip-conda            Skip conda installation (assume already installed)"
    echo "  --update-only           Only update existing installation"
    echo ""
    echo "Environment Variables:"
    echo "  PORT                    Override default port"
    echo ""
    echo "Examples:"
    echo "  $0                      # Full setup and launch"
    echo "  $0 --port 8080         # Launch on port 8080"
    echo "  $0 --i2v               # Launch in image-to-video mode"
    echo "  $0 --update-only       # Only update existing installation"
}

# Main function
main() {
    local skip_conda=false
    local update_only=false
    local i2v_mode=false
    local port="$DEFAULT_PORT"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -p|--port)
                port="$2"
                shift 2
                ;;
            --i2v)
                i2v_mode=true
                shift
                ;;
            --skip-conda)
                skip_conda=true
                shift
                ;;
            --update-only)
                update_only=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Override port from environment variable if set
    if [[ -n "${PORT:-}" ]]; then
        port="$PORT"
    fi
    
    DEFAULT_PORT="$port"
    
    print_info "Starting Wan2GP setup and launch script..."
    print_info "Target port: $port"
    
    # Check system requirements
    check_system_requirements
    
    # Install miniconda if not skipped and not installed
    if [[ "$skip_conda" == false ]]; then
        if ! check_conda; then
            install_miniconda
        else
            print_info "Conda is already installed"
            # Source conda to make it available in current session
            if [[ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]]; then
                source "$HOME/miniconda3/etc/profile.d/conda.sh"
            fi
        fi
    fi
    
    # Setup conda environment
    setup_conda_environment
    
    # Setup Wan2GP repository
    setup_wan2gp_repo
    
    # Install dependencies
    install_dependencies
    
    if [[ "$update_only" == true ]]; then
        print_success "Update completed successfully!"
        exit 0
    fi
    
    # Launch Wan2GP
    if [[ "$i2v_mode" == true ]]; then
        cd "$WAN2GP_DIR"
        export PORT="$DEFAULT_PORT"
        export GRADIO_SERVER_PORT="$DEFAULT_PORT"
        print_success "Starting Wan2GP in image-to-video mode on port $DEFAULT_PORT..."
        python wgp.py --i2v --port "$DEFAULT_PORT" || python wgp.py --i2v --server-port "$DEFAULT_PORT" || python wgp.py --i2v
    else
        launch_wan2gp
    fi
}

# Handle script interruption
trap 'print_info "Script interrupted by user"; exit 130' INT

# Run main function with all arguments
main "$@" 