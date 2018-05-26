CASK ?= cask
EMACS ?= emacs
VERSION := $(shell EMACS=$(EMACS) $(CASK) version)

PACKAGE = dist/swift-playground-mode-$(VERSION).tar

.PHONY: help
help: ## Print help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' \
	$(MAKEFILE_LIST) | sort

.PHONY: deps
deps: ## Install dependencies.
	$(CASK) install

$(PACKAGE): $(SRC) deps ## no-doc
	rm -rf dist
	$(CASK) package

.PHONY: package
package: $(PACKAGE) ## Build package.

.PHONY: install
install: package ## Install package.
	$(CASK) exec $(EMACS) --batch \
	  -l package \
	  -f package-initialize \
	  -f package-refresh-contents \
	  --eval '(package-install-file "$(PACKAGE)")'

.PHONY: clean
clean: ## Clean package directory.
	rm -rf dist
