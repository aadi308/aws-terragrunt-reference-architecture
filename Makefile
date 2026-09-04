SHELL := /usr/bin/env bash

.PHONY: fmt fmt-check validate lint security secrets check

fmt:
	terraform fmt -recursive
	terragrunt hcl fmt

fmt-check:
	terraform fmt -check -recursive
	terragrunt hcl fmt --check

validate:
	@for module in modules/*; do \
		echo "Validating $$module"; \
		terraform -chdir="$$module" init -backend=false >/dev/null; \
		terraform -chdir="$$module" validate; \
	done

lint:
	tflint --init
	tflint --recursive

security:
	checkov --config-file .checkov.yml

secrets:
	gitleaks detect --source . --no-git --redact

check: fmt-check validate lint security secrets

