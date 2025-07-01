function flathub --wraps='flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo' --description 'alias flathub=flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo'
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo $argv
        
end
