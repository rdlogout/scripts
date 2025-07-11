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
TORCH_VERSION="2.6.0"
TORCH_INDEX_URL_CUDA="https://download.pytorch.org/whl/cu124"
TORCH_INDEX_URL_CPU="https://download.pytorch.org/whl/cpu"
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

# Function to get system information
get_system_info() {
    local os=$(uname -s)
    local arch=$(uname -m)
    
    # Determine OS
    case $os in
        Darwin)
            echo "macos"
            ;;
        Linux)
            echo "linux"
            ;;
        *)
            echo "unsupported"
            ;;
    esac
}

# Function to get system architecture
get_architecture() {
    local arch=$(uname -m)
    local os=$(get_system_info)
    
    case $arch in
        x86_64)
            echo "x86_64"
            ;;
        arm64|aarch64)
            if [[ "$os" == "macos" ]]; then
                echo "arm64"
            else
                echo "aarch64"
            fi
            ;;
        *)
            echo "x86_64"  # Default fallback
            ;;
    esac
}

# Function to detect CUDA availability
detect_cuda() {
    print_info "Detecting CUDA availability..."
    
    # Check if nvidia-smi is available and working
    if command -v nvidia-smi &> /dev/null; then
        if nvidia-smi &> /dev/null; then
            print_success "NVIDIA GPU detected"
            nvidia-smi --query-gpu=name --format=csv,noheader,nounits | head -1 | while read gpu_name; do
                print_info "GPU: $gpu_name"
            done
            return 0
        else
            print_warning "nvidia-smi found but failed to run"
            return 1
        fi
    fi
    
    # Check if nvcc is available
    if command -v nvcc &> /dev/null; then
        print_info "CUDA compiler detected"
        return 0
    fi
    
    # Check for CUDA installation directories
    if [[ -d "/usr/local/cuda" ]] || [[ -d "/opt/cuda" ]]; then
        print_info "CUDA installation directory found"
        return 0
    fi
    
    # Check for CUDA libraries
    if ldconfig -p 2>/dev/null | grep -q "libcuda.so"; then
        print_info "CUDA libraries detected"
        return 0
    fi
    
    print_info "No CUDA GPU detected, will use CPU-only PyTorch"
    return 1
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
        # Get current shell
        local current_shell=$(basename "$SHELL")
        
        # Initialize conda for current shell
        if "$conda_path" init "$current_shell" &> /dev/null; then
            print_success "Conda initialized successfully for $current_shell"
        else
            print_warning "Failed to initialize conda for $current_shell"
        fi
        
        # Also initialize for bash as fallback (most common)
        if [[ "$current_shell" != "bash" ]]; then
            if "$conda_path" init bash &> /dev/null; then
                print_success "Conda initialized successfully for bash"
            else
                print_warning "Failed to initialize conda for bash"
            fi
        fi
        
        # Initialize for zsh if on macOS or if zsh is available
        if [[ "$current_shell" != "zsh" ]] && command -v zsh &> /dev/null; then
            if "$conda_path" init zsh &> /dev/null; then
                print_success "Conda initialized successfully for zsh"
            else
                print_warning "Failed to initialize conda for zsh"
            fi
        fi
        
        # Source the shell configuration to make conda available immediately
        local config_file=""
        case "$current_shell" in
            bash)
                config_file="$HOME/.bashrc"
                ;;
            zsh)
                config_file="$HOME/.zshrc"
                ;;
            fish)
                config_file="$HOME/.config/fish/config.fish"
                ;;
            *)
                config_file="$HOME/.bashrc"
                ;;
        esac
        
        if [[ -f "$config_file" ]]; then
            print_info "Conda has been initialized! Please restart your terminal or run 'source $config_file' to activate conda"
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
    
    # Check if miniconda directory already exists
    if [[ -d "$HOME/miniconda3" ]]; then
        print_info "Miniconda directory already exists at $HOME/miniconda3"
        
        # Check if it's a valid conda installation
        if [[ -f "$HOME/miniconda3/bin/conda" ]] || [[ -f "$HOME/miniconda3/condabin/conda" ]]; then
            print_success "Valid Miniconda installation found, skipping installation"
            
            # Initialize conda automatically
            initialize_conda
            
            # Source conda to make it available in current session
            if [[ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]]; then
                source "$HOME/miniconda3/etc/profile.d/conda.sh"
            fi
            return 0
        else
            print_warning "Miniconda directory exists but appears corrupted, removing and reinstalling..."
            rm -rf "$HOME/miniconda3"
        fi
    fi
    
    # Get system information
    local os=$(get_system_info)
    local arch=$(get_architecture)
    
    # Check if OS is supported
    if [[ "$os" == "unsupported" ]]; then
        print_error "Unsupported operating system: $(uname -s)"
        print_info "This script supports macOS and Linux-based systems"
        exit 1
    fi
    
    # Set installer name based on OS and architecture
    local installer_name=""
    local download_url=""
    
    case "$os" in
        macos)
            installer_name="Miniconda3-latest-MacOSX-${arch}.sh"
            ;;
        linux)
            installer_name="Miniconda3-latest-Linux-${arch}.sh"
            ;;
    esac
    
    download_url="https://repo.anaconda.com/miniconda/${installer_name}"
    local installer_path="/tmp/${installer_name}"
    
    print_info "Downloading Miniconda installer for $os (${arch})..."
    
    # Download the installer
    if curl -fsSL "$download_url" -o "$installer_path"; then
        print_success "Miniconda installer downloaded successfully"
    else
        print_error "Failed to download Miniconda installer"
        print_info "URL: $download_url"
        exit 1
    fi
    
    # Make the installer executable
    chmod +x "$installer_path"
    
    # Run the installer in batch mode (completely non-interactive)
    print_info "Installing Miniconda in batch mode (non-interactive)..."
    
    if bash "$installer_path" -b -p "$HOME/miniconda3"; then
        print_success "Miniconda installed successfully in batch mode"
    else
        print_error "Batch installation failed"
        exit 1
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
    
    # Make sure conda is available
    if ! command -v conda &> /dev/null; then
        if [[ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]]; then
            source "$HOME/miniconda3/etc/profile.d/conda.sh"
        fi
    fi
    
    # Check if environment already exists
    if conda env list | grep -q "$CONDA_ENV_NAME"; then
        print_info "Environment $CONDA_ENV_NAME already exists. Activating..."
        conda activate "$CONDA_ENV_NAME"
        print_success "Conda environment activated"
    else
        print_info "Creating new conda environment: $CONDA_ENV_NAME"
        conda create -n "$CONDA_ENV_NAME" python="$PYTHON_VERSION" -y
        conda activate "$CONDA_ENV_NAME"
        print_success "Conda environment created and activated"
    fi
    
    # Verify the environment is active
    if [[ "$CONDA_DEFAULT_ENV" == "$CONDA_ENV_NAME" ]]; then
        print_success "Currently active environment: $CONDA_DEFAULT_ENV"
    else
        print_warning "Environment activation may not have worked correctly"
    fi
}

