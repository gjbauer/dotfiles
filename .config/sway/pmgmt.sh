#!/bin/sh

# Anti-cold boot measure:
# Ensure that after the screen locks,
# if it is not unlocked within 5 minutes
# shutdown.
#
# This is needed even with TPM as researchers
# have overwritten the MOR bit in UEFI firmware
# to bypass zeroization.
LOCK_COMMAND="swaylock"

timeout 5m $LOCK_COMMAND

if [ $? -eq 124 ]; then
	doas poweroff
fi
