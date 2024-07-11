#!/bin/bash

# Variables
USERNAME="yourusername"
SHAREDIR="/home/$USERNAME/shared"

# Update system and install Samba
sudo apt update
sudo apt install -y samba

# Create shared directory
mkdir -p $SHAREDIR

# Set permissions for the shared directory
chmod 777 $SHAREDIR

# Backup existing smb.conf
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak

# Configure Samba
sudo bash -c "cat >> /etc/samba/smb.conf" <<EOL

[shared]
   path = $SHAREDIR
   available = yes
   valid users = $USERNAME
   read only = no
   browsable = yes
   public = yes
   writable = yes
EOL

# Create Samba user
sudo smbpasswd -a $USERNAME

# Restart Samba services
sudo systemctl restart smbd
sudo systemctl restart nmbd

# Allow Samba through the firewall
sudo ufw allow samba

echo "Samba setup complete. You can access the shared folder at \\$(hostname -I | awk '{print $1}')\shared"
