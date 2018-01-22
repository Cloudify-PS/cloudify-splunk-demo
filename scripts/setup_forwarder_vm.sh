#!/bin/bash -e

set -o pipefail

# Record stdout/stderr to a file.
# This will not be required with Cloudify 4.3 onward.
exec >> /tmp/setup_forwarder_vm.log 2>&1

ctx logger info "Installing common packages"
sudo yum -y install wget

ctx logger info "Creating forwarder group and user: ${forwarder_user}"

sudo groupadd -f ${forwarder_user}

if ! id -u ${forwarder_user} 2>/dev/null; then
    sudo useradd -c "Splunk Forwarder" -d ${forwarder_home} -s /bin/bash -g ${forwarder_user} ${forwarder_user}
else
    echo "User ${forwarder_user} already exists; skipping"
fi
