# Dotfiles - my Unix configuration

This branch is set to target OpenBSD, with branches for FreeBSD, macOS, Ubuntu ARM64 and Arch Linux.

That being said, in order to make this configuration usable, one must install in addition to sway & zsh; dmenu, konsole, swaylock, and finally a font package - noto-fonts. After setting the user shell to ZSH, run the ZSH setup script. And after installing the rest of the sway environment, run the sway setup script. All of the scripts can be found in the '.scripts' directory. Be sure to install the firmware for your graphical environment using `fw_update` and enable seatd!!
