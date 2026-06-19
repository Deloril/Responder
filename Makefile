# Load local secrets from .env (gitignored). See .env.example for the list of
# expected variables (AWS_PROFILE, TERRAFORM_STATE_BUCKET, TF_VAR_*).
-include .env
export

# Initialise the terraform backend with the state bucket from .env.
init:
	@test -n "$(TERRAFORM_STATE_BUCKET)" || { echo "TERRAFORM_STATE_BUCKET not set; copy .env.example to .env"; exit 1; }
	cd terraform && terraform init -backend-config=bucket=$(TERRAFORM_STATE_BUCKET) -reconfigure

# Timing helper -- use $(call timed,label,command) to time a block
define timed
	@START=$$(date +%s); \
	$(2); \
	END=$$(date +%s); \
	ELAPSED=$$((END - START)); \
	MINS=$$((ELAPSED / 60)); \
	SECS=$$((ELAPSED % 60)); \
	echo ""; \
	echo "========================================"; \
	echo "  $(1) completed in $${MINS}m $${SECS}s"; \
	echo "========================================"
endef

# APAC
terraform-apac:
	cd terraform && terraform workspace select apac && terraform apply -auto-approve
ansible-apac:
	./scripts/bastion_deploy_ansible_playbooks.sh apac
taint-apac:
	cd terraform && terraform workspace select apac && terraform taint module.public.aws_instance.web_server && terraform taint module.public.aws_instance.mail_server && terraform taint module.public.aws_instance.firewall && terraform taint module.corp.aws_instance.DC && terraform taint module.corp.aws_instance.client_1 && terraform taint module.corp.aws_instance.client_2 && terraform taint module.corp.aws_instance.client_3 && terraform taint module.super_secret.aws_instance.file_server && terraform taint module.super_secret.aws_instance.sql_server && terraform taint module.paw.aws_instance.paw_1 && terraform taint module.paw.aws_instance.paw_2 && terraform taint module.paw.aws_instance.guac && terraform taint module.firewalls.aws_instance.fw_dmz_corp && terraform taint module.firewalls.aws_instance.fw_corp_secret
build-apac:
	$(call timed,build-apac,$(MAKE) terraform-apac && $(MAKE) ansible-apac)
	@./scripts/print_lab_connection_summary.sh apac
destroy-apac: 
	cd terraform && terraform workspace select apac && terraform destroy -auto-approve
re-build-apac:
	$(call timed,re-build-apac,$(MAKE) taint-apac && $(MAKE) terraform-apac && $(MAKE) ansible-apac)
	@./scripts/print_lab_connection_summary.sh apac

# star
terraform-star:
	cd terraform && terraform workspace select star && terraform apply -auto-approve
ansible-star:
	./scripts/bastion_deploy_ansible_playbooks.sh star
taint-star:
	cd terraform && terraform workspace select star && terraform taint module.public.aws_instance.web_server && terraform taint module.public.aws_instance.mail_server && terraform taint module.public.aws_instance.firewall && terraform taint module.corp.aws_instance.DC && terraform taint module.corp.aws_instance.client_1 && terraform taint module.corp.aws_instance.client_2 && terraform taint module.corp.aws_instance.client_3 && terraform taint module.super_secret.aws_instance.file_server && terraform taint module.super_secret.aws_instance.sql_server && terraform taint module.paw.aws_instance.paw_1 && terraform taint module.paw.aws_instance.paw_2 && terraform taint module.paw.aws_instance.guac && terraform taint module.firewalls.aws_instance.fw_dmz_corp && terraform taint module.firewalls.aws_instance.fw_corp_secret
build-star:
	$(call timed,build-star,$(MAKE) terraform-star && $(MAKE) ansible-star)
	@./scripts/print_lab_connection_summary.sh star
destroy-star: 
	cd terraform && terraform workspace select star && terraform destroy -auto-approve
re-build-star:
	$(call timed,re-build-star,$(MAKE) taint-star && $(MAKE) terraform-star && $(MAKE) ansible-star)
	@./scripts/print_lab_connection_summary.sh star

# AMER
terraform-amer:
	cd terraform && terraform workspace select amer && terraform apply -auto-approve
ansible-amer:
	./scripts/bastion_deploy_ansible_playbooks.sh amer
