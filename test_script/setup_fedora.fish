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

# --- Configuration for temporary files ---
set -l INITIAL_DIR (pwd)
set -l TEMP_DIR "$INITIAL_DIR/fedora_setup_temp"

echo "Creating temporary directory: $TEMP_DIR"
mkdir -p "$TEMP_DIR"
check_status

# --- Step 1: Remove GNOME Software autostart ---
echo "\n--- Step 1: Removing GNOME Software autostart entry ---"
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
echo "Adding Flathub remote..."
flatpak remote-add --if-not-exists flathub [https://flathub.org/repo/flathub.flatpakrepo](https://flathub.org/repo/flathub.flatpakrepo)
check_status
echo "Flathub remote added."

# --- Step 3: Add Terra repository ---
echo "--- Step 3: Adding Terra repository ---"
echo "Installing Terra release package..."
# Note: --nogpgcheck is used as per your command. Be aware of the security implications.
sudo dnf install --nogpgcheck --repofrompath 'terra,[https://repos.fyralabs.com/terra$releasever](https://repos.fyralabs.com/terra$releasever)' terra-release
check_status
echo "Terra repository added."

# --- Step 5: Update Flatpak appstream ---
echo "\n--- Step 5: Updating Flatpak appstream data ---"
flatpak update --appstream
check_status
echo "Flatpak appstream updated."

# --- Step 6: Theme GTK3 ---
echo "\n--- Step 6: Installing and setting GTK3 themes ---"
echo "Installing adw-gtk3 themes via Flatpak..."
flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark
check_status
echo "Setting GTK theme to 'adw-gtk3-dark' and color scheme to 'prefer-dark'..."
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
and gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
check_status
echo "GTK themes applied."

# --- Step 7: Theme GNOME Shell (Marble-shell-theme) ---
echo "\n--- Step 7: Installing GNOME Shell theme (Marble-shell-theme) ---"
echo "Cloning Marble-shell-theme repository..."
cd "$TEMP_DIR"
git clone [https://github.com/imarkoff/Marble-shell-theme.git](https://github.com/imarkoff/Marble-shell-theme.git)
check_status

cd Marble-shell-theme
check_status

echo "Installing Marble-shell-theme..."
# Ensure python3 is available
python3 install.py --blue --filled --mode dark -Pds --launchpad
check_status
echo "Marble-shell-theme installed. You might need to log out and back in, or restart GNOME Shell (Alt+F2, r, Enter) to see changes."

# Return to initial directory
cd "$INITIAL_DIR"
check_status

# --- Step 8: Create Flatpak Update Systemd Service and Timer ---
echo "\n--- Step 8: Setting up automatic Flatpak updates via systemd timer ---"
set -l FLATPAK_SERVICE_FILE "/etc/systemd/system/flatpak-update.service"
set -l FLATPAK_TIMER_FILE "/etc/systemd/system/flatpak-update.timer"

echo "Creating $FLATPAK_SERVICE_FILE..."

echo '[Unit]
Description=Update Flatpak apps automatically

[Service]
Type=oneshot
ExecStart=/usr/bin/flatpak update -y --noninteractive
EOF
check_status' | sudo tee "$FLATPAK_SERVICE_FILE" > /dev/null 

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
WantedBy=timers.target
EOF
check_status' | sudo tee "$FLATPAK_TIMER_FILE" > /dev/null

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload
check_status

echo "Enabling and starting flatpak-update.timer..."
sudo systemctl enable --now flatpak-update.timer
check_status

echo "Checking status of flatpak-update.timer:"
sudo systemctl status flatpak-update.timer
echo "Automatic Flatpak updates configured."

# --- Step 9: Disable NetworkManager-wait-online.service ---
echo "\n--- Step 9: Disabling NetworkManager-wait-online.service ---"
sudo systemctl disable NetworkManager-wait-online.service
check_status
echo "NetworkManager-wait-online.service disabled."

# --- Step 10: Cloudflared DNS-over-HTTPS Setup ---
echo "\n--- Step 10: Setting up Cloudflared DNS-over-HTTPS ---"
echo "Adding Cloudflared repository..."
curl -fsSL [https://pkg.cloudflare.com/cloudflared-ascii.repo](https://pkg.cloudflare.com/cloudflared-ascii.repo) | sudo tee /etc/yum.repos.d/cloudflared.repo > /dev/null
check_status

echo "Installing cloudflared..."
sudo dnf install -y cloudflared
check_status

set -l CLOUDFLARED_SERVICE_FILE "/etc/systemd/system/cloudflared.service"
echo "Creating $CLOUDFLARED_SERVICE_FILE..."
sudo tee "$CLOUDFLARED_SERVICE_FILE" > /dev/null <<'EOF'
[Unit]
Description=Cloudflared DNS-over-HTTPS proxy
After=network.target

[Service]
ExecStart=/usr/bin/cloudflared proxy-dns --upstream [https://1.1.1.1/dns-query](https://1.1.1.1/dns-query) --upstream [https://1.0.0.1/dns-query](https://1.0.0.1/dns-query)
Restart=on-failure
User=nobody
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF
check_status

echo "Reloading systemd daemon (re-exec and reload)..."
sudo systemctl daemon-reexec
check_status
sudo systemctl daemon-reload
check_status

echo "Enabling and starting cloudflared service..."
sudo systemctl enable --now cloudflared
check_status

echo "Configuring systemd-resolved to use 127.0.0.1 (cloudflared)..."
sudo mkdir -p /etc/systemd/resolved.conf.d
check_status

set -l RESOLVED_CONF_FILE "/etc/systemd/resolved.conf.d/dns-over-https.conf"
sudo tee "$RESOLVED_CONF_FILE" > /dev/null <<'EOF'
[Resolve]
DNS=127.0.0.1
FallbackDNS=1.1.1.1
DNSSEC=yes
Cache=yes
EOF
check_status

echo "Telling NetworkManager to use systemd-resolved..."
set -l NM_DNS_CONF_FILE "/etc/NetworkManager/conf.d/dns.conf"
sudo tee "$NM_DNS_CONF_FILE" > /dev/null <<'EOF'
[main]
dns=systemd-resolved
EOF
check_status

echo "Restarting cloudflared, systemd-resolved, and NetworkManager services..."
sudo systemctl restart cloudflared
check_status
sudo systemctl restart systemd-resolved
check_status
sudo systemctl restart NetworkManager
check_status

echo "Testing DNS resolution with dig..."
dig +short example.com
echo "Checking current DNS status with resolvectl..."
resolvectl status
echo "Cloudflared DNS-over-HTTPS setup complete."

# --- Step 11: Install additional software ---
echo "\n--- Step 11: Installing additional software ---"
echo "Installing Deja Dup (backup utility)..."
sudo dnf install -y deja-dup
check_status

echo "Installing Extension Manager (Flatpak)..."
flatpak install -y flathub com.mattjakeman.ExtensionManager
check_status


# --- Cleanup ---
echo "\n--- Cleanup: Removing temporary files ---"
cd "$INITIAL_DIR"
check_status
rm -rf "$TEMP_DIR"
if [ $status -ne 0 ]
    echo "Warning: Failed to remove temporary directory: $TEMP_DIR. You may need to remove it manually."
else
    echo "Successfully removed temporary directory: $TEMP_DIR"
end

echo "\nFedora system setup script finished!"
echo "Please log out and log back in (or reboot) for all changes to take full effect, especially for the shell and themes."

