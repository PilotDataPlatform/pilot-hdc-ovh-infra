# pilot-hdc-ovh-infra
This is a IaC repository that contains all the necessary code to setup the infrastructure that will run Pilot-HDC on OVH cloud.

## Manual steps
Before you try to run the terraform code, you'll need to do certain steps in OVH:

1) Create an apikey with the following permissions:
```
GET/POST/PUT/DELETE /cloud/project/*
```

2) Add the ssh key that will be used by default.

3) Create the floating ips that will be used by the nginx VMs.

## NFS Server Setup

The NFS server provides RWX persistent storage for K8s workloads. It runs on a private-network-only VM (no public IP), accessible via SSH through the nginx VM as a bastion.

**Not included in `make ansible`** — runs separately via `make ansible-nfs` due to dist-upgrade + filesystem creation side effects.

### Steps

1. Export S3 backend credentials (`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` — see `terraform/bootstrap/README.md`)
2. Add `deploy_nfs = true` and `nfs_volume_size = 50` to `terraform/config/dev/terraform.tfvars`
3. `make plan-dev` then `make apply-dev`
4. Attach the block volume to the NFS instance in OVH Console
5. SSH to the NFS VM via bastion (agent forwarding required) and verify the device:
   ```bash
   ssh-add ~/.ssh/your-ovh-key
   ssh -A ubuntu@<nginx-ip> -p <ssh-port>
   # then from nginx:
   ssh ubuntu@<nfs-private-ip> lsblk
   ```
   Expect `/dev/sdb` (override with `-e nfs_block_device=/dev/sdX` if different)
6. Add the NFS VM private IP to `ansible/vars/sensitive.yml`:
   ```yaml
   nfs_hosts:
     dev:
       ip: <private IP from terraform output nfs_addresses>
   ```
7. Test Ansible connectivity:
   ```bash
   cd ansible && ansible nfs -m ping -e ssh_port=22 -e @vars/sensitive.yml
   ```
8. Bootstrap SSH hardening and DNS (first run only, VM still on port 22):
   ```bash
   cd ansible && ansible-playbook playbooks/ssh-hardening.yml -l nfs \
     -e ssh_port=22 -e @vars/sensitive.yml
   cd ansible && ansible-playbook playbooks/dns-setup.yml -l nfs \
     -e @vars/sensitive.yml
   ```
9. `make ansible-nfs`

### Verification

From any host on the private network (e.g. a K8s node):
```bash
showmount -e <nfs-private-ip>        # expect /nfs/export 10.0.0.0/24
mount -t nfs <nfs-private-ip>:/nfs/export /mnt && touch /mnt/test && rm /mnt/test
```

## Acknowledgements
The development of the HealthDataCloud open source software was supported by the EBRAINS research infrastructure, funded from the European Union's Horizon 2020 Framework Programme for Research and Innovation under the Specific Grant Agreement No. 945539 (Human Brain Project SGA3) and H2020 Research and Innovation Action Grant Interactive Computing E-Infrastructure for the Human Brain Project ICEI 800858.

This project has received funding from the European Union’s Horizon Europe research and innovation programme under grant agreement No 101058516. Views and opinions expressed are however those of the author(s) only and do not necessarily reflect those of the European Union or other granting authorities. Neither the European Union nor other granting authorities can be held responsible for them.

![EU HDC Acknowledgement](https://hdc.humanbrainproject.eu/img/HDC-EU-acknowledgement.png)
