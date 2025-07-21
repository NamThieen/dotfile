#!/usr/bin/fish


echo "Starting Fedora system setup script..."
echo "This script requires an active internet connection and sudo privileges."

# --- Helper function for error checking ---
function check_status
    if [ $status -ne 0 ]
        echo "Error: Last command failed. Exiting."
        exit 1
    end
end

# --- Step 1: Remove GNOME Software autostart ---
echo "--- Step 1: Removing GNOME Software autostart entry ---"
if sudo test -f /etc/xdg/autostart/org.gnome.Software.desktop
    sudo rm /etc/xdg/autostart/org.gnome.Software.desktop
    check_status
    echo "Removed /etc/xdg/autostart/org.gnome.Software.desktop"
else
    echo "GNOME Software autostart file not found or already removed. Skipping."
end

# --- Step 2: Flatpak Configuration ---
echo "--- Step 2: Configuring Flatpak remotes ---"
echo "Removing default Fedora Flatpak remote (if it exists)..."
flatpak remote-delete fedora 2>/dev/null || true # Suppress error if not found
echo "Adding Flathub remote..."./
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
check_status
echo "Flathub remote added."

# --- Step 3: Add Terra repository ---
echo "--- Step 3: Adding Terra repository ---"
echo "Installing Terra release package..."
sudo dnf install -y --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release >/dev/null || true
check_status
echo "Terra repository added."

# --- Step 4: Update Flatpak appstream ---
echo "--- Step 4: Updating Flatpak appstream data ---"
flatpak update --appstream
check_status
echo "Flatpak appstream updated."

# --- Step 5: Theme GTK3 ---
echo "--- Step 5: Installing and setting GTK3 themes ---"
echo "Installing adw-gtk3 themes via Flatpak..."
flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark
check_status
echo "Setting GTK theme to 'adw-gtk3-dark' and color scheme to 'prefer-dark'..."
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
and gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
check_status
echo "GTK themes applied."

# --- Step 6: Create Flatpak Update Systemd Service and Timer ---
echo "--- Step 6: Setting up automatic Flatpak updates via systemd timer ---"
set -l FLATPAK_SERVICE_FILE "/etc/systemd/system/flatpak-update.service"
set -l FLATPAK_TIMER_FILE "/etc/systemd/system/flatpak-update.timer"

echo "Creating $FLATPAK_SERVICE_FILE..."

echo '[Unit]
Description=Update Flatpak apps automatically

[Service]
Type=oneshot
ExecStart=/usr/bin/flatpak update -y --noninteractive' | sudo tee "$FLATPAK_SERVICE_FILE" > /dev/null 
check_status

echo "Creating $FLATPAK_TIMER_FILE..."

echo '[Unit]
Description=Run Flatpak update every 24 hours
Wants=network-online.target
Requires=network-online.target
After=network-online.target 

[Timer]
OnBootSec=120
OnUnitActiveSec=24h

[Install]
WantedBy=timers.target' | sudo tee "$FLATPAK_TIMER_FILE" > /dev/null
check_status 

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload
check_status

echo "Enabling and starting flatpak-update.timer..."
sudo systemctl enable --now flatpak-update.timer
check_status

echo "Checking status of flatpak-update.timer:"
sudo systemctl status flatpak-update.timer
echo "Automatic Flatpak updates configured."

# --- Step 7: Disable NetworkManager-wait-online.service ---
echo "--- Step 7: Disabling NetworkManager-wait-online.service ---"
sudo systemctl disable NetworkManager-wait-online.service
check_status
echo "NetworkManager-wait-online.service disabled."

# --- Step 8: Install additional software ---
echo "--- Step 8: Installing additional software ---"
echo "Installing Deja Dup (backup utility)..."
sudo dnf install -y deja-dup
check_status

echo "Installing Extension Manager (Flatpak)..."
flatpak install -y flathub com.mattjakeman.ExtensionManager
check_status