taint-amer:
	cd terraform && terraform workspace select amer && terraform taint module.public.aws_instance.web_server && terraform taint module.public.aws_instance.mail_server && terraform taint module.public.aws_instance.firewall && terraform taint module.corp.aws_instance.DC && terraform taint module.corp.aws_instance.client_1 && terraform taint module.corp.aws_instance.client_2 && terraform taint module.corp.aws_instance.client_3 && terraform taint module.super_secret.aws_instance.file_server && terraform taint module.super_secret.aws_instance.sql_server && terraform taint module.paw.aws_instance.paw_1 && terraform taint module.paw.aws_instance.paw_2 && terraform taint module.paw.aws_instance.guac && terraform taint module.firewalls.aws_instance.fw_dmz_corp && terraform taint module.firewalls.aws_instance.fw_corp_secret
build-amer:
	$(call timed,build-amer,$(MAKE) terraform-amer && $(MAKE) ansible-amer)
	@./scripts/print_lab_connection_summary.sh amer
destroy-amer: 
	cd terraform && terraform workspace select amer && terraform destroy -auto-approve
re-build-amer:
	$(call timed,re-build-amer,$(MAKE) taint-amer && $(MAKE) terraform-amer && $(MAKE) ansible-amer)
	@./scripts/print_lab_connection_summary.sh amer

# EMEA
terraform-emea:
	cd terraform && terraform workspace select emea && terraform apply -auto-approve
ansible-emea:
	./scripts/bastion_deploy_ansible_playbooks.sh emea
taint-emea:
	cd terraform && terraform workspace select emea && terraform taint module.public.aws_instance.web_server && terraform taint module.public.aws_instance.mail_server && terraform taint module.public.aws_instance.firewall && terraform taint module.corp.aws_instance.DC && terraform taint module.corp.aws_instance.client_1 && terraform taint module.corp.aws_instance.client_2 && terraform taint module.corp.aws_instance.client_3 && terraform taint module.super_secret.aws_instance.file_server && terraform taint module.super_secret.aws_instance.sql_server && terraform taint module.paw.aws_instance.paw_1 && terraform taint module.paw.aws_instance.paw_2 && terraform taint module.paw.aws_instance.guac && terraform taint module.firewalls.aws_instance.fw_dmz_corp && terraform taint module.firewalls.aws_instance.fw_corp_secret
build-emea:
	$(call timed,build-emea,$(MAKE) terraform-emea && $(MAKE) ansible-emea)
	@./scripts/print_lab_connection_summary.sh emea
destroy-emea: 
	cd terraform && terraform workspace select emea && terraform destroy -auto-approve
re-build-emea:
	$(call timed,re-build-emea,$(MAKE) taint-emea && $(MAKE) terraform-emea && $(MAKE) ansible-emea)
	@./scripts/print_lab_connection_summary.sh emea

# Test Environment
terraform-test-env:
	cd terraform && terraform workspace select test-env && terraform apply -auto-approve
ansible-test-env:
	./scripts/bastion_deploy_ansible_playbooks.sh test-env --with-linux
build-test-env:
	$(call timed,build-test-env,$(MAKE) terraform-test-env && $(MAKE) ansible-test-env)
	@./scripts/print_lab_connection_summary.sh test-env
destroy-test-env: 
	cd terraform && terraform workspace select test-env && terraform destroy -auto-approve
taint-test-env:
	cd terraform && terraform workspace select test-env && terraform taint module.public.aws_instance.web_server && terraform taint module.public.aws_instance.mail_server && terraform taint module.public.aws_instance.firewall && terraform taint module.corp.aws_instance.DC && terraform taint module.corp.aws_instance.client_1 && terraform taint module.corp.aws_instance.client_2 && terraform taint module.corp.aws_instance.client_3 && terraform taint module.super_secret.aws_instance.file_server && terraform taint module.super_secret.aws_instance.sql_server && terraform taint module.paw.aws_instance.paw_1 && terraform taint module.paw.aws_instance.paw_2 && terraform taint module.paw.aws_instance.guac && terraform taint module.firewalls.aws_instance.fw_dmz_corp && terraform taint module.firewalls.aws_instance.fw_corp_secret
re-build-test-env:
	$(call timed,re-build-test-env,$(MAKE) taint-test-env && $(MAKE) terraform-test-env && $(MAKE) ansible-test-env)
	@./scripts/print_lab_connection_summary.sh test-env


# Helpers
env-usage-report:
	cd terraform && terraform workspace select apac && terraform show
	cd terraform && terraform workspace select star && terraform show
	cd terraform && terraform workspace select amer && terraform show
	cd terraform && terraform workspace select emea && terraform show
	cd terraform && terraform workspace select test-env && terraform show
update-authorised-cidrs: terraform-apac terraform-star terraform-emea terraform-amer terraform-test-env
destroy-all: destroy-apac destroy-star destroy-emea destroy-amer destroy-test-env
