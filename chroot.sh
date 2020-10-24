#!/bin/bash

echo 'скрипт второй настройка системы в chroot '
timedatectl set-ntp true
pacman -Syyu --noconfirm
echo ""
read -p "Введите имя компьютера: " hostname
echo ""
echo " Используйте в имени только буквы латинского алфавита "
echo ""
read -p "Введите имя пользователя: " username

echo $hostname > /etc/hostname
echo ""
echo " Очистим папку конфигов, кеш, и скрытые каталоги в /home/$username от старой системы ? "
while
    read -n1 -p  "
    1 - да
    0 - нет: " i_rm      # sends right after the keypress
    echo ''
    [[ "$i_rm" =~ [^10] ]]
do
    :
done
if [[ $i_rm == 0 ]]; then
clear
echo " очистка пропущена "
elif [[ $i_rm == 1 ]]; then
rm -rf /home/$username/.*
clear
echo " очистка завершена "
fi
echo " Настройка localtime "
echo ""
ln -sf /usr/share/zoneinfo/Asia/Novokuznetsk /etc/localtime
echo " Часовой пояс установлен "

#####################################
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo 'LANG="ru_RU.UTF-8"' > /etc/locale.conf
echo "KEYMAP=ru" >> /etc/vconsole.conf
echo "FONT=cyr-sun16" >> /etc/vconsole.conf
echo ""
echo " Укажите пароль для ROOT "
passwd

echo ""
useradd -m -g users -G wheel -s /bin/bash $username
echo ""
echo 'Добавляем пароль для пользователя '$username' '
echo ""
passwd $username
echo ""

pacman -Syy
clear
lsblk -f
###########################################################################
echo "Какой загрузчик установить UEFI(systemd или GRUB) или BIOS (GRUB)"
while
    read -n1 -p  "
    1 - UEFI(systemd-boot )

    2 - BIOS(GRUB)

    3 - UEFI-GRUB: " t_bootloader # sends right after the keypress

    echo ''
    [[ "$t_bootloader" =~ [^123] ]]
do
    :
done
if [[ $t_bootloader == 1 ]]; then
bootctl install
clear
echo ' default arch ' > /boot/loader/loader.conf
echo ' timeout 10 ' >> /boot/loader/loader.conf
echo ' editor 0' >> /boot/loader/loader.conf
echo 'title   Arch Linux' > /boot/loader/entries/arch.conf
echo "linux  /vmlinuz-linux" >> /boot/loader/entries/arch.conf
echo ""
echo " Добавим ucode cpu? "
while
    read -n1 -p  "
    1 - amd

    2 - intel

    0 - ucode не добавляем : " i_cpu   # sends right after the keypress
    echo ''
    [[ "$i_cpu" =~ [^120] ]]
do
    :
done
if [[ $i_cpu == 0 ]]; then
clear
echo " Добавление ucode пропущено "
elif [[ $i_cpu  == 1 ]]; then
clear
pacman -S amd-ucode --noconfirm
echo  'initrd /amd-ucode.img ' >> /boot/loader/entries/arch.conf
elif [[ $i_cpu  == 2 ]]; then
clear
pacman -S intel-ucode  --noconfirm
echo ' initrd /intel-ucode.img ' >> /boot/loader/entries/arch.conf
fi
echo "initrd  /initramfs-linux.img" >> /boot/loader/entries/arch.conf
clear
lsblk -f
echo ""
echo " Укажите тот радел который будет после перезагрузки, то есть например "

echo " при установке с флешки ваш hdd может быть sdb, а после перезагрузки sda "

echo " выше видно что sdbX например примонтирован в /mnt, а после перезагрузки systemd будет искать корень на sdaX "

echo " если указать не правильный раздел система не загрузится "

echo " если у вас один hdd/ssd тогда это будет sda 99%"
echo ""
read -p "Укажите ROOT  раздел для загрузчика(пример  sda6,sdb3 ): " root
echo options root=/dev/$root rw >> /boot/loader/entries/arch.conf
#
cd /home/$username
git clone https://aur.archlinux.org/systemd-boot-pacman-hook.git
chown -R $username:users /home/$username/systemd-boot-pacman-hook
chown -R $username:users /home/$username/systemd-boot-pacman-hook/PKGBUILD
cd /home/$username/systemd-boot-pacman-hook
sudo -u $username makepkg -si --noconfirm
rm -Rf /home/$username/systemd-boot-pacman-hook
cd /home/$username
#
clear
elif [[ $t_bootloader == 2 ]]; then
clear
echo " Если на компьютере/сервере будет только один ArchLinux
и вам не нужна мультибут  >>> тогда 2
если же установка рядом в Windows или другой OS тогда 1 "
echo ""
echo " Нужен мультибут (установка рядом с другой OS)? "
while
    read -n1 -p  "
    1 - да

    2 - нет: " i_grub      # sends right after the keypress
    echo ''
    [[ "$i_grub" =~ [^12] ]]
