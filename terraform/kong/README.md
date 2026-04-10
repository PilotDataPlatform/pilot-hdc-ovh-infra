# Kong Gateway Configuration

Terraform-managed Kong services, routes, and plugins for the Pilot-HDC API gateway.

**No CI/CD pipeline.** You apply changes manually from a local workstation via `kubectl port-forward` to the Kong Admin API.

## Architecture

Kong sits in front of Pilot-HDC backend services in Kubernetes. Terraform manages services (upstream K8s endpoints), routes (path-based rules), and per-route plugins (OIDC token validation and CORS).

`locals.tf` contains a single `local.services` map that drives everything. You add or change a service by editing that map. The `services.tf`, `routes.tf`, and `plugins.tf` resources iterate over it via `for_each`.

## Services

| Service | Upstream | Route Path | OIDC | CORS |
|---|---|---|---|---|
| `pilot-portal-api` | `bff.utility:5060` | `/pilot/portal` | yes | yes |
| `pilot-upload-gr` | `upload.greenroom:5079` | `/pilot/upload/gr` | yes | yes |
| `pilot-download-gr` | `download.greenroom:5077` | `/pilot/portal/download/gr` | no | yes |
| `pilot-download-core` | `download.core:5077` | `/pilot/portal/download/core` | no | yes |
| `pilot-cli-bff-api` | `bff-cli.utility:5080` | `/pilot/cli` | yes | no |
| `pilot-user-auth` | `auth.utility:5061` | `/pilot/portal/users/auth` | no | yes |
| `pilot-user-auth-refresh` | `auth.utility:5061` | `/pilot/portal/users/refresh` | no | yes |
| `dataops-task-stream` | `dataops.utility:5063` | `/pilot/task-stream` | no | no |

OIDC-enabled routes validate Bearer tokens via Keycloak introspection (`bearer_only` mode, no browser redirects). Download and auth routes authenticate at the application layer.

## Prerequisites

- Terraform >= 1.5
- [SOPS](https://github.com/getsops/sops) with an age key that can decrypt `config/<env>/terraform.tfvars`
- `kubectl` access to the target cluster
- S3 backend credentials (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) from bootstrap Terraform output

## Usage

`run.sh` wraps init, plan, apply, and import. It decrypts SOPS tfvars to a tempfile, passes it to Terraform, and cleans up on exit.

```bash
# Port-forward Kong Admin API (separate terminal)
kubectl port-forward -n kong svc/kong-kong-admin 8001:8001

# Export S3 backend credentials
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."

# Plan and apply
./run.sh dev plan
./run.sh dev apply
./run.sh prod plan
./run.sh prod apply
```

### Commands

| Command | What it does |
|---|---|
| `./run.sh <env> init` | Initialize backend |
| `./run.sh <env> plan` | Init + decrypt tfvars + plan (saves `deploy-<env>.tfplan`) |
| `./run.sh <env> apply` | Apply a saved plan file |
| `./run.sh <env> import <addr> <id>` | Import an existing Kong resource into state |

## Making Changes

### Adding a service

Add an entry to the `services` map in `locals.tf`:

```hcl
"my-new-service" = {
  host       = "my-svc.my-namespace"  # K8s service DNS
  port       = 8080
  path       = null                    # upstream path prefix (null = root)
  route_path = "/pilot/my-endpoint"    # external route path
  methods    = ["GET", "POST", "OPTIONS"]
  oidc       = true                    # attach OIDC plugin
  cors       = true                    # attach CORS plugin
  # timeout  = 180000                  # override default 60s
}
```

This creates the service, route, and any enabled plugins in one go.

### Modifying a service

Edit the entry in `locals.tf`. Common fields:

- `route_path`, `host`, `port`, `path` for routing changes
- `oidc` / `cors` booleans to toggle plugins
- `methods` list for allowed HTTP methods
- `timeout` in milliseconds (default: 60000)

### Changing OIDC or CORS configuration

Plugin-level variables (discovery URL, introspection endpoint, client secret, CORS origins) live in the encrypted tfvars. Edit them with SOPS:

```bash
sops --input-type dotenv --output-type dotenv config/dev/terraform.tfvars
```

Plugin behavior settings like `bearer_only` or `ssl_verify` are in `plugins.tf`.

### Removing a service

Delete the entry from `locals.tf`. Plan will show the service, route, and associated plugins being destroyed.

## Environment Separation

Dev and prod share Terraform code. Separation is config and state:

```
config/
  dev/
    backend.tfbackend     # state: kong/dev/terraform.tfstate
    terraform.tfvars      # SOPS-encrypted variables
  prod/
    backend.tfbackend     # state: kong/prod/terraform.tfstate
    terraform.tfvars      # SOPS-encrypted variables
```

State lives in OVH S3-compatible object storage (`s3.de.io.cloud.ovh.net`).

## Secrets

Tfvars files are SOPS-encrypted with [age](https://github.com/FiloSottile/age). The `.sops.yaml` at the repo root defines authorized recipients.

Edit encrypted variables:

```bash
sops --input-type dotenv --output-type dotenv config/dev/terraform.tfvars
```

Add a new recipient, then re-encrypt:

```bash
sops updatekeys -y config/dev/terraform.tfvars
```

## Files

| File | Purpose |
|---|---|
| `locals.tf` | Service definitions (**the main file you edit**) |
| `services.tf` | Kong service resources (`for_each` over `local.services`) |
| `routes.tf` | Kong route resources (`for_each` over `local.services`) |
| `plugins.tf` | OIDC and CORS plugins (filtered subsets of `local.services`) |
| `variables.tf` | Input variable declarations |
| `providers.tf` | Terraform and provider version constraints, S3 backend |
| `outputs.tf` | Service IDs, route IDs, configured route names |
| `run.sh` | Wraps init/plan/apply/import with SOPS decryption |
| `config/` | Per-environment backend configs and encrypted tfvars |
