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

- Automatically installs Miniconda (if not present) - completely self-contained
- Sets up a dedicated conda environment
- Installs PyTorch and all required dependencies
- Launches Wan2GP on a specified port (default: 7860)
- Supports both text-to-video and image-to-video modes
- Handles repository cloning and updates
- No external dependencies or script files needed

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

**Command Line Options:**

- `-h, --help`: Show help message
- `-p, --port PORT`: Set the port for Wan2GP (default: 7860)
- `--i2v`: Launch in image-to-video mode
- `--skip-conda`: Skip conda installation (assume already installed)
- `--update-only`: Only update existing installation

**Environment Variables:**

- `PORT`: Override default port

**What the script does:**

1. Checks system requirements (git, curl)
2. Installs Miniconda (if needed) - downloads directly from official source
3. Automatically initializes conda and verifies installation
4. Creates and activates a conda environment named "wan2gp"
5. Clones/updates the Wan2GP repository
6. Installs PyTorch 2.7.0 and other dependencies
7. Launches the Wan2GP application on the specified port

**Access the application:**
Once running, you can access Wan2GP at: `http://localhost:7860` (or your custom port)

## Requirements

- macOS (scripts are optimized for macOS but may work on other Unix-like systems)
- Git (for cloning repositories)
- curl (for downloading installers)
- Internet connection (for downloading dependencies)

## Installation

1. Clone this repository or download the scripts
2. Make the scripts executable:
   ```bash
   chmod +x install_miniconda.sh wan.sh
   ```
3. Run the desired script

## Notes

- The scripts use colored output for better readability
- Both scripts include comprehensive error handling
- The wan.sh script is completely self-contained and doesn't depend on external files
- All installations are done in isolated conda environments to avoid conflicts
- Press Ctrl+C to stop any running process

## Troubleshooting

If you encounter issues:

1. **Conda not found after installation**: Restart your terminal or run `source ~/.zshrc`
2. **Permission denied**: Make sure the scripts are executable (`chmod +x script_name.sh`)
3. **Port already in use**: Use a different port with `--port` option
4. **Git not found**: Install git using `brew install git` or Xcode command line tools
5. **Network issues**: Check your internet connection and try again

## Contributing

Feel free to submit issues or pull requests to improve these scripts.
