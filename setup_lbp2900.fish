#!/usr/bin/fish

# Canon LBP2900 Printer Setup Script for Fedora
# Based on user-provided steps.

echo "Starting Canon LBP2900 printer setup script..."
echo "This script requires an active internet connection and sudo privileges."

# --- Configuration ---
# Store the initial directory to return to later
set -l INITIAL_DIR (pwd)
set -l SCRIPT_DIR (dirname (status --current-filename))
set -l DOWNLOAD_DIR "$SCRIPT_DIR/canon_lbp2900_setup_files"

echo "Creating download directory: $DOWNLOAD_DIR"
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR" || exit 1

# --- Step 1: Get Dependencies ---
echo "\n--- Step 1: Downloading i686 dependencies ---"
# Note: These URLs are for Fedora 42. Adjust if on a different Fedora version.
set -l LIBTIFF_URL "https://rpmfind.net/linux/fedora/linux/releases/42/Everything/x86_64/os/Packages/l/libtiff-4.7.0-3.fc42.i686.rpm"
set -l POPT_URL "https://rpmfind.net/linux/fedora/linux/releases/42/Everything/x86_64/os/Packages/p/popt-1.19-8.fc42.i686.rpm"

echo "Downloading libtiff..."
wget -c "$LIBTIFF_URL"
if [ $status -ne 0 ]
    echo "Error downloading libtiff. Exiting."
    cd "$INITIAL_DIR" # Return to initial directory before exiting
    exit 1
end

echo "Downloading popt..."
wget -c "$POPT_URL"
if [ $status -ne 0 ]
    echo "Error downloading popt. Exiting."
    cd "$INITIAL_DIR" # Return to initial directory before exiting
    exit 1
end

echo "Installing i686 dependencies..."
# Using dnf to install local RPMs
sudo dnf install -y "$DOWNLOAD_DIR/libtiff-4.7.0-3.fc42.i686.rpm" "$DOWNLOAD_DIR/popt-1.19-8.fc42.i686.rpm"
if [ $status -ne 0 ]
    echo "Warning: Error installing i686 dependencies. Please check the output. Attempting to proceed."
    # We don't exit here, as dnf might have partially installed or they might be present.
end

# --- Step 2: Download Official Canon Driver ---
echo "\n--- Step 2: Downloading official Canon driver ---"
set -l CANON_DRIVER_URL "https://pdisp01.c-wss.com/gdl/WWUFORedirectTarget.do?id=MDEwMDAwNDU5NjA1&cmp=ABX&lang=EN"
set -l CANON_DRIVER_FILENAME "linux-capt-drv-v271-uken.tar.gz" # Expected filename after download

echo "Downloading Canon driver: $CANON_DRIVER_FILENAME"
# Use wget with --content-disposition to save with the correct filename if possible,
# otherwise specify -O to ensure correct name.
wget -c --content-disposition "$CANON_DRIVER_URL" -O "$CANON_DRIVER_FILENAME"
if [ $status -ne 0 ]
    echo "Error downloading Canon driver. Exiting."
    cd "$INITIAL_DIR" # Return to initial directory before exiting
    exit 1
end

# --- Step 3: Unzip and Install Canon Driver RPMs ---
echo "\n--- Step 3: Unzipping and installing Canon driver RPMs ---"
echo "Extracting $CANON_DRIVER_FILENAME"
tar -xzf "$CANON_DRIVER_FILENAME"
if [ $status -ne 0 ]
    echo "Error extracting Canon driver. Exiting."
    cd "$INITIAL_DIR" # Return to initial directory before exiting
    exit 1
end

# Assuming the extracted directory name
set -l EXTRACTED_DIR "linux-capt-drv-v271-uken"
set -l DRIVER_RPM_PATH "$DOWNLOAD_DIR/$EXTRACTED_DIR/64-bit_Driver/RPM"

if not test -d "$DRIVER_RPM_PATH"
    echo "Error: Expected directory $DRIVER_RPM_PATH not found after extraction. Exiting."
    cd "$INITIAL_DIR" # Return to initial directory before exiting
    exit 1
end

