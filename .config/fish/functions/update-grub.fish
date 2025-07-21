function update-grub --wraps='sudo grub2-mkconfig -o /etc/grub2.cfg' --description 'alias update-grub=sudo grub2-mkconfig -o /etc/grub2.cfg'
    sudo grub2-mkconfig -o /etc/grub2.cfg $argv

end
