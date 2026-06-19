# `Project: Responder` - Ansible

Ansible is the configuration management and automation tool of choice. Ansible is a flexible and powerful tool that can manage configuration of various infrastructure. 

Ansible is being used to configure various aspects of the environment. It automates set-up of the windows domain, file server, sql server, splunk server and all other customisations.

## Ansible Modules
`Project: Responder` is using Ansible playbooks to deploy the configuration changes. Several modules have been created that represent logical configuration groups. 
- **ansible-bastion-prereq**: Ansible playbook to deploy ansible and all pre-requisites to the linux bastion server in the `Project: Responder` environment.
- **windows**: Ansible playbook to configure all aspects of the windows infrastructure. This includes building the domain and promoting a domain controller, configuring and joing members to the domain, configuring domain users and groups. This playbook also sets up the file server/sql server/web server and configures sysmon and splunk forwarding. This playbook also deploys CrowdStrike agents to domain servers.

## Running Ansible
Ansible playbooks for configuring the environment should be run from the linux bastion host because infrastructure in the environment is not internet accessible. The exception to this is the `ansible-bastion-prereq` playbook which is run from your local machine to configure the bastion server.

### Running `ansible-bastion-prereq`
*Run this from your local machine*
```bash
# Depending on where you call `ansible-playbook` from, you may need to adjust the directory paths
ansible-playbook -i ansible-bastion-prereq/bastion_ansible_inventory_file ansible-bastion-prereq/install_ansible-prereqs.yml
```

*Alternatively, from the repo root, run `./scripts/bastion_deploy_ansible_playbooks.sh <region>` to copy playbooks to the Linux bastion and execute the full Windows/public stack.*

*Before running ansible manually on the bastion server, use scp to copy each ansible playbook directory to the bastion server*

### Running `windows`
*Run this from the linux bastion server*
```bash
ansible-playbook -i windows/windows_ansible_inventory_file windows/windows_build_env.yml
```
    