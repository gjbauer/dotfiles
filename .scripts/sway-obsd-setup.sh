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

# Create XDG_RUNTIME_DIR
mkdir -p /run/user/$id

# Change ownership of 
chown $user:$user /run/user/$id

exit

return 0
