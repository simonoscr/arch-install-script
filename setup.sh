#!/bin/bash

####################
## Setup Question ##
####################

# Ask for GPU type and validate input
while true; do
    echo "What GPU do you have, AMD, NVIDIA, or do you want to SKIP? (Type 'AMD', 'NVIDIA', or 'SKIP')"
    read gpu_type
    gpu_type=${gpu_type^^} # Convert to uppercase

    # Check if the input is valid
    if [[ "$gpu_type" == "AMD" || "$gpu_type" == "NVIDIA" || "$gpu_type" == "SKIP" ]]; then
        break
    else
        echo "Invalid input. Please enter 'AMD', 'NVIDIA', or 'SKIP'."
    fi
done

# Convert the input to uppercase for consistency
gpu_type=${gpu_type^^}

###################
## System Update ##
###################

# Update system
sudo pacman -Syu

# Install necessary packages for building from AUR
sudo pacman -S --needed base-devel git

# Setup AUR Helper paru
sudo mkdir ~/git/
cd ~/git/
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd ~
paru --noconfirm
echo "Installation of paru completed."
################
## GPU Driver ##
################

# Install GPU-specific packages
if [ "$gpu_type" == "AMD" ]; then
    echo "Installing packages for AMD GPU..."
    paru -S --noconfirm mesa lib32-mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon libva-mesa-driver mesa-vdpau lib32-libva-mesa-driver lib32-mesa-vdpau
elif [ "$gpu_type" == "NVIDIA" ]; then
    echo "Installing packages for NVIDIA GPU..."
    # Add your NVIDIA-specific package installations here
    # paru -S nvidia-package-name
elif [ "$gpu_type" == "SKIP" ]; then
    echo "Skipping GPU-specific package installation."
else
    echo "Unknown GPU type. Continuing without GPU-specific packages."
fi
echo "Installation of GPU Driver completed."

##########################
## Install applications ##
##########################

package_list="packages/package-list.txt"
if [ ! -f "$package_list" ]; then
    echo "Package list file not found: $package_list"
    exit 1
fi
while IFS= read -r line; do
    pkg=$(echo "$line" | sed 's/- //')

    if paru -Si $pkg &> /dev/null; then
        echo "Installing $pkg..."
        paru -S --noconfirm $pkg
    else
        echo "Package not found or incorrect: $pkg, skipping..."
    fi
done < "$package_list"
echo "Installation of applications completed."

#######################
## COPY Config Files ##
#######################

## Dotfiles yadm
cd ~
yadm clone https://github.com/simonoscr/dotfiles.git
yadm submodule init
yadm submodule update

## DRI
dri_config_file_path="/conf/.drirc"
destination_path="$HOME/.drirc"
if [ ! -f "$dri_config_file_path" ]; then
    echo "DRI configuration file not found: $dri_config_file_path"
    exit 1
fi
echo "Copying DRI configuration file to $destination_path..."
sudo cp "$dri_config_file_path" "$destination_path"
echo "DRI configuration file copied successfully."

## Increase VM Map count
# Having the default vm.max_map_count size limit of 65530 maps can be too little for some games [1]. Therefore increase the size permanently by creating the sysctl config file:
gamecompatibility_file_path="/conf/80-gamecompatibility.conf"
destination_path="/etc/sysctl.d/80-gamecompatibility.conf"
if [ ! -f "$gamecompatibility_file_path" ]; then
    echo "gamecompatibility file not found: $gamecompatibility_file_path"
    exit 1
fi
echo "Copying gamecompatibility file to $destination_path..."
sudo cp "$gamecompatibility_file_path" "$destination_path"
echo "gamecompatibility file copied successfully."

## consistent reponse time
response_time_file_path="conf/consistent-response-time-for-gaming.conf"
destination_path="/etc/tmpfiles.d/consistent-response-time-for-gaming.conf"
if [ ! -f "$response_time_file_path" ]; then
    echo "response_time file not found: $response_time_file_path"
    exit 1
fi
echo "Copying response_time file to $destination_path..."
sudo cp "$response_time_file_path" "$destination_path"
echo "response_time file copied successfully."

## Set pipewire rate to 44100
pipewire_config_file_path="conf/10-pipewire-default.conf"
destination_path="/etc/pipewire/pipewire.conf.d/10-default.conf"
if [ ! -f "$pipewire_config_file_path" ]; then
    echo "pipewire_config file not found: $pipewire_config_file_path"
    exit 1
fi
echo "Copying pipewire_config file to $destination_path..."
sudo cp "$pipewire_config_file_path" "$destination_path"
echo "pipewire_config file copied successfully."

reboot
