function sudin --wraps='sudo dnf install' --description 'alias sudnfin=sudo dnf -y install'
    sudo dnf install -y $argv

end
