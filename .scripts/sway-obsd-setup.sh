#!/bin/sh

# Get user information before entering superuser mode
user=$(whoami)
id=$(id -u)

# Add user to seatd group
doas usermod -G _seatd $user

# Enable seatd
doas rcctl enable seatd
