sudo dnf remove libreoffice
curl -fsSL https://christitus.com/linux | sh
sudo dnf install mako waybar gnome-tweaks fd swaybg
flatpak install flathub com.mattjakeman.ExtensionManager
sudo dnf install neovim
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
. "$HOME/.cargo/env"
sudo dnf copr enable yalter/niri 
sudo dnf install niri
sudo dnf remove alacritty
sudo dd if=/dev/zero of=/swapfile bs=1024 count=1048576
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo nano /etc/fstab 
swapon --show
sudo dnf install git
git clone https://github.com/yeyushengfan258/Reversal-gtk-theme.git
cd Reversal-gtk-theme/
./install.sh -s compact -l
sudo flatpak override --filesystem=$HOME/.themes
sudo flatpak override --filesystem=$HOME/.icons
sudo flatpak override --env=GTK_THEME=Reversal-Dark 
sudo flatpak override --env=ICON_THEME=Fluent-grey
sudo flatpak override --env=GTK_THEME=Reversal-Dark-Compact 
sudo flatpak override --env=ICON_THEME=Fluent-grey
nvim
sudo dnf install fishs

sudo dnf install fish
chsh /bin/fish
chsh -l
chsh /usr/bin/fish
chsh /usr/bin/fish nam
chsh -s /usr/bin/fish 
