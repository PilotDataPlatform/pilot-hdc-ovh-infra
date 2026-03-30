# env var is passed via tfvars for consistency across modules
# but not yet referenced in kong resources
rule "terraform_unused_declarations" {
  enabled = false
}
