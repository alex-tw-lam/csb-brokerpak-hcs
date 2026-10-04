PAK_NAME := $(shell awk '/^name:/{print $$2; exit}' manifest.yml)
PAK_VERSION := $(shell awk '/^version:/{print $$2; exit}' manifest.yml)
PAK := $(PAK_NAME)-$(PAK_VERSION).brokerpak

RUN_CSB ?= go run github.com/cloudfoundry/cloud-service-broker/v2

PAK_BUILD_CACHE_PATH ?= $(shell pwd)/.pak-cache

BIN_STAGED := bin/tofu_1.11.8_linux_amd64/tofu \
	bin/terraform-provider-hcs_2.4.28_linux_amd64/terraform-provider-hcs_v2.4.28 \
	bin/terraform-provider-random_3.9.0_linux_amd64/terraform-provider-random_v3.9.0

TF_FILES := $(shell find terraform -name '*.tf' 2>/dev/null)

# Sample plans for services whose sizing values are site-specific.
# csb-hcs-rds-postgresql and csb-hcs-gaussdb ship inline plans (see their ymls) that this
# environment variable can override; only csb-hcs-elb requires plans via environment.
export GSB_SERVICE_CSB_HCS_ELB_PLANS ?= [{"name":"default","id":"1d1c9366-6f51-4f51-8eb0-6a1a29f36c1e","description":"Default ELB plan","display_name":"default","l4_flavor_id":"CHANGE_ME","l7_flavor_id":"CHANGE_ME"}]

BROKER_GO_OPTS := \
	DB_TYPE=sqlite3 DB_PATH=/tmp/csb-hcs.db \
	SECURITY_USER_NAME=user SECURITY_USER_PASSWORD=pass \
	CSB_LISTENER_HOST=localhost \
	PAK_BUILD_CACHE_PATH=$(PAK_BUILD_CACHE_PATH)

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "%-30s %s\n", $$1, $$2}'

.PHONY: fetch-binaries
fetch-binaries: ## Stage tofu and provider zips into ./bin (requires internet)
	scripts/fetch-binaries.sh

.PHONY: gen-config
gen-config: ## Generate hcs-broker.yaml and example tfvars from config/site-values.yaml
	python3 scripts/gen-config.py

$(PAK): manifest.yml $(wildcard hcs-*.yml) $(TF_FILES) $(BIN_STAGED)
	$(BROKER_GO_OPTS) $(RUN_CSB) pak build

$(BIN_STAGED):
	scripts/fetch-binaries.sh

.PHONY: build
build: $(PAK) ## Build the brokerpak (offline once ./bin is staged)

.PHONY: validate
validate: build ## Validate the built brokerpak
	$(BROKER_GO_OPTS) $(RUN_CSB) pak validate $(PAK)

.PHONY: info
info: build ## Show brokerpak metadata
	$(BROKER_GO_OPTS) $(RUN_CSB) pak info $(PAK)

.PHONY: docs
docs: build ## Generate brokerpak user docs
	$(BROKER_GO_OPTS) $(RUN_CSB) pak docs $(PAK) > brokerpak-user-docs.md

.PHONY: test
test: lint run-integration-tests ## Run lint and integration tests

.PHONY: run-integration-tests
run-integration-tests: ## Run broker integration tests (mock Terraform, no HCS required)
	cd integration-tests && go tool ginkgo -r .

.PHONY: lint
lint: checkgoformat checkgoimports checktfformat vet staticcheck ## Run all linters

.PHONY: checkgoformat
checkgoformat:
	@files=$$(gofmt -l tools integration-tests); if [ -n "$$files" ]; then echo "gofmt required on:"; echo "$$files"; exit 1; fi

.PHONY: checkgoimports
checkgoimports:
	@files=$$(find tools integration-tests -name '*.go' -exec go tool goimports -l {} +); if [ -n "$$files" ]; then echo "goimports required on:"; echo "$$files"; exit 1; fi

.PHONY: checktfformat
checktfformat:
	tofu fmt -check -recursive terraform

.PHONY: vet
vet:
	go vet ./tools/... ./integration-tests/...

.PHONY: staticcheck
staticcheck:
	go tool staticcheck ./tools/... ./integration-tests/...

.PHONY: format
format: ## Format Go and Terraform code
	gofmt -w tools integration-tests
	go tool goimports -w tools integration-tests
	tofu fmt -recursive terraform

.PHONY: run
run: build ## Build the brokerpak and serve the broker locally (configure HCS_* env first)
	$(BROKER_GO_OPTS) $(RUN_CSB) serve

.PHONY: clean
clean: ## Remove build artifacts
	rm -f $(PAK) brokerpak-user-docs.md
	rm -rf .pak-cache
