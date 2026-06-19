## Inventory

### Overview
Inventory files (not to be confused with ansible inventory files), are generated at build time by terraform and provide access details for the newly built environment. There are three different inventory types, `attack_server_details`, `bastion_server_details`, and `victim_infra_details`. For each environment that is currently running there is a corresponding set of inventory files. 

#### attack_server_details
```
[amer]
## Linux Attack Server ##
Linux Bastion Public IP: 34.227.80.40
Linux Bastion User: ubuntu
Linux Bastion Certificate: project-responder-ssh (see your team's secret store)
```

#### bastion_server_details
```
[amer]
## Windows Bastion Server ##
Windows Bastion Public IP: 3.215.66.70
Windows Bastion Private IP: 10.0.3.7
Windows Bastion Public DNS: ec2-3-215-66-70.compute-1.amazonaws.com
Windows Bastion User: Administrator
Windows Bastion Password: <password>

## Linux Bastion Server ##
Linux Bastion Public IP: 3.90.112.82
Linux Bastion Private IP: 10.0.3.8
Linux Bastion User: ubuntu
Linux Bastion Certificate: project-responder-ssh (see your team's secret store)

```

#### victim_infra_details
```
[amer]

## Public subnet (10.0.0.0/24) ##
web server: web-amer.tsg-internal.lab 10.0.0.6 107.21.204.195 ec2-107-21-204-195.compute-1.amazonaws.com
nat gateway: 34.232.255.45

## Corp subnet (10.0.1.0/24) ##
domain controller: DC01-amer.tsg-internal.lab 10.0.1.6
client 1: client-1-amer.tsg-internal.lab 10.0.1.10
client 2: client-2-amer.tsg-internal.lab 10.0.1.11

## Secret subnet (10.0.2.0/24)
file server: file-amer.tsg-internal.lab 10.0.2.6
sql server: sql-amer.tsg-internal.lab 10.0.2.7
```

