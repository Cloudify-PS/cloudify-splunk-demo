#!/bin/bash -e

set -o pipefail

# Record stdout/stderr to a file.
# This will not be required with Cloudify 4.3 onward.
exec >> /tmp/connnect_to_splunk.log 2>&1

forwarder_home=$(ctx source node properties home)
forwarder_user=$(ctx source node properties user)
forwarder_admin_password=$(ctx source node properties forwarder_admin_password)
splunk_server=$(ctx target instance host_ip)
splunk_receiver_port=$(ctx target node properties splunk_receiver_port)
splunk_server_location="${splunk_server}:${splunk_receiver_port}"

ctx logger info "Configuring message forwarding to Splunk server located at ${splunk_server_location}"
sudo -u ${forwarder_user} ${forwarder_home}/bin/splunk add forward-server ${splunk_server_location} -auth "admin:${forwarder_admin_password}"
