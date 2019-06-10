ifneq (,)
.error This Makefile requires GNU Make.
endif

.PHONY: help lint galaxy test _lint_yaml _lint_syntax _lint_ansible

CURRENT_DIR     = $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
ANSIBLE_VERSION = 2.5

help:
	@echo "lint       Static source code analysis"
	@echo "galaxy     Try to fetch role from Ansible galaxy"
	@echo "test       Integration tests"

lint:
	@echo "================================================================================"
	@echo "= LINTING"
	@echo "================================================================================"
	@$(MAKE) --no-print-directory _lint_yaml
	@$(MAKE) --no-print-directory _lint_syntax
	@$(MAKE) --no-print-directory _lint_ansible

galaxy:
	@echo "================================================================================"
	@echo "= ANSIBLE-GALAXY"
	@echo "================================================================================"
	$(eval ROLE_VERSION := $(shell git describe --abbrev=0 --tags))
	docker run --rm \
		-v $(CURRENT_DIR):/data \
		cytopia/ansible:$(ANSIBLE_VERSION) \
		ansible-galaxy install cytopia.cloudformation,$(ROLE_VERSION)

test: ansible.cfg
	@echo "================================================================================"
	@echo "= TESTING"
	@echo "================================================================================"
	docker run --rm \
		-w /data/ansible-role-cloudformation \
		-v $(CURRENT_DIR):/data/ansible-role-cloudformation \
		cytopia/ansible:$(ANSIBLE_VERSION) \
		ansible-playbook tests/test.yml -i tests/inventory -vv -e cloudformation_generate_only=True
	docker run --rm \
		-w /data/ansible-role-cloudformation \
		-v $(CURRENT_DIR):/data/ansible-role-cloudformation \
		cytopia/ansible:$(ANSIBLE_VERSION) \
		test -f build/stack-1.yml.j2-stack-1.yml

ansible.cfg:
	printf '[defaults]\nroles_path=../' > ansible.cfg

_lint_yaml:
	@echo "------------------------------------------------------------"
	@echo "- yamllint"
	@echo "------------------------------------------------------------"
	docker run --rm \
		-v $(CURRENT_DIR):/data/ \
		cytopia/yamllint .

_lint_syntax: ansible.cfg
	@echo "------------------------------------------------------------"
	@echo "- ansible-playbook --syntax-check"
	@echo "------------------------------------------------------------"
	docker run --rm \
		-w /data/ansible-role-cloudformation \
		-v $(CURRENT_DIR):/data/ansible-role-cloudformation \
		cytopia/ansible:$(ANSIBLE_VERSION) \
		ansible-playbook tests/test.yml -i tests/inventory -vv --syntax-check

_lint_ansible: ansible.cfg
	@echo "------------------------------------------------------------"
	@echo "- ansible-lint"
	@echo "------------------------------------------------------------"
	docker run --rm \
		-w /data/ansible-role-cloudformation \
		-v $(CURRENT_DIR):/data/ansible-role-cloudformation \
		cytopia/ansible-lint \
		ansible-lint -vv tests/test.yml
