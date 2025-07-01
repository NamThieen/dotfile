function sudse --wraps='sudo dnf search' --description 'alias sudnfse=sudo dnf search'
    sudo dnf search $argv

end
