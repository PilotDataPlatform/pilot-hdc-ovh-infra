resource "keycloak_authentication_flow" "project" {
  for_each = toset(var.workspace_projects)

  realm_id = keycloak_realm.hdc.id
  alias    = "Browser-With-Group-Enforcement-${title(each.value)}"
}

resource "keycloak_authentication_subflow" "project_browser" {
  for_each = toset(var.workspace_projects)

  realm_id          = keycloak_realm.hdc.id
  parent_flow_alias = keycloak_authentication_flow.project[each.value].alias
  alias             = "Browser-With-Group-Enforcement-${title(each.value)}-Browser-Flow"
  requirement       = "REQUIRED"
}

resource "keycloak_authentication_execution" "project_cookie" {
  for_each = toset(var.workspace_projects)

  realm_id          = keycloak_realm.hdc.id
  parent_flow_alias = keycloak_authentication_subflow.project_browser[each.value].alias
  authenticator     = "auth-cookie"
  requirement       = "ALTERNATIVE"
}

resource "keycloak_authentication_execution" "project_idp_redirect" {
  for_each = toset(var.workspace_projects)

  realm_id          = keycloak_realm.hdc.id
  parent_flow_alias = keycloak_authentication_subflow.project_browser[each.value].alias
  authenticator     = "identity-provider-redirector"
  requirement       = "ALTERNATIVE"
}

resource "keycloak_authentication_subflow" "project_forms" {
  for_each = toset(var.workspace_projects)

  realm_id          = keycloak_realm.hdc.id
  parent_flow_alias = keycloak_authentication_subflow.project_browser[each.value].alias
  alias             = "Browser-With-Group-Enforcement-${title(each.value)}-Forms"
  requirement       = "ALTERNATIVE"
  depends_on        = [keycloak_authentication_execution.project_idp_redirect]
}

resource "keycloak_authentication_execution" "project_username_password" {
  for_each = toset(var.workspace_projects)

  realm_id          = keycloak_realm.hdc.id
  parent_flow_alias = keycloak_authentication_subflow.project_forms[each.value].alias
  authenticator     = "auth-username-password-form"
  requirement       = "REQUIRED"
}

resource "keycloak_authentication_subflow" "project_conditional_otp" {
  for_each = toset(var.workspace_projects)

  realm_id          = keycloak_realm.hdc.id
  parent_flow_alias = keycloak_authentication_subflow.project_forms[each.value].alias
  alias             = "Browser-With-Group-Enforcement-${title(each.value)}-Conditional-OTP"
  requirement       = "CONDITIONAL"
  depends_on        = [keycloak_authentication_execution.project_username_password]
}

resource "keycloak_authentication_execution" "project_otp" {
  for_each = toset(var.workspace_projects)

  realm_id          = keycloak_realm.hdc.id
  parent_flow_alias = keycloak_authentication_subflow.project_conditional_otp[each.value].alias
  authenticator     = "auth-otp-form"
  requirement       = "REQUIRED"
  depends_on        = [keycloak_authentication_execution.project_username_password]
}

# MANUAL STEPS — after terraform apply, for each project flow:
#
# In KC admin: Authentication > Flows > "Browser-With-Group-Enforcement-<Project>"
#
# 1. At the TOP LEVEL of the flow (sibling of Browser-Flow), click "Add step":
#    - Search "require-group", add it, set to REQUIRED
#    - Click gear icon to configure which group is required
#    Note: require-group may be a custom SPI — if not listed, check KC deployment has it
#
# 2. At the TOP LEVEL, click "Add sub-flow":
#    - Name: "cond" (or similar), set to CONDITIONAL
#    - Inside that subflow, click "Add step":
#      - Search "conditional-user-role", add it, set to REQUIRED
#      - Configure: set the role to check (e.g. "contributor")
#
# 3. Also create per-project realm roles if not already present:
#    Realm roles > Create: <project>-admin, <project>-collaborator, <project>-contributor
#
# Final flow structure:
#   Browser-With-Group-Enforcement-<Project>
#   ├── Browser-Flow (REQUIRED)                    ← TF-managed
#   │   ├── Cookie (ALTERNATIVE)
#   │   ├── IdP Redirector (ALTERNATIVE)
#   │   └── Forms (ALTERNATIVE)
#   │       ├── Username/Password (REQUIRED)
#   │       └── Conditional OTP (CONDITIONAL)
#   │           └── OTP Form (REQUIRED)
#   ├── Require Group (REQUIRED)                   ← manual
#   └── cond (CONDITIONAL)                         ← manual
#       └── Condition - user role (REQUIRED)
#
# Ref: cscs-infra/configurations/keycloak-terraform/authentication-hdctestproject.tf