do
    :
done
if [[ $i_grub == 2 ]]; then
pacman -S grub   --noconfirm
lsblk -f
read -p "Укажите диск куда установить GRUB (sda/sdb): " x_boot
grub-install /dev/$x_boot
grub-mkconfig -o /boot/grub/grub.cfg
echo " установка завершена "
elif [[ $i_grub == 1 ]]; then
pacman -S grub ntfs-3g os-prober  --noconfirm
lsblk -f
read -p "Укажите диск куда установить GRUB (sda/sdb): " x_boot
grub-install /dev/$x_boot
grub-mkconfig -o /boot/grub/grub.cfg
echo " установка завершена "
fi
elif [[ $t_bootloader == 3 ]]; then
pacman -S grub ntfs-3g os-prober --noconfirm
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
fi
mkinitcpio -p linux
##########
echo ""
echo " Настроим Sudo? "
while
    read -n1 -p  "
    1 - с паролем

    2 - без пароля

    0 - Sudo не добавляем : " i_sudo   # sends right after the keypress
    echo ''
    [[ "$i_sudo" =~ [^120] ]]
do
    :
done
if [[ $i_sudo  == 0 ]]; then
clear
echo " Добавление sudo пропущено"
elif [[ $i_sudo  == 1 ]]; then
echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers
clear
echo " Sudo с запросом пароля установлено "
elif [[ $i_sudo  == 2 ]]; then
echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
clear
echo " Sudo nopassword добавлено  "
fi
##########
echo ""
echo ""
echo " Добавление Multilib репозитория"
echo '[multilib]' >> /etc/pacman.conf
echo 'Include = /etc/pacman.d/mirrorlist' >> /etc/pacman.conf
echo " Multilib репозиторий добавлен"
#echo " Настроим multilib? "
#while
#    read -n1 -p  "
#    1 - да
#
#    0 - нет : " i_multilib   # sends right after the keypress
#    echo ''
#    [[ "$i_multilib" =~ [^10] ]]
#do
#    :
#done
#if [[ $i_multilib  == 0 ]]; then
#clear
#echo " Добавление мультилиб репозитория  пропущено"
#elif [[ $i_multilib  == 1 ]]; then
#echo '[multilib]' >> /etc/pacman.conf
#echo 'Include = /etc/pacman.d/mirrorlist' >> /etc/pacman.conf
#clear
#echo " Multilib репозиторий добавлен"
#fi
######
pacman -Sy xorg-server xorg-drivers --noconfirm
clear
echo " Установка KDE и набора программ "


# Последний вариант

pacman -Sy plasma konsole --noconfirm

pacman -S alsa-utils ark chromium --noconfirm

pacman -S dnsmasq dolphin-plugins filelight fzf git --noconfirm

pacman -S gwenview gzip haveged kfind lib32-alsa-plugins --noconfirm

pacman -S lib32-freetype2 --noconfirm

pacman -S nano-syntax-highlighting neofetch --noconfirm

pacman -S partitionmanager pkgfile --noconfirm

pacman -S pulseaudio-alsa gtk-engine-murrine --noconfirm

pacman -S sddm-kcm telegram-desktop terminus-font terminus-font-otb --noconfirm

pacman -S ttf-dejavu ttf-opensans unrar qbittorrent zsh --noconfirm


pacman -Rns bluedevil discover plasma-thunderbolt bolt --noconfirm


echo " "

grub-mkfont -s 16 -o /boot/grub/ter-u16b.pf2 /usr/share/fonts/misc/ter-u16b.otb
grub-mkconfig -o /boot/grub/grub.cfg
clear
pacman -S xorg-xinit --noconfirm
cp /etc/X11/xinit/xinitrc /home/$username/.xinitrc
chown $username:users /home/$username/.xinitrc
chmod +x /home/$username/.xinitrc
echo "exec startplasma-x11 " >> /home/$username/.xinitrc
echo ' [[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx ' >> /etc/profile
echo ""
pacman -R konqueror --noconfirm
clear
echo "Plasma KDE успешно установлена"
echo "Установка sddm "
pacman -S sddm sddm-kcm --noconfirm
systemctl enable sddm.service -f
echo "[General]" >> /etc/sddm.conf
echo "..." >> /etc/sddm.conf
echo "Numlock=on" >> /etc/sddm.conf
clear
echo " установка sddm  завершена "
echo "#####################################################################"
echo ""
echo " Нужен NetworkManager ? "
while
    read -n1 -p  "
    1 - да

    0 - нет : " i_network   # sends right after the keypress
    echo ''
    [[ "$i_network" =~ [^10] ]]
