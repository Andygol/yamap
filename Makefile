# based on template from https://www.thapaliya.com/en/writings/well-documented-makefiles/
# https://makefiletutorial.com/#commands-and-execution

.DEFAULT_GOAL:=help
SHELL:=/bin/bash

##@ Run/Stop Services

.PHONY:
run:  ## Builds, (re)creates, starts containers for a service
	$(info Running containers )
	@docker compose up --detach 

.PHONY:
start:  ## Starts existing containers for a service
	$(info Satrting running containers )
	@docker compose start

.PHONY:
stop:  ## Stops running containers without removing them
	$(info Stopping running containers )
	@docker compose stop

.PHONY:
restart:  ## Restarts all stopped and running services
	$(info Restarting containers )
	@docker compose restart

##@ Cleanup

.PHONY:
destroy:  ## Stop and remove containers, networks
	$(info Destroying existing containers )
	@docker compose down

.PHONY:
clean-apidb:  ## Cleaning of the mounted DB file system
	$(info Cleaning up DB folder )
	@find data/apidb -mindepth 1 -type f -not -name '.empty' -delete

.PHONY:
clean-data:  ## Cleaning the data folder except for the mounted DB file system
	$(info Cleaning up data folder )
	@find data -mindepth 1 -path 'data/apidb' -prune -o ! -path 'data/apidb/*' -not -name '.empty' -delete

.PHONY:
clean-db:  ## TODO Cleaning up DB for fresh deployment
	$(info Cleaning up DB without destroying mounted filesystem )

##@ Building

.PHONY:
rebuild:  ## Build or rebuild services if you change a service’s Dockerfile
	$(info Re-building and running containers )
	@docker compose build 

.PHONY:
init-db:  ## Init fresh DB and populate extract
	$(info DB initialization )
	@docker compose -f docker-compose.yml -f docker-compose.init.yml up --detach

.PHONY:
debug:  ## Start services in debug mode to run commands manually
	$(info Running apitools debug shell )
	@docker compose -f docker-compose.yml -f docker-compose.debug.yml up --detach

##@ Helpers

.PHONY:
list:  ## List containers
	$(info Showing list of containers )
	@docker compose ps

.PHONY:
images:  ## List images used by the created containers
	$(info Showing list of images )
	@docker compose images

.PHONY:
config:  ## Parse, resolve and render compose file in canonical format
	$(info Showing docker compose config )
	@docker compose config

##@ Help
.PHONY:
help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} \
	/^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2 } \
	/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
