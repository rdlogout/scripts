# Script Collection

This repository contains useful scripts for setting up development environments and running applications.

## Scripts

### 1. install_miniconda.sh

A comprehensive script that checks for and installs Miniconda on macOS with automatic conda initialization.

**Features:**

- Checks if conda is already installed
- Downloads the appropriate Miniconda installer for your system architecture (x86_64 or ARM64)
- Automatically handles conda initialization for both zsh and bash shells
- Verifies installation and provides clear feedback
- Colored output for better readability

**Usage:**

```bash
./install_miniconda.sh
```

The script will:

1. Check if conda is already installed
2. If not installed, download and install Miniconda
3. Automatically run `conda init` for your shell
4. Verify the installation is working properly

### 2. wan.sh

A complete setup and launch script for [Wan2GP](https://github.com/deepbeepmeep/Wan2GP) - a video generation tool.

**Features:**

- **Cross-platform support**: Works on macOS and Linux (Ubuntu/Debian, Red Hat, Arch)
- Automatically installs Miniconda (if not present) - completely self-contained
- Sets up a dedicated conda environment
- Installs PyTorch and all required dependencies
- Launches Wan2GP on a specified port (default: 7860)
- Supports both text-to-video and image-to-video modes
- Handles repository cloning and updates
- No external dependencies or script files needed
- Intelligent shell detection and initialization

**Usage:**

Basic usage (full setup and launch):

```bash
./wan.sh
```

With custom port:

```bash
./wan.sh --port 8080
```

Image-to-video mode:

```bash
./wan.sh --i2v
```

Update existing installation only:

```bash
./wan.sh --update-only
```

Skip conda installation (if already installed):

```bash
./wan.sh --skip-conda
```

Force reinstall all dependencies:

```bash
./wan.sh --force-deps
```

Update and force reinstall dependencies:

```bash
./wan.sh --update-only --force-deps
```

**Command Line Options:**

- `-h, --help`: Show help message
- `-p, --port PORT`: Set the port for Wan2GP (default: 7860)
- `--i2v`: Launch in image-to-video mode
- `--skip-conda`: Skip conda installation (assume already installed)
- `--update-only`: Only update existing installation
- `--force-deps`: Force reinstall all dependencies

**Environment Variables:**

- `PORT`: Override default port

**What the script does:**

1. **Detects your operating system** (macOS or Linux) and architecture
2. **Checks system requirements** (git, curl) with OS-specific install instructions
3. **Installs Miniconda** (if needed) - downloads directly from official source
4. **Automatically initializes conda** for your shell (bash, zsh, fish) and verifies installation
5. **Creates and activates** a conda environment named "wan2gp"
6. **Clones/updates** the Wan2GP repository
7. **Installs PyTorch 2.6.0** and other dependencies
8. **Launches** the Wan2GP application on the specified port

**Access the application:**
Once running, you can access Wan2GP at: `http://localhost:7860` (or your custom port)

## Requirements

- **Operating System**: macOS or Linux (Ubuntu/Debian, Red Hat, Arch, and other distributions)
- **Git**: For cloning repositories
  - macOS: `brew install git` or install Xcode command line tools
  - Ubuntu/Debian: `sudo apt update && sudo apt install git`
  - Red Hat/CentOS: `sudo yum install git`
  - Arch: `sudo pacman -S git`
- **curl**: For downloading installers
  - macOS: Pre-installed or `brew install curl`
  - Ubuntu/Debian: `sudo apt update && sudo apt install curl`
  - Red Hat/CentOS: `sudo yum install curl`
  - Arch: `sudo pacman -S curl`
- **Internet connection**: For downloading dependencies

## Installation

1. Clone this repository or download the scripts
2. Make the scripts executable:
   ```bash
   chmod +x install_miniconda.sh wan.sh
   ```
3. Run the desired script

## Notes

- **Cross-platform compatibility**: Works on macOS and Linux (Ubuntu, Debian, Red Hat, Arch, etc.)
- **Automatic OS detection**: Detects your operating system and architecture automatically
- **Shell intelligence**: Automatically detects and initializes conda for your shell (bash, zsh, fish)
- **Colored output**: Uses colored output for better readability
- **Comprehensive error handling**: Both scripts include detailed error handling with helpful messages
- **Self-contained**: The wan.sh script is completely self-contained and doesn't depend on external files
- **Isolated environments**: All installations are done in isolated conda environments to avoid conflicts
- **Easy interruption**: Press Ctrl+C to stop any running process
- **Non-interactive installation**: Fully automated installation without user prompts
- **Re-run friendly**: Handles existing installations gracefully and can update them
- **Smart updates**: Uses git reset --hard for clean repository updates

## Troubleshooting

If you encounter issues:

1. **Conda not found after installation**: Restart your terminal or run:

   - On macOS/zsh: `source ~/.zshrc`
   - On Linux/bash: `source ~/.bashrc`
   - Or the appropriate config file for your shell

2. **Permission denied**: Make sure the scripts are executable (`chmod +x script_name.sh`)

3. **Port already in use**: Use a different port with `--port` option

4. **Git not found**: Install git using your system's package manager:

   - macOS: `brew install git` or install Xcode command line tools
   - Ubuntu/Debian: `sudo apt update && sudo apt install git`
   - Red Hat/CentOS: `sudo yum install git`
   - Arch: `sudo pacman -S git`

5. **curl not found**: Install curl using your system's package manager:

   - macOS: `brew install curl`
   - Ubuntu/Debian: `sudo apt update && sudo apt install curl`
   - Red Hat/CentOS: `sudo yum install curl`
   - Arch: `sudo pacman -S curl`

6. **Network issues**: Check your internet connection and try again

7. **Architecture issues**: The script auto-detects x86_64 and ARM64/aarch64 architectures

## Contributing

Feel free to submit issues or pull requests to improve these scripts.