do
    :
done
if [[ $i_network  == 1 ]]; then
pacman -Sy networkmanager networkmanager-openvpn network-manager-applet --noconfirm
systemctl enable NetworkManager.service
elif [[ $i_network  == 0 ]]; then
echo " Установка NetworkManager пропущена "
echo ""
echo " Добавим dhcpcd в автозагрузку( для проводного интернета, который  получает настройки от роутера ) ? "
echo ""
echo "при необходимости это можно будет сделать уже в установленной системе "
while
    read -n1 -p  "
    1 - включить dhcpcd

    0 - не включать dhcpcd " x_dhcpcd
    echo ''
    [[ "$x_dhcpcd" =~ [^10] ]]
do
    :
done
if [[ $x_dhcpcd == 0 ]]; then
  echo ' dhcpcd не включен в автозагрузку, при необходиости это можно будет сделать уже в установленной системе '
elif [[ $x_dhcpcd == 1 ]]; then
systemctl enable dhcpcd.service
clear
echo "Dhcpcd успешно добавлен в автозагрузку"
fi
fi
clear
##############################################

echo ""

echo "  Установка  программ закончена"

echo ""
# clear
# pacman -S zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions grml-zsh-config --noconfirm
# echo 'source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh' >> /etc/zsh/zshrc
# echo 'source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> /etc/zsh/zshrc
# echo 'prompt adam2' >> /etc/zsh/zshrc
# clear

chsh -s /bin/fish
chsh -s /bin/fish $username
clear
# echo " при первом запуске консоли(терминала) нажмите "0" "
pacman -Sy --noconfirm

clear



# echo ""
# echo "##################################################################################"
# echo "###################   <<<< Установка программ из AUR >>>    ######################"
# echo "##################################################################################"


cd /home/$username
git clone https://aur.archlinux.org/yay.git
chown -R $username:users /home/$username/yay
chown -R $username:users /home/$username/yay/PKGBUILD
cd /home/$username/yay
sudo -u $username  makepkg -si --noconfirm
rm -Rf /home/$username/yay
clear

echo ""

#echo "##################################################################################"
#echo "###################№   <<<< Копирование настроек >>>    ######################№№№№"
#echo "##################################################################################"
#
#echo " Копируем настройки из /home/$username/system?"
#while
#    read -n1 -p  "1 - да, 0 - нет: " vm_cpset # sends right after the keypress
#    echo ''
#    [[ "$vm_cpset" =~ [^10] ]]
#do
#    :
#done
#if [[ $vm_cpset == 0 ]]; then
#  echo 'этап пропущен'
#elif [[ $vm_cpset == 1 ]]; then
#
#rm -r /etc /root
#rm -r /usr/share/icons
#
#cd /home/$username/system/
#cp -r etc root /
#cp -r icons /usr/share/
#cp -r Qogir /usr/share/sddm/themes/
#
#fi
clear
pacman -Syyu
grub-mkconfig -o /boot/grub/grub.cfg

clear


echo "
Данный этап может исключить возможные ошибки при первом запуске системы
Фаил откроется через редактор  !nano!"
echo ""
echo " Просмотрим//отредактируем /etc/fstab ?"
while
    read -n1 -p  "1 - да, 0 - нет: " vm_fstab # sends right after the keypress
    echo ''
    [[ "$vm_fstab" =~ [^10] ]]
do
    :
done
if [[ $vm_fstab == 0 ]]; then
  echo 'этап пропущен'
elif [[ $vm_fstab == 1 ]]; then
nano /etc/fstab
fi
clear
echo "################################################################"
echo ""
echo "Создаем папки музыка, видео и т.д. в директории пользователя?"
while
    read -n1 -p  "1 - да, 0 - нет: " vm_text # sends right after the keypress
    echo ''
    [[ "$vm_text" =~ [^10] ]]
do
    :
done
if [[ $vm_text == 0 ]]; then
  echo 'этап пропущен'
 exit
elif [[ $vm_text == 1 ]]; then
  mkdir /home/$username/{Downloads,Music,Pictures,Videos,Documents,time}
  chown -R $username:users  /home/$username/{Downloads,Music,Pictures,Videos,Documents,time}
exit
fi
clear
echo " Установка завершена для выхода введите >> exit << "
exit
exit
