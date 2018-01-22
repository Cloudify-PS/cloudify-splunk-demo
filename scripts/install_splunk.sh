#!/bin/bash -e

set -o pipefail

# Record stdout/stderr to a file.
# This will not be required with Cloudify 4.3 onward.
exec >> /tmp/install_splunk.log 2>&1

working_dir=$(mktemp -d)

host_name=$(hostname)

splunk_installer_url=$(ctx node properties splunk_installer_url)
splunk_password=$(ctx node properties splunk_admin_password)
splunk_web_port=$(ctx node properties splunk_web_port)
splunk_management_port=$(ctx node properties splunk_management_port)
splunk_receiver_port=$(ctx node properties splunk_receiver_port)
splunk_user=$(ctx node properties user)
splunk_home=$(ctx node properties home)
splunk_db_path=$(ctx node properties db_path)

ctx logger info "Downloading Splunk installer from ${splunk_installer_url} into ${working_dir}"
wget -nv -O ${working_dir}/splunk.tgz ${splunk_installer_url}

ctx logger info "Creating Splunk directories: ${splunk_home}, ${splunk_db_path}"
sudo mkdir -p ${splunk_home}
sudo mkdir -p ${splunk_db_path}

sudo chown ${splunk_user}:${splunk_user} ${splunk_home}
sudo chown ${splunk_user}:${splunk_user} ${splunk_db_path}

ctx logger info "Extracting archive into ${splunk_home}..."
sudo tar -xzf ${working_dir}/splunk.tgz --strip-components=1 -C ${splunk_home}

sudo chown -R ${splunk_user}:${splunk_user} ${splunk_home}
sudo chown -R ${splunk_user}:${splunk_user} ${splunk_db_path}

ctx logger info "Executing pre-configuration steps"
sudo -u ${splunk_user} touch ${splunk_home}/etc/.ui_login

cat <<EOF | sudo -u ${splunk_user} tee ${splunk_home}/etc/system/local/telemetry.conf
[general]
sendLicenseUsage = false
sendAnonymizedUsage = false
precheckSendLicenseUsage = false
precheckSendAnonymizedUsage = false
showOptInModal = false
EOF

cat <<EOF | sudo -u ${splunk_user} tee ${splunk_home}/etc/system/local/ui-tour.conf
[default]
useTour = false
EOF

cat <<EOF | sudo -u ${splunk_user} tee ${splunk_home}/etc/system/local/inputs.conf
[default]
host = ${host_name}
EOF

echo -e "\nSPLUNK_DB=${splunk_db_path}/" | sudo -u ${splunk_user} tee -a ${splunk_home}/etc/splunk-launch.conf.default

ctx logger info "Enabling start at boot"
sudo ${splunk_home}/bin/splunk enable boot-start -user ${splunk_user} --accept-license --answer-yes --no-prompt

ctx logger info "Starting Splunk for the first time"
sudo ${splunk_home}/bin/splunk start --accept-license --answer-yes --no-prompt

ctx logger info "Configuring Splunk admin user and default ports"
sudo sudo -u ${splunk_user} ${splunk_home}/bin/splunk edit user admin -password ${splunk_password} -role admin -auth "admin:changeme"
sudo sudo -u ${splunk_user} ${splunk_home}/bin/splunk set web-port ${splunk_web_port} -auth "admin:${splunk_password}"
sudo sudo -u ${splunk_user} ${splunk_home}/bin/splunk set splunkd-port ${splunk_management_port} -auth "admin:${splunk_password}"
sudo sudo -u ${splunk_user} ${splunk_home}/bin/splunk set servername ${host_name} -auth "admin:${splunk_password}"
sudo sudo -u ${splunk_user} ${splunk_home}/bin/splunk enable listen ${splunk_receiver_port} -auth "admin:${splunk_password}"

ctx logger info "Configuring Splunk monitoring of host logs"
sudo sudo -u ${splunk_user} ${splunk_home}/bin/splunk add monitor /var/log/ -auth "admin:${splunk_password}"

echo never | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
cat <<EOF | sudo tee -a /etc/rc.local
   if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
      echo never > /sys/kernel/mm/transparent_hugepage/enabled
   fi
EOF

ctx logger info "Restarting Splunk"
sudo -u ${splunk_user} ${splunk_home}/bin/splunk restart

ctx logger info "Cleaning up"
rm -rf ${working_dir}
