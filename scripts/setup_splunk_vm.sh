#!/bin/bash -e

set -o pipefail

# Record stdout/stderr to a file.
# This will not be required with Cloudify 4.3 onward.
exec >> /tmp/setup_splunk_vm.log 2>&1

ctx logger info "Setting permissive selinux"
sudo setenforce Permissive

ctx logger info "Creating Splunk group and user: ${splunk_user}"

sudo groupadd -f ${splunk_user}

if ! id -u ${splunk_user} 2>/dev/null; then
    sudo useradd -c "Splunk Server" -s /bin/bash -g ${splunk_user} ${splunk_user}
else
    echo "User ${splunk_user} already exists; skipping"
fi

ctx logger info "Installing packages"
sudo yum -y install libselinux-python psmisc ksh mc wget curl dstat zsh git nano zip unzip bzip2 ntpdate ntp

cat <<EOF | sudo tee /etc/security/limits.d/99-splunk.conf
* hard   nofile 64000
* soft   nofile 10240
* hard   nproc  64000
* soft   nproc  10240
EOF
