#!/bin/bash

sudo su -

# User creation
user_name="ansible-user"
user_home="/home/$user_name"
user_ssh_dir="$user_home/.ssh"

# Check if the user already exists
if id "$username" &>/dev/null; then
  echo "User $username already exists."
  exit 1
fi

# Create the user
sudo adduser --disabled-password --gecos "" "$user_name"

# Inform user creation success
echo "User $user_name has been created successfully."

# Add user to sudoer group
echo "ansible-user ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ansible-user

# Switch to user from root
su - ansible-user

# Install AWS CLI
sudo apt-get update -y
sudo apt-get install -y awscli
# sudo apt install python3-pip

# Install ansible
sudo apt-add-repository ppa:ansible/ansible -y
sudo apt update -y
sudo apt install ansible -y

# Create .ssh directory if not exists
mkdir -p $user_ssh_dir
chmod 700 $user_ssh_dir

# Generate SSH key pair if not exists
if [ ! -f "$user_ssh_dir/id_rsa" ]; then
  ssh-keygen -t rsa -b 4096 -f $user_ssh_dir/id_rsa -N ""
fi

chown -R $user_name:$user_name $user_home

# Delete existing public key file in S3 bucket if exists
aws s3 rm s3://my-key1/server.pub
# if aws s3 ls s3://my-key1/server.pub; then
#    aws s3 rm s3://my-key1/server.pub
#fi

# Upload public key to S3 bucket with a custom name
aws s3 cp $user_ssh_dir/id_rsa.pub s3://my-key1/server.pub

#logi =n into user
user_name="ansible-user"
user_home="/home/$user_name"
user_ssh_dir="$user_home/.ssh"
ssh_key_path="$user_ssh_dir/authorized_keys"

mkdir -p $user_ssh_dir
chmod 700 $user_ssh_dir

aws s3 cp s3://my-key/server.pub $ssh_key_path
chmod 600 $ssh_key_path
chown -R $user_name:$user_name $user_home

cd
# Navigate to home directory and log a message
cd $user_home && echo "correct till this step" >>/var/log/main-data.log 2>&1

export AWS_REGION=ap-south-1

git clone https://github.com/ManoharShetty507/singlenode.git

# Define the inventory file and log file
# Define the inventory file and log file
INVENTORY_FILE="singlenode/ansible/inventories/inventory.ini"
LOG_FILE="ansible_script.log"

# Logging function
log() {
  local message="$1"
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $message" | sudo tee -a "$LOG_FILE"
}

# Function to update or add entries
update_entry() {
  local section=$1
  local host=$2
  local ip=$3

  log "Updating entry: Section: $section, Host: $host, IP: $ip"

  # Ensure the section header exists
  if ! grep -q "^\[$section\]" "$INVENTORY_FILE"; then
    log "Section $section not found. Adding section header."
    sudo bash -c "echo -e '\n[$section]' >>'$INVENTORY_FILE'"
  fi

  # Remove existing entry if it exists
  sudo sed -i "/^\[$section\]/,/^\[.*\]/{/^$host ansible_host=.*/d}" "$INVENTORY_FILE"

  # Add or update the entry
  sudo sed -i "/^\[$section\]/a $host ansible_host=$ip" "$INVENTORY_FILE"
}

# Check if the inventory file exists
if [ ! -f "$INVENTORY_FILE" ]; then
  log "Inventory file not found: $INVENTORY_FILE"
  exit 1
fi
# Fetch NFS IP and update the inventory file
NFS_IP=$(aws ec2 describe-instances --region ap-south-1 --filters "Name=tag:Name,Values=nfs" --query "Reservations[*].Instances[*].PublicIpAddress" --output text)

# Fetch the NFS IP and update the inventory file
if [ -z "$NFS_IP" ]; then
  log "Failed to fetch Bastion IP"
  exit 1
fi
log "NFS IP: $NFS_IP"

# Fetch the Bastion host public IP
log "Fetching Bastion IP"
BASTION_IP=$(aws ec2 describe-instances --region ap-south-1 --filters "Name=tag:Name,Values=k8s-instance" --query "Reservations[*].Instances[*].PublicIpAddress" --output text)

# Check if the IP is fetched successfully
if [ -z "$BASTION_IP" ]; then
  log "Failed to fetch Bastion IP"
  exit 1
fi
log "Bastion IP: $BASTION_IP"

# Update the inventory file
log "Updating inventory file with NFS and Bastion IPs"

# Use a temporary file to avoid editing issues
TEMP_FILE=$(mktemp)

# Flag to track if local and nfs sections have been found
LOCAL_FOUND=false
NFS_FOUND=false

# Read the inventory file and modify it
while IFS= read -r line; do
  # Check for the local section
  if [[ "$line" == "[local]" ]]; then
    echo "$line" >>"$TEMP_FILE"
    # Check if Bastion IP is already present
    if ! grep -q "$BASTION_IP" "$INVENTORY_FILE"; then
      echo "$BASTION_IP" >>"$TEMP_FILE" # Add Bastion IP under local if not exists
    else
      log "Bastion IP $BASTION_IP already exists in the inventory file."
    fi
    LOCAL_FOUND=true
    continue
  fi

  # Check for the nfs section
  if [[ "$line" == "[nfs]" ]]; then
    echo "$line" >>"$TEMP_FILE"
    # Check if NFS IP is already present
    if ! grep -q "$NFS_IP" "$INVENTORY_FILE"; then
      echo "$NFS_IP" >>"$TEMP_FILE" # Add NFS IP under nfs if not exists
    else
      log "NFS IP $NFS_IP already exists in the inventory file."
    fi
    NFS_FOUND=true
    continue
  fi

  echo "$line" >>"$TEMP_FILE" # Write the line as is
done <"$INVENTORY_FILE"

# If local or nfs sections were not found, append them at the end
if [ "$LOCAL_FOUND" = false ]; then
  echo -e "\n[local]\n$BASTION_IP" >>"$TEMP_FILE"
fi

if [ "$NFS_FOUND" = false ]; then
  echo -e "\n[nfs]\n$NFS_IP" >>"$TEMP_FILE"
fi

# Replace the original inventory file with the updated one
mv "$TEMP_FILE" "$INVENTORY_FILE"

log "Inventory file updated successfully"
