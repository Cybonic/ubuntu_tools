#!/usr/bin/env bash

# Check if arguments were provided
if [[ $# -lt 1 ]]; then
  echo "Usage: sudo $0 <username> [<password>] [--sudo]"
  exit 1
fi

# Variables
LOCAL_SCRIPT="/usr/local/bin/create_user.sh"
SERVERS=("sol" "terra" "marte")
REMOTE_USER="admin"

# Create local user
echo "Creating user locally on the main server (lua)..."
sudo "$LOCAL_SCRIPT" "$@"
if [[ $? -ne 0 ]]; then
  echo "Error creating user locally."
  exit 1
fi

# Ask for remote user
read -s -p "Remote user password for $REMOTE_USER: " REMOTE_PASS
echo

# Create user remotely
for host in "${SERVERS[@]}"; do
  echo "[$host] Copying script..."

  if ! scp "$LOCAL_SCRIPT" "$REMOTE_USER@$host:/tmp/create_user.sh"; then
    echo "[$host] Failed to copy script with scp."
    continue
  fi

  echo "[$host] Executing remote user creation..."
  ssh "$REMOTE_USER@$host" "echo '$REMOTE_PASS' | sudo -S bash /tmp/create_user.sh $*" &>/dev/null

  if [[ $? -ne 0 ]]; then
    echo "[$host] Failed to create user remotely."
  else
    echo "[$host] User created successfully."
  fi
done
