#!/bin/bash

set -e

# env
# Define the registry config path
CONFIG_PATH="/etc/containerd/certs.d/_default"
DEFAULT_HOSTS_FILE="${CONFIG_PATH}/hosts.toml"
#REGISTRY_MIRROR_URL="$REGISTRY_MIRROR_URL"
#FILE_STORAGE_URL="$FILE_STORAGE_URL"
#PRIVATE_FILE_STORAGE_URL="$PRIVATE_FILE_STORAGE_URL"

# Ensure the environment variables are set
if [ -z "$REGISTRY_MIRROR_URL" ] || [ -z "$FILE_STORAGE_URL" ] || [ -z "$PRIVATE_FILE_STORAGE_URL" ]; then
    echo "Error: Environment variables REGISTRY_MIRROR_URL, FILE_STORAGE_URL, and PRIVATE_FILE_STORAGE_URL must be set."
    exit 1
fi


# Ensure the directory exists
mkdir -p "$CONFIG_PATH"

# Backup the original containerd config
cp /etc/containerd/config.toml /etc/containerd/config.toml.bak

# Set config_path in config.toml
if grep -q 'config_path' /etc/containerd/config.toml; then
    # Update existing config_path
    sed -i 's|config_path = .*|config_path = "/etc/containerd/certs.d"|' /etc/containerd/config.toml
else
    # Add config_path under the registry section
    sed -i '/\[plugins."io.containerd.grpc.v1.cri".registry\]/a\  config_path = "/etc/containerd/certs.d"' /etc/containerd/config.toml
fi

# Create default hosts.toml
cat <<EOF > "$DEFAULT_HOSTS_FILE"
# Default hosts.toml for containerd
[host."https://$REGISTRY_MIRROR_URL"]
  capabilities = ["pull", "resolve"]
  skip_verify = true
EOF


# Append custom host entries to /etc/hosts if not already present
grep -q "$PRIVATE_FILE_STORAGE_URL" /etc/hosts || echo "$PRIVATE_FILE_STORAGE_URL" >> /etc/hosts
grep -q "$FILE_STORAGE_URL" /etc/hosts || echo "$FILE_STORAGE_URL" >> /etc/hosts


# Restart containerd to apply changes
systemctl restart containerd
