#!/bin/sh

echo "Make sure to run using 'source sway-obsd-setup.sh'"

# Get user information before entering superuser mode
user=$(whoami)
id=$(id -u)

# Enter superuser
su

# Add user to seatd group
usermod -G _seatd $user

# Enable seatd
rcctl enable seatd

exit

return 0
