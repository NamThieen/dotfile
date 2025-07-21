function install-rust --wraps="curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh" --description "alias install-rust=curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh $argv
        
end
