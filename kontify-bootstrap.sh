#!/bin/bash
# This block defines the variables the user of the script needs to input
# when deploying using this script.
#
#
#<UDF name="hostname" label="The hostname for the new Linode.">
# HOSTNAME=
#
#<UDF name="fqdn" label="The new Linode's Fully Qualified Domain Name">
# FQDN=
#
#<UDF name="user" label="Name of the user with docker privileges">
# USER=

# This sets the variable $IPADDR to the IP address the new Linode receives.

SSH_KEY1="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3AQvLzePBFtkqgkhtvdGys1qagV/UIiNR2nY3ffcKgwfhV4g4Dl3Tj/FCYrW2/cmFq3bMzF+CifJ8/Sd9ybWKiGZiZd9NxW3cHLqBMVfR2YhWKvwE8Jw5BFQ9nkGq/9vVnfppYNj3uNayFZZlVTSfv2T0H8T+POU8Nf6SORZbvhYseUvu9+PhW51/dn3L6rlmAznAGbDd5mqvge/lxsgG9A+uUg+vBvwJ00E8wVxEKPl0Sbees8Mk66Wg7eY6/uGooKJWEswaV567EtJ+sqiKfMwpEis+gQ+cOiaxrqJN0qpcH7rF1wQXkSE6hA6aGech61VQHEfaeESvxtdK5ucyQtrWMz0YW518IZrkHPo1954l+NfHPZbd+/jQTPfn4x1ZyGDAglMLPzf0Bu45ZUkmPgSG+Ofo/is2T6aJ+z31i//9WRfRWwXXtSBFOXTmLVTZpH7icOvJN+bN7XT6lh2fRhoOaqNq5Pxc6ppeF1lDqnH3f5jXCcTt7CZa2UaiaqPM4AubO1aa+Sw6MQFANIjDjNbZlcdLOgiuG6mPqtfdJ5u0huCn7HFBeJUuq9rwMquGWBbkbx3cA7ARbu8klJ+mgxiO1w1e60zfIF7IDmG3cA2ivsVuWXPz6Uak2pnhmLgSeHrrQSa0j8ra1/xtMdFeuHHo+UzuqGCqtkcsvOzinQ== kepes@Peter-Kepess-MacBook-Pro.local"
SSH_KEY2="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDS9uzuz6fuznt+aUVrI4+6hG0nnwUqGfEkrh4Zc+aYHifBDWuS2g1Z313RV5rhdfEZFlYyg+81xTLD+ds6CZEbaBe0YD3j3OCIp2Zdz58RPsHhjpSvGg0AUEh8x2sKWVXZDmpswUfbW8j2y+6NIZBzYzRx7/1Ly1ZQUkzJGss9O6Qbm22i+IrQKvQlJNTGBE54yE3If9YIaeeK5V5MrmvS5IyQkIhnJZDgop1n31ZM2J0SdzdpeOhfiwS+70kXmb72eHbp0wzXm/NrL6uLotIhzdymQ6mEOZCv4Zo7BCDVFJ5RYDPSz23GgnQBLqdX0MgQ88JTUMKR5dOFhTsjPQeN29Ug9ERhUJmWRbuUdrTj2eZdCCpc1PaW913o5NQx2Uplf927e9umYI+/EyQiP1KTLRP0FVE1VuJ3WPxDcXVVW48jletI/wK3JG3LxnzoF2/opJFn1A2N07ZupjVLp9aSb7rVn3Fa0oVgkRyPPvnDt/KYaC6v+GR6avvCYBOlej3TVq81DTDzFCapxToKchtEHEu6h7D6pWtUc/Ndr8LH8z+rVcb5BsaadjrjTWEnJq5U0yVJF3k6hz1DDGMPp4q/K/2LJwgZLjkBTPjKQHPxbWOQknaipPqrPZ9+3UNuT0afNVvAxbY5iFEh5Fq7qBvpsfoI9YbWHF7eCDqSYw3FUQ== muskovicsgabor@muskovics.net"

IPADDR=$(/usr/sbin/ip addr show eth0 | awk '/inet / { print $2 }' | sed 's/\/..//')
USER=$1
FQDN=$2
HOSTNAME=$3

# This updates the packages on the system from the distribution repositories.
yum -y update
yum -y upgrade

# This section sets the hostname.
echo $HOSTNAME > /etc/hostname
hostname -F /etc/hostname

# This section sets the Fully Qualified Domain Name (FQDN) in the hosts file.
echo $IPADDR $FQDN $HOSTNAME >> /etc/hosts

useradd -m -G docker $USER
su - $USER -c "mkdir .ssh"
su - $USER -c "chmod 700 .ssh"
sudo usermod -aG docker $USER

su - $USER -c "echo '${SSH_KEY1}' >> .ssh/authorized_keys"
su - $USER -c "echo '${SSH_KEY2}' >> .ssh/authorized_keys"

su - $USER -c "chmod 600 .ssh/authorized_keys"

mkdir /root/.ssh
chmod 700 /root/.ssh

echo $SSH_KEY1 >> /root/.ssh/authorized_keys
echo $SSH_KEY2 >> /root/.ssh/authorized_keys

yum -y install tmux \
  yum-utils \
  device-mapper-persistent-data \
  mc \
  nano

yum-config-manager \
  --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

yum -y install docker-ce

systemctl enable docker
systemctl start docker

sed -i 's/#\?Port.*/Port 50022/' /etc/ssh/sshd_config
sed -i 's/#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

systemctl stop firewalld
systemctl disable firewalld

sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
