provider "aws" {
  region = "ap-south-1" # Correct region code for Asia South (Mumbai)
}

# Fetch the existing VPC by name
data "aws_vpc" "selected_vpc" {
  filter {
    name   = "tag:Name"
    values = ["Hosting-VPC"]
  }
}

# Fetch the existing subnet by name
data "aws_subnet" "selected_subnet" {
  filter {
    name   = "tag:Name"
    values = ["Hosting-Public-1"]
  }

  vpc_id = data.aws_vpc.selected_vpc.id
}

# Fetch the existing security group by name and retrieve its ID
data "aws_security_group" "selected_sg" {
  filter {
    name   = "group-name"
    values = ["Hosting-VPC-SG"]
  }

  vpc_id = data.aws_vpc.selected_vpc.id
}

# Define EC2 instance with the updated AMI ID and user data script
resource "aws_instance" "k8s_instance" {
  ami                    = "ami-03bb6d83c60fc5f7c" # Updated AMI ID
  instance_type          = "t2.medium"
  key_name               = "testing-dev-1" # Do not include the .pem extension
  subnet_id              = data.aws_subnet.selected_subnet.id
  vpc_security_group_ids = [data.aws_security_group.selected_sg.id] # Use security group ID

  # Pass the user script using the file function
  user_data = file("kube-containerd-install.sh")

  # Tags for the instance
  tags = {
    Name                               = "k8s-instance" # Update this name if needed
    "kubernetes.io/cluster/kubernetes" = "owned"        # Specific tag as requested
  }
}

# Output only the public IP of the EC2 instance
output "public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.k8s_instance.public_ip
}
