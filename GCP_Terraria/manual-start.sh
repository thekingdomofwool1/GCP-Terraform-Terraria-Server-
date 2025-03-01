#!/bin/bash
# Manual script to start Terraria server for testing/debugging

echo "This script will manually start the Terraria server for testing purposes."
echo "It will help diagnose any issues with the server startup."

# Define the Terraria directory
TERRARIA_DIR="/opt/terraria"

echo "Starting Terraria server manually..."
echo "Working directory: $TERRARIA_DIR"
echo "Command: mono TerrariaServer.exe -config $TERRARIA_DIR/serverconfig.txt"
echo ""
echo "The server will start in the foreground. Press Ctrl+C to stop."
echo "If this works but the systemd service doesn't, there's an issue with the service configuration."
echo ""
echo "Starting in 3 seconds..."
sleep 3

# Create a log file for manual testing
LOG_FILE="$TERRARIA_DIR/manual-test-$(date +%Y%m%d-%H%M%S).log"
echo "Output will be logged to: $LOG_FILE"

# Start the server in the foreground with logging
cd $TERRARIA_DIR && mono TerrariaServer.exe -config $TERRARIA_DIR/serverconfig.txt 2>&1 | tee "$LOG_FILE"

echo "Server stopped. Check the log file at $LOG_FILE for any errors."
