ifneq (,)
.error This Makefile requires GNU Make.
endif

.PHONY: help lint galaxy test _lint-ansible-syntax _lint-ansible-lint _lint-yamllint _lint-pycodestyle

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
	@$(MAKE) --no-print-directory _lint-ansible-syntax
	@$(MAKE) --no-print-directory _lint-ansible-lint
	@$(MAKE) --no-print-directory _lint-yamllint
	@$(MAKE) --no-print-directory _lint-pycodestyle

galaxy:
	@echo "================================================================================"
	@echo "= ANSIBLE-GALAXY"
	@echo "================================================================================"
	docker run --rm \
		-v $(CURRENT_DIR):/data \
		cytopia/ansible:$(ANSIBLE_VERSION) \
		ansible-galaxy install cytopia.cloudformation

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

_lint-yamllint:
	@echo "------------------------------------------------------------"
	@echo "- yamllint"
	@echo "------------------------------------------------------------"
	docker run --rm \
		-v $(CURRENT_DIR):/data/ \
		cytopia/yamllint .

_lint-ansible-syntax: ansible.cfg
	@echo "------------------------------------------------------------"
	@echo "- ansible-playbook --syntax-check"
	@echo "------------------------------------------------------------"
	docker run --rm \
		-w /data/ansible-role-cloudformation \
		-v $(CURRENT_DIR):/data/ansible-role-cloudformation \
		cytopia/ansible:$(ANSIBLE_VERSION) \
		ansible-playbook tests/test.yml -i tests/inventory -vv --syntax-check

_lint-ansible-lint: ansible.cfg
	@echo "------------------------------------------------------------"
	@echo "- ansible-lint"
	@echo "------------------------------------------------------------"
	docker run --rm \
		-w /data/ansible-role-cloudformation \
		-v $(CURRENT_DIR):/data/ansible-role-cloudformation \
		cytopia/ansible-lint -v tests/test.yml

_lint-pycodestyle:
	@echo "------------------------------------------------------------"
	@echo "- pycodestyle"
	@echo "------------------------------------------------------------"
	docker run --rm \
		-v $(CURRENT_DIR):/data/ \
		cytopia/pycodestyle -v .
