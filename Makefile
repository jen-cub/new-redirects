
.EXPORT_ALL_VARIABLES:

NAMESPACE := nginx-ingress

DEFAULT_OWNER := jencub@gmail.com

DEV_CLUSTER ?= testrc
DEV_PROJECT ?= jendevops1
DEV_ZONE ?= australia-southeast1-c

YAMLLINT := $(shell command -v yamllint 2> /dev/null)
JQ := $(shell command -v jq 2> /dev/null)

lint: lint-json

lint-yaml:
ifdef YAMLLINT
	@find . -type f -name '*.yml' | xargs $(YAMLLINT)
	@find . -type f -name '*.yaml' | xargs $(YAMLLINT)
else
	$(warning "WARNING :: yamllint is not installed: https://github.com/adrienverge/yamllint")
endif

lint-json:
ifdef JQ
	@find . -type f -name '*.json' | xargs $(JQ) .
else
	$(warning "WARNING :: jq is not installed: https://stedolan.github.io/jq/")
endif

list:
	kubectl -n $(NAMESPACE) get ingress -l app=redirects

clean:
	@rm -fr ingress

devingress:
	@mkdir -p ingress
	@./go.sh dev.sites.json

prodingress:
	@mkdir -p ingress
	@./go.sh prod.sites.json

devprep: lint clean devingress lint-yaml

prodprep: lint clean prodingress lint-yaml

dev: devprep
ifndef CI
	$(error This is intended to be deployed via CI, please commit and push)
endif
	gcloud config set project $(DEV_PROJECT)
	gcloud container clusters get-credentials $(DEV_CLUSTER) --zone $(DEV_ZONE) --project $(DEV_PROJECT)
	kubectl -n $(NAMESPACE) apply -f ingress/

prod: prodprep
ifndef CI
	$(error This is intended to be deployed via CI, please commit and push)
endif
	gcloud config set project $(PROD_PROJECT)
	gcloud container clusters get-credentials $(PROD_PROJECT) --zone $(PROD_ZONE) --project $(PROD_PROJECT)
	kubectl -n $(NAMESPACE) apply -f ingress/

destroy: lint connect
	kubectl -n $(NAMESPACE) delete -f ingress/
