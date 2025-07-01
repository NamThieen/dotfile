function open-grub --wraps='sudo nvim /etc/default/grub' --description 'alias open-grub=sudo nvim /etc/default/grub'
  sudo nvim /etc/default/grub $argv
        
end
