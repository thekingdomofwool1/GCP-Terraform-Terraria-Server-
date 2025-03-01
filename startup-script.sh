#!/bin/bash
# Startup script for Terraria server on Debian/Ubuntu

# Enable debugging and logging
set -e
set -x  # Print commands and their arguments as they are executed
exec > >(tee /var/log/terraria-startup.log) 2>&1  # Log all output to a file

echo "Starting Terraria server installation script at $(date)"

# Get Terraform variables from instance metadata
echo "Retrieving metadata values..."
TERRARIA_VERSION=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/terraria_version" 2>/dev/null || echo "1.4.4.9")
WORLD_NAME=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/world_name" 2>/dev/null || echo "terraform-world")
WORLD_SIZE=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/world_size" 2>/dev/null || echo "2")
MAX_PLAYERS=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/max_players" 2>/dev/null || echo "8")
SERVER_PASSWORD=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/server_password" 2>/dev/null || echo "")

echo "Using the following configuration:"
echo "Terraria Version: $TERRARIA_VERSION"
echo "World Name: $WORLD_NAME"
echo "World Size: $WORLD_SIZE"
echo "Max Players: $MAX_PLAYERS"
echo "Password Set: $(if [ -z "$SERVER_PASSWORD" ]; then echo "No"; else echo "Yes"; fi)"

# Update system and install Google OS Config Agent
echo "Updating system and installing Google OS Config Agent..."
sudo apt update
sudo apt -y install google-osconfig-agent
echo "Google OS Config Agent installed successfully"

# Install dependencies
echo "Installing dependencies..."
apt-get update || { echo "Failed to update package lists"; exit 1; }
apt-get install -y unzip wget tmux screen gnupg2 apt-transport-https dirmngr ca-certificates || { echo "Failed to install basic dependencies"; exit 1; }

# Install a specific version of Mono that's compatible with Terraria 1.4.4.9
echo "Installing Mono 6.12 from the official repository..."
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF || { echo "Failed to add Mono repository key"; exit 1; }

# Use the Debian 10 (Buster) repository for better compatibility
echo "deb https://download.mono-project.com/repo/debian stable-buster main" | tee /etc/apt/sources.list.d/mono-official-stable.list || { echo "Failed to add Mono repository"; exit 1; }
apt-get update || { echo "Failed to update package lists after adding Mono repository"; exit 1; }

# Install specific Mono packages needed for Terraria
apt-get install -y mono-runtime mono-devel mono-mcs || { echo "Failed to install Mono"; exit 1; }

# Verify Mono version
MONO_VERSION=$(mono --version | head -n 1)
echo "Installed Mono version: $MONO_VERSION"

# Create a symbolic link to ensure mono is in the PATH
ln -sf /usr/bin/mono /usr/local/bin/mono || { echo "Failed to create symbolic link for mono"; exit 1; }
echo "Dependencies installed successfully"

# Create Terraria directory
echo "Creating Terraria directories..."
TERRARIA_DIR="/opt/terraria"
mkdir -p $TERRARIA_DIR
mkdir -p $TERRARIA_DIR/worlds
echo "Terraria directories created at $TERRARIA_DIR"

# Download Terraria server
echo "Downloading Terraria server version 1.4.4.9 to match client version..."
cd $TERRARIA_DIR

# Use the latest version of Terraria server to match client version
DOWNLOAD_URL="https://terraria.org/api/download/pc-dedicated-server/terraria-server-1449.zip"

echo "Using official download URL for Terraria 1.4.4.9: $DOWNLOAD_URL"
wget -O terraria-server.zip "$DOWNLOAD_URL" || { 
  echo "Failed to download Terraria server"
  exit 1
}

echo "Extracting Terraria server files..."
unzip terraria-server.zip || { echo "Failed to extract Terraria server files"; exit 1; }
rm terraria-server.zip
echo "Terraria server files downloaded and extracted"

# Find the Linux directory in the extracted files
echo "Locating Linux server files..."
LINUX_DIR=$(find . -type d -name "*Linux*" | head -n 1)
if [ -z "$LINUX_DIR" ]; then
  echo "ERROR: Could not find Linux directory in Terraria server package"
  exit 1
fi
echo "Found Linux server files in $LINUX_DIR"