# Function to clone or update Wan2GP repository
setup_wan2gp_repo() {
    print_step "Setting up Wan2GP repository..."
    
    if [[ -d "$WAN2GP_DIR" ]]; then
        print_info "Wan2GP directory exists. Updating..."
        cd "$WAN2GP_DIR"
        
        # Check if it's a valid git repository
        if git rev-parse --git-dir > /dev/null 2>&1; then
            print_info "Updating existing repository..."
            git fetch origin
            git reset --hard origin/main
            print_success "Repository updated successfully"
        else
            print_warning "Directory exists but is not a valid git repository, removing and cloning..."
            cd ..
            rm -rf "$WAN2GP_DIR"
            git clone "$WAN2GP_REPO"
        fi
        cd ..
    else
        print_info "Cloning Wan2GP repository..."
        git clone "$WAN2GP_REPO"
    fi
    
    print_success "Wan2GP repository ready"
}

# Function to install dependencies
install_dependencies() {
    local force_deps=${1:-false}
    print_step "Installing dependencies..."
    
    cd "$WAN2GP_DIR"
    
    # Check if requirements.txt exists
    if [[ ! -f "requirements.txt" ]]; then
        print_error "requirements.txt not found in Wan2GP directory"
        cd ..
        exit 1
    fi
    
    # Detect CUDA availability
    print_info "Detecting CUDA support..."
    local torch_index_url=""
    local cuda_suffix=""
    
    if detect_cuda; then
        torch_index_url="$TORCH_INDEX_URL_CUDA"
        cuda_suffix="+cu124"
        print_success "CUDA detected - installing PyTorch with CUDA support"
    else
        torch_index_url="$TORCH_INDEX_URL_CPU"
        cuda_suffix=""
        print_info "No CUDA detected - installing CPU-only PyTorch"
    fi
    
    # Install PyTorch
    print_info "Installing PyTorch $TORCH_VERSION with appropriate backend..."
    if [[ "$force_deps" == true ]]; then
        pip install "torch==$TORCH_VERSION$cuda_suffix" "torchvision" "torchaudio" --index-url "$torch_index_url" --force-reinstall
    else
        pip install "torch==$TORCH_VERSION$cuda_suffix" "torchvision" "torchaudio" --index-url "$torch_index_url"
    fi
    
    # Verify PyTorch installation
    print_info "Verifying PyTorch installation..."
    if python -c "import torch; print(f'PyTorch version: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}')" 2>/dev/null; then
        print_success "PyTorch installation verified"
        
        # If CUDA was detected but PyTorch can't use it, provide troubleshooting
        if [[ "$cuda_suffix" == "+cu124" ]]; then
            if ! python -c "import torch; assert torch.cuda.is_available()" 2>/dev/null; then
                print_warning "CUDA GPU detected but PyTorch cannot access it"
                print_info "Troubleshooting tips:"
                print_info "1. Check CUDA runtime: nvidia-smi"
                print_info "2. Verify CUDA version compatibility"
                print_info "3. Try running: export CUDA_VISIBLE_DEVICES=0"
                print_info "4. Restart the script with --force-deps to reinstall PyTorch"
            fi
        fi
    else
        print_warning "PyTorch installation verification failed, but continuing..."
    fi
    
    # Install other requirements
    print_info "Installing requirements from requirements.txt..."
    if [[ "$force_deps" == true ]]; then
        pip install -r requirements.txt --force-reinstall
    else
        pip install -r requirements.txt --upgrade
    fi
    
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
    
    # Pre-launch CUDA check
    print_info "Performing pre-launch checks..."
    if python -c "import torch; print('PyTorch version:', torch.__version__); print('CUDA available:', torch.cuda.is_available())" 2>/dev/null; then
        print_success "PyTorch is working correctly"
    else
        print_warning "PyTorch may have issues, but attempting to launch anyway..."
    fi
    
    # Set environment variables
    export PORT="$DEFAULT_PORT"
    export GRADIO_SERVER_PORT="$DEFAULT_PORT"
    
    # Try to set CUDA device if available
    if command -v nvidia-smi &> /dev/null && nvidia-smi &> /dev/null; then
        export CUDA_VISIBLE_DEVICES=0
        print_info "CUDA device set to GPU 0"
    fi
    
    print_success "Starting Wan2GP on port $DEFAULT_PORT..."
    print_info "Access the interface at: http://localhost:$DEFAULT_PORT"
    print_info "Press Ctrl+C to stop the server"
    
    # Launch the application with better error handling
    if python wgp.py --port "$DEFAULT_PORT" 2>&1; then
        print_success "Wan2GP launched successfully"
    elif python wgp.py --server-port "$DEFAULT_PORT" 2>&1; then
        print_success "Wan2GP launched successfully"
    elif python wgp.py 2>&1; then
        print_success "Wan2GP launched successfully"
    else
        print_error "Failed to launch Wan2GP"
        print_info "Check the error messages above for troubleshooting"
        exit 1
    fi
}

