# CI/CD

## Workflows

| Workflow | Trigger | Scope | Environment |
|---|---|---|---|
| **Terraform Lint** | PR to main | `terraform/**` | - |
| **Terraform Deploy** | Push to main / manual dispatch | infra + keycloak (dev), infra (prod) | dev, prod |
| **Ansible Lint** | PR to main | `ansible/**` | - |
| **Ansible Deploy** | Manual (workflow_dispatch) | site/nfs/freeipa/guacamole | dev |

### Terraform Lint

Runs on PRs that touch `terraform/**`. Steps: gitleaks secret scan, `terraform fmt -check` (infra + keycloak), `terraform validate` (infra + keycloak), tflint (recursive, includes kong), checkov (recursive, includes kong — static analysis for security misconfigs and compliance violations in TF resources).

### Terraform Deploy

**Dev**: auto plan+apply on push to main. Matrix: `infra` and `keycloak` modules in parallel. **Prod**: manual dispatch (`deploy_prod: true`), infra module only (keycloak/kong prod tfvars not yet created). Same-job plan+apply in both cases, no artifact passing (plan files contain decrypted secrets). Concurrency groups: one run per module+env at a time.

### Ansible Lint

Runs on PRs that touch `ansible/**`. Steps: yamllint, ansible-lint (moderate profile), syntax-check all playbooks with dummy vars (no SOPS decryption needed).

### Ansible Deploy

Manual trigger only. Bootstrap playbooks (nfs/freeipa/guacamole) run dist-upgrade and reboot, too disruptive for auto-deploy. Select playbook, `--limit` pattern (defaults to `!nginx-prod`), and optional extra args from the dispatch UI.

Log sanitization: the masking step decrypts `sensitive.yml` and calls `::add-mask::` on every scalar value before Ansible runs. No IPs, passwords, or keys visible in public logs.

```bash
# Trigger via CLI
gh workflow run "Ansible Deploy" -f playbook=site
gh workflow run "Ansible Deploy" -f playbook=guacamole -f extra_args="-e ssh_port=22"
```

## What's NOT in CI/CD

| Component | Why | How to deploy |
|---|---|---|
| **Kong TF** | Separate state backend, infrequent changes | `make plan-kong && make apply-kong` |
| **ArgoCD bootstrap** | One-time setup, requires kubeconfig | `make ansible-argocd-bootstrap` |
| **Prod TF (keycloak, kong)** | Prod tfvars not yet created for these modules | Manual via `run.sh prod plan && run.sh prod apply` |
| **Prod Ansible** | No CI runner access to prod hosts | `./ansible/run.sh` with prod inventory |
| **SSH hardening** | Included in `site` playbook (CI runs it), but standalone runs are manual | `./ansible/run.sh ansible-playbook playbooks/ssh-hardening.yml -l <group> -e @vars/sensitive.yml` |
| **NFS/FreeIPA/Guacamole** | Available via dispatch but first run needs `-e ssh_port=22` | `make ansible-nfs`, `make ansible-freeipa`, `make ansible-guacamole` (see README for bootstrap steps) |

## Secrets

| GitHub Secret | Used by | Purpose |
|---|---|---|
| `HDC_OVH_SOPS_AGE_KEY` | TF Deploy, Ansible Deploy | Decrypt SOPS-encrypted tfvars and sensitive.yml |
| `HDC_OVH_SSH_PRIVATE_KEY` | Ansible Deploy | SSH to target VMs (ed25519, CI-only key) |
| `HDC_OVH_AWS_ACCESS_KEY_ID` | TF Deploy | S3 state backend auth |
| `HDC_OVH_AWS_SECRET_ACCESS_KEY` | TF Deploy | S3 state backend auth |

OVH API credentials (`OVH_APPLICATION_KEY`, etc.) live inside SOPS-encrypted tfvars. The age key decrypts them at runtime.

## Local Validation

```bash
make ansible-lint   # Full lint suite in Docker container (no local install needed)
make ci-tf          # TF fmt + validate + tflint + checkov (requires local tools)
```

## Security Considerations

- **Public repo**: Plan files and Ansible output can contain decrypted values. TF uses same-job plan+apply (no artifacts). Ansible masks all sensitive.yml scalars before execution.
- **gitleaks**: Scans for secrets on every PR (TF Lint workflow).
- **SOPS**: All credentials encrypted at rest with age. `SOPS_AGE_KEY` env var, no key file needed in CI.
- **CI SSH key**: Dedicated ed25519 key (`robot-cicd@indocresearch.org`), deployed to dev hosts only. Not shared with personal keys.