# Move files from Linux directory to main directory
echo "Setting up Terraria server files..."
mv $LINUX_DIR/* . || { echo "Failed to move server files"; exit 1; }
chmod +x TerrariaServer.exe || { echo "Failed to make TerrariaServer.exe executable"; exit 1; }

# Fix Mono compatibility issue by removing bundled System.dll
echo "Fixing Mono compatibility issue..."
if [ -f "$TERRARIA_DIR/System.dll" ]; then
  echo "Found bundled System.dll, renaming to System.dll.bak to avoid conflicts with system Mono"
  mv "$TERRARIA_DIR/System.dll" "$TERRARIA_DIR/System.dll.bak" || { echo "Failed to rename System.dll"; exit 1; }
fi

# Check for other potential conflicting DLLs
for dll in "$TERRARIA_DIR/mscorlib.dll" "$TERRARIA_DIR/Mono.Security.dll"; do
  if [ -f "$dll" ]; then
    echo "Found potentially conflicting DLL: $dll, renaming to avoid conflicts"
    mv "$dll" "$dll.bak" || { echo "Failed to rename $dll"; exit 1; }
  fi
done

echo "Terraria server files set up successfully"

# Create server config file
echo "Creating server configuration file..."
cat > $TERRARIA_DIR/serverconfig.txt << EOL
world=$TERRARIA_DIR/worlds/$WORLD_NAME.wld
autocreate=$WORLD_SIZE
worldname=$WORLD_NAME
difficulty=0
maxplayers=$MAX_PLAYERS
port=7777
password=$SERVER_PASSWORD
motd=Welcome to Terraria Server created with Terraform!
worldpath=$TERRARIA_DIR/worlds/
banlist=$TERRARIA_DIR/banlist.txt
secure=1
EOL
echo "Server configuration file created at $TERRARIA_DIR/serverconfig.txt"

# Configure screen to log output
echo "Configuring screen logging..."
cat > /root/.screenrc << EOL
# Enable logging
logfile $TERRARIA_DIR/screenlog.%n
log on
# Turn off the startup message
startup_message off
# Increase scrollback buffer
defscrollback 10000
EOL
echo "Screen logging configured"

# Create systemd service file
echo "Creating systemd service file..."
cat > /etc/systemd/system/terraria.service << EOL
[Unit]
Description=Terraria Server
After=network.target

[Service]
Type=forking
User=root
WorkingDirectory=$TERRARIA_DIR
# Start Terraria in a detached screen session with logging enabled
ExecStart=/bin/bash -c '/usr/bin/screen -L -dmS terraria mono TerrariaServer.exe -config $TERRARIA_DIR/serverconfig.txt'
# Only try to send exit command if the screen session exists
ExecStop=/bin/bash -c 'if screen -list | grep -q "terraria"; then screen -S terraria -X stuff "exit\n"; fi'
# Give the server time to shut down gracefully
TimeoutStopSec=30
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOL
echo "Systemd service file created at /etc/systemd/system/terraria.service"

# Enable and start the service
echo "Starting Terraria server service..."
systemctl daemon-reload || { echo "Failed to reload systemd daemon"; exit 1; }
systemctl enable terraria || { echo "Failed to enable terraria service"; exit 1; }
systemctl start terraria || { echo "Failed to start terraria service"; exit 1; }
echo "Terraria server service started successfully"

# Verify the service is running
echo "Verifying Terraria server service status..."
systemctl status terraria || echo "Warning: Service status check returned non-zero exit code"

# Create a simple script to check server status
echo "Creating server status script..."
cat > /usr/local/bin/terraria-status << EOL
#!/bin/bash
echo "Terraria Server Status:"
systemctl status terraria
echo ""
echo "To view server console:"
echo "screen -r terraria"
echo ""
echo "To detach from console: Press Ctrl+A then D"
EOL

chmod +x /usr/local/bin/terraria-status
echo "Server status script created at /usr/local/bin/terraria-status"

# Create a manual start script for debugging
echo "Creating manual start script..."
cat > $TERRARIA_DIR/manual-start.sh << EOL
#!/bin/bash
# Manual script to start Terraria server for testing/debugging

echo "This script will manually start the Terraria server for testing purposes."
echo "It will help diagnose any issues with the server startup."

# Define the Terraria directory
TERRARIA_DIR="$TERRARIA_DIR"

echo "Starting Terraria server manually..."
echo "Working directory: \$TERRARIA_DIR"
echo "Command: mono TerrariaServer.exe -config \$TERRARIA_DIR/serverconfig.txt"
echo ""
echo "The server will start in the foreground. Press Ctrl+C to stop."
echo "If this works but the systemd service doesn't, there's an issue with the service configuration."
echo ""
echo "Starting in 3 seconds..."
sleep 3

# Create a log file for manual testing
LOG_FILE="\$TERRARIA_DIR/manual-test-\$(date +%Y%m%d-%H%M%S).log"
echo "Output will be logged to: \$LOG_FILE"

# Start the server in the foreground with logging
cd \$TERRARIA_DIR && mono TerrariaServer.exe -config \$TERRARIA_DIR/serverconfig.txt 2>&1 | tee "\$LOG_FILE"

echo "Server stopped. Check the log file at \$LOG_FILE for any errors."
EOL

chmod +x $TERRARIA_DIR/manual-start.sh
echo "Manual start script created at $TERRARIA_DIR/manual-start.sh"

echo "==================================================="
echo "Terraria server installation complete at $(date)!"
echo "Server is running at port 7777"
echo "Run 'terraria-status' to check server status"
echo "==================================================="