# Function to check system requirements
check_system_requirements() {
    print_step "Checking system requirements..."
    
    # Get system information
    local os=$(get_system_info)
    
    # Check if OS is supported
    case "$os" in
        macos)
            print_info "Detected macOS system"
            ;;
        linux)
            print_info "Detected Linux system"
            # Check if we're on Ubuntu/Debian-based system
            if command -v apt &> /dev/null; then
                print_info "Detected Debian/Ubuntu-based system"
            elif command -v yum &> /dev/null; then
                print_info "Detected Red Hat-based system"
            elif command -v pacman &> /dev/null; then
                print_info "Detected Arch-based system"
            fi
            ;;
        unsupported)
            print_error "Unsupported operating system: $(uname -s)"
            print_info "This script supports macOS and Linux-based systems"
            exit 1
            ;;
    esac
    
    # Check if git is installed
    if ! command -v git &> /dev/null; then
        print_error "Git is required but not installed."
        case "$os" in
            macos)
                print_info "Install git using: brew install git or install Xcode command line tools"
                ;;
            linux)
                if command -v apt &> /dev/null; then
                    print_info "Install git using: sudo apt update && sudo apt install git"
                elif command -v yum &> /dev/null; then
                    print_info "Install git using: sudo yum install git"
                elif command -v pacman &> /dev/null; then
                    print_info "Install git using: sudo pacman -S git"
                else
                    print_info "Install git using your system's package manager"
                fi
                ;;
        esac
        exit 1
    fi
    
    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        print_error "curl is required but not installed."
        case "$os" in
            macos)
                print_info "curl should be pre-installed on macOS. Try: brew install curl"
                ;;
            linux)
                if command -v apt &> /dev/null; then
                    print_info "Install curl using: sudo apt update && sudo apt install curl"
                elif command -v yum &> /dev/null; then
                    print_info "Install curl using: sudo yum install curl"
                elif command -v pacman &> /dev/null; then
                    print_info "Install curl using: sudo pacman -S curl"
                else
                    print_info "Install curl using your system's package manager"
                fi
                ;;
        esac
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
    echo "  --force-deps            Force reinstall all dependencies"
    echo ""
    echo "Environment Variables:"
    echo "  PORT                    Override default port"
    echo ""
    echo "Examples:"
    echo "  $0                      # Full setup and launch"
    echo "  $0 --port 8080         # Launch on port 8080"
    echo "  $0 --i2v               # Launch in image-to-video mode"
    echo "  $0 --update-only       # Only update existing installation"
    echo "  $0 --force-deps        # Force reinstall all dependencies"
}

# Main function
main() {
    local skip_conda=false
    local update_only=false
    local i2v_mode=false
    local force_deps=false
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
            --force-deps)
                force_deps=true
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
    install_dependencies "$force_deps"
    
    if [[ "$update_only" == true ]]; then
        print_success "Update completed successfully!"
        if [[ "$force_deps" == true ]]; then
            print_info "Also reinstalling dependencies due to --force-deps flag..."
            install_dependencies "$force_deps"
        else
            print_info "Use --force-deps flag if you want to force reinstall dependencies"
        fi
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