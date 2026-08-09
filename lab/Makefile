SHELL := /bin/bash
TF    := $(shell command -v tofu 2>/dev/null || command -v terraform)
ANSIBLE := ansible-playbook
TFDIR := terraform
ANDIR := ansible
export ANSIBLE_CONFIG := $(CURDIR)/$(ANDIR)/ansible.cfg
export PATH := $(HOME)/.local/bin:$(PATH)

.PHONY: help tf-init tf-plan tf-apply tf-destroy inventory wait-ssh \
	ansible-bootstrap ansible-lab ansible-mvp ansible-intune-prereqs ansible-spire \
	ansible-8021x ansible-site-full validate demo-paths docker-up docker-down

help:
	@echo "LTZ Lab: tf-init tf-plan tf-apply tf-destroy inventory wait-ssh"
	@echo "         ansible-bootstrap ansible-intune-prereqs ansible-lab ansible-mvp"
	@echo "         ansible-8021x ansible-site-full ansible-spire validate demo-paths"
	@echo "Dual path: make ansible-mvp && make demo-paths"
	@echo "802.1X:   make ansible-mvp && make ansible-8021x"
	@echo "Full:     make ansible-site-full   # bootstrap + mvp + 802.1X"
	@echo "  - ticket → device cert (lab CA) → FreeRADIUS EAP-TLS"
	@echo "Client (real/MS hosts): see ../client/README.md + docs/deployment/"

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

ansible-intune-prereqs:
	$(ANSIBLE) -i $(ANDIR)/inventory/hosts.yml $(ANDIR)/playbooks/intune-prereqs.yml

ansible-lab:
	$(ANSIBLE) -i $(ANDIR)/inventory/hosts.yml $(ANDIR)/playbooks/site.yml

ansible-mvp:
	$(ANSIBLE) -i $(ANDIR)/inventory/hosts.yml $(ANDIR)/playbooks/mvp.yml

ansible-8021x:
	$(ANSIBLE) -i $(ANDIR)/inventory/hosts.yml $(ANDIR)/playbooks/network-8021x.yml

ansible-site-full:
	$(ANSIBLE) -i $(ANDIR)/inventory/hosts.yml $(ANDIR)/playbooks/site-full.yml

ansible-spire:
	$(ANSIBLE) -i $(ANDIR)/inventory/hosts.yml $(ANDIR)/playbooks/spire.yml

validate:
	./scripts/validate-poc.sh

demo-paths:
	./scripts/demo-attestation-paths.sh

docker-up:
	cd docker && docker compose up -d

docker-down:
	cd docker && docker compose down -v
