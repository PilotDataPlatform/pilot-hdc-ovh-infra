.PHONY: init fmt validate plan apply destroy ansible-ping ansible

# Terraform
init:
	cd terraform && terraform init

fmt:
	cd terraform && terraform fmt -recursive

validate:
	cd terraform && terraform validate

plan:
	cd terraform && terraform plan

apply:
	cd terraform && terraform apply

destroy:
	cd terraform && terraform destroy

terraform-all: init validate plan apply

# Ansible
ansible-ping:
	cd ansible && ansible nginx -m ping -e @vars/sensitive.yml

ansible:
	cd ansible && ansible-playbook playbooks/site.yml -e @vars/sensitive.yml