echo "Installing Canon driver RPMs from $DRIVER_RPM_PATH..."
sudo dnf install -y "$DRIVER_RPM_PATH/cndrvcups-capt-2.71-1.x86_64.rpm" "$DRIVER_RPM_PATH/cndrvcups-common-3.21-1.x86_64.rpm"
if [ $status -ne 0 ]
    echo "Error installing Canon driver RPMs. Please check the output."
    cd "$INITIAL_DIR" # Return to initial directory before exiting
    exit 1
end

# --- Step 4: Restart CUPS Service ---
echo "\n--- Step 4: Restarting CUPS service ---"
sudo systemctl restart cups.service
if [ $status -ne 0 ]
    echo "Error restarting CUPS service. Please check the output."
    # Don't exit, try to continue as it might still work
fi

# --- Step 5: Add Printer with lpadmin ---
echo "\n--- Step 5: Adding printer with lpadmin ---"
sudo /usr/sbin/lpadmin -p LBP2900 -m CNCUPSLBP2900CAPTK.ppd -v ccp://localhost:59787 -E
if [ $status -ne 0 ]
    echo "Error adding printer with lpadmin. Please check the output."
    cd "$INITIAL_DIR" # Return to initial directory before exiting
    exit 1
end

# --- Step 6: Configure CCPD Admin ---
echo "\n--- Step 6: Configuring CCPD admin ---"
sudo /usr/sbin/ccpdadmin -p LBP2900 -o /dev/usb/lp0
if [ $status -ne 0 ]
    echo "Error configuring ccpdadmin. Please check the output."
    echo "Ensure your printer is connected and detected at /dev/usb/lp0 or adjust the path."
    cd "$INITIAL_DIR" # Return to initial directory before exiting
    exit 1
end

# --- Step 7: Create CCPD Systemd Service ---
echo "\n--- Step 7: Creating ccpd.service systemd file ---"
set -l SERVICE_FILE "/etc/systemd/system/ccpd.service"

echo '[Unit]
Description=CCPD Printing Daemon
Requires=cups.service
After=cups.service

[Service]
Type=forking
ExecStart=/usr/sbin/ccpd
TimeoutSec=30

[Install]
WantedBy=default.target' | sudo tee "$SERVICE_FILE" > /dev/null

if [ $status -ne 0 ]
    echo "Error creating ccpd.service file. Exiting."
    cd "$INITIAL_DIR" # Return to initial directory before exiting
    exit 1
end
echo "Created $SERVICE_FILE"

# --- Final Steps: Reload, Enable, Start, Check ---
echo "\n--- Final Steps: Reloading daemon, enabling and starting CCPD service ---"
sudo systemctl daemon-reload
if [ $status -ne 0 ]
    echo "Error running daemon-reload. Exiting."
    cd "$INITIAL_DIR" # Return to initial directory before exiting
    exit 1
end

sudo systemctl enable ccpd.service
if [ $status -ne 0 ]
    echo "Error enabling ccpd.service. Exiting."
    cd "$INITIAL_DIR" # Return to initial directory before exiting
    exit 1
end

sudo systemctl start ccpd.service
if [ $status -ne 0 ]
    echo "Error starting ccpd.service. Please check for issues above."
    # Don't exit immediately, let the status check run
fi

echo "\n--- Checking CCPD service status ---"
sudo systemctl status ccpd.service

# --- Cleanup ---
echo "\n--- Cleanup: Removing temporary download files ---"
# Return to the initial directory before attempting to remove the download directory
cd "$INITIAL_DIR" || begin
    echo "Could not return to initial directory: $INITIAL_DIR. Skipping cleanup."
    exit 1 # Exit if we can't get back, cleanup won't work reliably
end

# Remove the entire download directory
rm -rf "$DOWNLOAD_DIR"
if [ $status -ne 0 ]
    echo "Warning: Failed to remove temporary download directory: $DOWNLOAD_DIR. You may need to remove it manually."
else
    echo "Successfully removed temporary download directory: $DOWNLOAD_DIR"
end

echo "\nPrinter setup script finished!"
echo "You might need to restart your computer for all changes to take full effect, though the printer should be ready now."
echo "You can try printing a test page from your system settings."
