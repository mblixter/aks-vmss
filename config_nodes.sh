#!/bin/bash

set -e

# env
# Define the registry config path
CONFIG_PATH="/etc/containerd/certs.d/_default"
DEFAULT_HOSTS_FILE="${CONFIG_PATH}/hosts.toml"
#REGISTRY_MIRROR_URL="$REGISTRY_MIRROR_URL"
#FILE_STORAGE_URL="$FILE_STORAGE_URL"
#PRIVATE_FILE_STORAGE_URL="$PRIVATE_FILE_STORAGE_URL"

# Loop through arguments
for arg in "$@"; do
  case "$arg" in
    REGISTRY_MIRROR_URL=*) REGISTRY_MIRROR_URL="${arg#*=}" ;;
    FILE_STORAGE_URL=*) FILE_STORAGE_URL="${arg#*=}" ;;
    PRIVATE_FILE_STORAGE_URL=*) PRIVATE_FILE_STORAGE_URL="${arg#*=}" ;;
    PRIVATE_FILE_STORAGE_URL=*) PRIVATE_FILE_STORAGE_URL="${arg#*=}" ;;
  esac
done



# Ensure the variables are set
# env
if [ -z "$REGISTRY_MIRROR_URL" ] || [ -z "$FILE_STORAGE_URL" ] || [ -z "$PRIVATE_FILE_STORAGE_URL" ]; then
    echo "Error: Environment variables REGISTRY_MIRROR_URL, FILE_STORAGE_URL, and PRIVATE_FILE_STORAGE_URL must be set."
    exit 1
fi

echo "REGISTRY_MIRROR_URL: $REGISTRY_MIRROR_URL"
echo "FILE_STORAGE_URL: $FILE_STORAGE_URL"
echo "PRIVATE_FILE_STORAGE_URL: $PRIVATE_FILE_STORAGE_URL"

# exit 0
# Ensure the directory exists
mkdir -p "$CONFIG_PATH"

# Backup the original containerd config
containerdConfig=/etc/containerd/config.toml
if [ -f "$containerdConfig" ]; then
  cp "$containerdConfig" "${containerdConfig}.bak"
  echo "$containerdConfig copied successfully!"
else
  echo "$containerdConfig does not exist."
fi

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
[host."$REGISTRY_MIRROR_URL"]
  capabilities = ["pull", "resolve"]
  skip_verify = true
EOF

# Restart containerd to apply changes
systemctl restart containerd

# Not Needed once IT fixes the issue with the private endpoint
# Append custom host entries to /etc/hosts if not already present
grep -q "$PRIVATE_FILE_STORAGE_URL" /etc/hosts || echo "$PRIVATE_FILE_STORAGE_URL" >> /etc/hosts
grep -q "$FILE_STORAGE_URL" /etc/hosts || echo "$FILE_STORAGE_URL" >> /etc/hosts
