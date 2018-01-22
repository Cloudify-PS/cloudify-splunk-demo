# Splunk and Splunk Forwarder

This blueprint orchestrates Splunk and Splunk Forwarder.

## Supported platforms

This blueprint has been tested with an official CentOS 7.x image.

It will also work with a RHEL 7.x image, provided that the image is set up to connect to
official `yum` repositories.

## Prerequisites

* Cloudify Manager 4.2 or later
* A VPC
* Splunk and Splunk Forwarder installation archives, accessible from within the VPC via HTTP
* Certain inputs default to values of Cloudify Manager Secrets. If these inputs are not provided at
  deployment time, then they must exist as Secrets on the manager:
  * Common:
    * `splunk_installer_url`: URL of the Splunk installer tar.gz file
    * `splunk_admin_password`: the administrator password to set for Splunk
    * `forwarder_installer_url`: URL of the Splunk Forwarder installer tar.gz file
    * `forwarder_admin_password`: the administrator password to set for Splunk Forwarder
  * AWS-specific:
    * `ec2_region_name`: the EC2 region to operate on
    * `aws_access_key_id`: the access key ID to use for communicating with AWS
    * `aws_secret_access_key`: the secret access key for communicating with AWS
    * `vpc_id`: the ID of the VPC to work in
    * `keypair_name`: name of keypair to associate new VM's with
    * `agents_security_group`: the ID of a security group that allows agents access to the
      Cloudify Manager
  * OpenStack-specific:
    * `openstack_username`: username for OpenStack authentication
    * `openstack_password`: password for OpenStack authentication
    * `openstack_tenant_name`: name of tenant to operate on
    * `openstack_auth_url`: Keystone authentication URL
    * `openstack_region`: region to work with
    * `keypair_name`: name of keypair to associate new VM's with
    * `agents_security_group`: the ID of a security group that allows agents access to the
      Cloudify Manager

## Structure

This blueprint is designed to support various IaaS providers:

* The common parts are located in the `includes` directory
* For each IaaS provider, a separate YAML file exists (such as `aws-blueprint.yaml`), which adds
  the IaaS-specific parts.

## Functionality

The blueprint creates two VM's:

* VM containing Splunk (referred-to as `splunk_vm`)
* VM containing Splunk Forwarder (referred-to as `forwarder_vm`)

On both VM's, Splunk is configured to monitor everything under `/var/log`.

## Auto-heal

The blueprint supports auto-healing of either VM's:

* If `splunk_vm` becomes unresponsive, it is terminated and reinstalled
  * The Splunk Forwarder will then be reconfigured to forward to the new Splunk address
* If `forwarder_vm` becomes unresponsive, it is terminated and reinstalled
