#!/bin/sh

# Anti-cold boot measure:
# Ensure that after the screen locks,
# if it is not unlocked within 5 minutes
# shutdown.
#
# This is needed even with TPM as researchers
# have overwritten the MOR bit in UEFI firmware
# to bypass zeroization.
LOCK_COMMAND="swaylock \
	--screenshots \
	--clock \
	--indicator \
	--indicator-radius 100 \
	--indicator-thickness 7 \
	--effect-blur 7x5 \
	--effect-vignette 0.5:0.5 \
	--ring-color bb00cc \
	--key-hl-color 880033 \
	--line-color 00000000 \
	--inside-color 00000088 \
	--separator-color 00000000 \
	--grace 2 \
	--fade-in 0.2"

timeout 5m $LOCK_COMMAND

if [ $? -eq 124 ]; then
	doas poweroff
fi
