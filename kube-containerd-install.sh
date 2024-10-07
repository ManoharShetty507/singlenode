#!/bin/bash
set -e # Exit on error
sudo apt-get update -y

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

sudo apt-get update
sudo apt-get -y install containerd

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

sudo systemctl restart containerd
#systemctl status containerd

sleep 5s

# ls -l install.sh
# chmod u+x install.sh
# ls -l install.sh
# ./install.sh

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
#sudo apt install -y kubeadm=1.18.13-00 kubelet=1.18.13-00 kubectl=1.18.13-00 --allow-downgrades --allow-change-held-packages
#sudo apt-get install -y kubelet=1.21.0-00 kubeadm=1.21.0-00 kubectl=1.21.0-00

#sudo apt-mark hold kubelet kubeadm kubectl

kubeadm version

# chmod u+x install kube-install.sh
# ./install kube-install.sh

# sudo kubeadm init

# This command as root user
#kubeadm init

# Exit root user & exeucte below three command as normal user

# mkdir -p $HOME/.kube
# sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
# sudo chown $(id -u):$(id -g) $HOME/.kube/config

# This command also as normal user
# kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

# This is to regenerta the token again
# kubeadm token create --print-join-command

# use the token in workers as root

# untaint master and schedule pod on it
#kubectl taint nodes <nodename> node-role.kubernetes.io/master:NoSchedule-
# kubectl taint nodes ip-10-200-1-40 node-role.kubernetes.io/control-plane-
# This command as root user
#kubeadm init

# Exit root user & exeucte below three command as normal user

# mkdir -p $HOME/.kube
# sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
# sudo chown $(id -u):$(id -g) $HOME/.kube/config

# This command also as normal user
# kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

# This is to regenerta the token again
# kubeadm token create --print-join-command

# use the token in workers as root
# kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
#kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/v3.14/manifests/calico.yaml
# kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# untaint master and schedule pod on it
#kubectl taint nodes <nodename> node-role.kubernetes.io/master:NoSchedule-

# apt-mark unhold kubeadm && apt-get update && apt-get install -y kubeadm=1.23.0-00 && apt-mark hold kubeadm

#sudo apt-get install -qy kubelet=1.9.6-00 kubectl=1.9.6-00 kubeadm=1.9.6-00

# https://stackoverflow.com/questions/49721708/how-to-install-specific-version-of-kubernetes

echo "Script completed successfully!" | sudo tee script_completion.log
