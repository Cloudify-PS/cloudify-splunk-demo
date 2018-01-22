#!/bin/bash -e

set -o pipefail

# Record stdout/stderr to a file.
# This will not be required with Cloudify 4.3 onward.
exec >> /tmp/install_forwarder.log 2>&1

working_dir=$(mktemp -d)

host_name=$(hostname)
forwarder_installer_url=$(ctx node properties forwarder_installer_url)
forwarder_home=$(ctx node properties home)
forwarder_user=$(ctx node properties user)
forwarder_admin_password=$(ctx node properties forwarder_admin_password)

ctx logger info "Downloading Splunk Forwarder installer from ${forwarder_installer_url} into ${working_dir}..."
wget -nv -O ${working_dir}/splunkfwd.tgz ${forwarder_installer_url}

ctx logger info "Extracting archive into ${forwarder_home}..."
sudo mkdir -p ${forwarder_home}
sudo tar -xzf ${working_dir}/splunkfwd.tgz --strip-components=1 -C ${forwarder_home}

sudo chown -R ${forwarder_user}:${forwarder_user} ${forwarder_home}

ctx logger info "Enabling start at boot"
sudo ${forwarder_home}/bin/splunk enable boot-start -user ${forwarder_user} --accept-license --answer-yes --no-prompt

ctx logger info "Starting Splunk Forwarder for the first time"
sudo ${forwarder_home}/bin/splunk start --accept-license --answer-yes --no-prompt

ctx logger info "Updating admin password"
sudo sudo -u ${forwarder_user} ${forwarder_home}/bin/splunk edit user admin -password ${forwarder_admin_password} -role admin -auth "admin:changeme"

ctx logger info "Configuring Splunk Forwarder to monitor /var/log..."
sudo -u ${forwarder_user} ${forwarder_home}/bin/splunk add monitor /var/log/ -auth "admin:${forwarder_admin_password}"

ctx logger info "Cleaning up"
rm -rf ${working_dir}
