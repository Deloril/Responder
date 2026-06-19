# `Project:Responder` environment

## To access the attacker environment: 
1. Make sure your public IP is whitelisted. If you face timeouts or errors accessing the environment, this is likely why. 
2. Log in to the attacker server with the credentials from the inventory file generated when building the environment (or ask the person who built the environment).

## To access the windows environment: 
1. Make sure your public IP is whitelisted. If you face timeouts or errors accessing the environment, this is likely why. 
2. Log in to the windows bastion host with the credentials from the inventory file generated when building the environment (or ask the person who built the environment).
3. From the windows bastion, RDP or VNC to any of the hosts in the environment using the credentials below.
4. **VNC** (non-disruptive, view active session): Connect from the bastion to any host on port 5900 with password `tsg_vnc_2025`. VNC lets you observe the desktop without kicking off the logged-in user.

``` yml
Domain: TSG-INTERNAL (tsg-internal.lab)
Domain Admin: 
  - user: Administrator
    - domain_user: TSG-INTERNAL\Administrator
    - domain_password: tsgInt3rnal
Domain Users:
  - user: ben
    - domain_username: TSG-INTERNAL\ben
    - domain_password: Kia0ra2025!
  - user: kate
    - domain_username: TSG-INTERNAL\kate
    - domain_password: Wellington#1
  - user: sam.hewitt
    - domain_username: TSG-INTERNAL\sam.hewitt
    - domain_password: DevOps2025!
    - notes: Developer workstation (client-3), VS Code with vault-sdk-snippets extension
SPN User:
  - user: AV-Admin
    - domain_username: TSG-INTERNAL\AV-Admin
    - domain_password: SuperGenericPassword1!
```

### Environment Notes
- Machines in the same subnet can communicate on all ports.
- Client machines in the Corp subnet can reach the file server but cannot reach the sql server. 
- Machines in the Corp subnet can reach the web server.
- All machines have access to the internet over TCP 80/443. 
- Machines are behind a NAT gateway so are not directly reachable from the internet, except for the web server which can be accessed on TCP80/443 on its public IP or dns name.

### `Project: Responder` Infrastructure Diagram
![](project-responder-diagram.jpeg)
