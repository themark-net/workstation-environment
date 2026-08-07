SHELL := /bin/bash
TF    := $(shell command -v tofu 2>/dev/null || command -v terraform)
ANSIBLE := ansible-playbook
TFDIR := terraform
ANDIR := ansible

.PHONY: help tf-init tf-plan tf-apply tf-destroy inventory wait-ssh \
	ansible-bootstrap ansible-lab ansible-mvp ansible-spire validate docker-up docker-down

help:
	@echo "LTZ Lab: tf-init tf-plan tf-apply tf-destroy inventory wait-ssh"
	@echo "         ansible-bootstrap ansible-lab ansible-mvp ansible-spire validate"
	@echo "MVP path: make tf-apply && make wait-ssh && make ansible-mvp && make validate"

tf-init:
	cd $(TFDIR) && $(TF) init

tf-plan:
	cd $(TFDIR) && $(TF) plan

tf-apply:
	cd $(TFDIR) && $(TF) apply -auto-approve
	$(MAKE) inventory

tf-destroy:
	cd $(TFDIR) && $(TF) destroy -auto-approve

inventory:
	./scripts/tf-to-inventory.sh

wait-ssh:
	./scripts/wait-ssh.sh

ansible-bootstrap:
	$(ANSIBLE) -i $(ANDIR)/inventory/hosts.yml $(ANDIR)/playbooks/bootstrap.yml

ansible-lab:
	$(ANSIBLE) -i $(ANDIR)/inventory/hosts.yml $(ANDIR)/playbooks/site.yml

ansible-mvp:
	$(ANSIBLE) -i $(ANDIR)/inventory/hosts.yml $(ANDIR)/playbooks/mvp.yml

ansible-spire:
	$(ANSIBLE) -i $(ANDIR)/inventory/hosts.yml $(ANDIR)/playbooks/spire.yml

validate:
	./scripts/validate-poc.sh

docker-up:
	cd docker && docker compose up -d

docker-down:
	cd docker && docker compose down -v
