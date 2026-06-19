## Ansible

### Overview
Ansible is used to configure various aspects of the environment. Ansible playbooks have been written that use modules to configure things like the windows domain, dns settings, group policies, crowdstrike installation, registry settings and more. 

An ansible playbook contains a set of plays that perform (mostly) idempotent actions on a host. For example, the windows playbook contains a set of plays that will change a hostname and join a host to a domain. These actions performed by ansible are idempotent because it first checks whether a change is required and only performs the action if the condition is not already satisfied.  

### Code Structure
Ansible playbooks are provided in a directory structure that groups similar operations into modules. For example, all the playbooks that relate to configuring windows systems are contained in their own folder called `windows`. 

```yml
- ansible
    | ansible-bastion-prereq # Sets up any dependencies on the linux bastion (i.e. Ansible, pywinrm, etc.)
    | attack # Installs metasploit and other attack tools
    | windows # Configures all windows aspects of the environment (i.e domain, applications, logging, etc.)
    | windows-bastion # Configures settings on the windows bastion 
```

Inside each folder are several more resources. These is how they are structured in the windows folder.

```yml
- windows
    | files # Contains files that are referenced by playbooks (i.e. for ansible.copy)
    | inventory # Contains host inventory files that are used by ansible
    | roles # Contains ansible roles. These contain more ansible playbooks for specific actions. This is where the bulk of the code is located.
    | vars # This contains variables used by ansible playbooks.
    - <ansible playbooks>.yml # There are several playbooks which import other playbooks and roles.
```


### Execution of Ansible Playbooks
When the Project:responder environments are being built, they utilise a Make file to orchestrate the build process between Terraform and Ansible. See the Building.md file for more info. 

Ansible playbooks are executed via the ansible-playbook tool. An ansible playbook execution differs slightly from the normal ansible tool. ansible-playbook takes two main arguments, a inventory file in the standard ini or yml format and a path to an ansible playbook. 

Ansible will then load the playbook and inventory file and begin execution.

```
ansible-playbook -i windows/inventory/windows_ansible_inventory_file_amer windows/windows_build_env.yml
```

