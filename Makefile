### mkpm bootstrap
mkpm_pkg_dir := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

ifndef mkpm_included
ifndef MKPM_DIR
mkpm: 
	@curl https://raw.githubusercontent.com/codextremist/mkpm/refs/heads/master/Makefile > $@
else
mkpm: $(MKPM_DIR)
	@ln -sfn $(MKPM_DIR)/Makefile $@
endif
include mkpm
endif

ifneq ($(filter-out $(mkpm_included_pkgs),$(mkpm_include_pkgs)),)
mkpm_included_pkgs := $(sort $(mkpm_included_pkgs) $(mkpm_include_pkgs))
include $(mkpm_include_pkgs)
endif

mkpm_bootstraped := true
### mkpm bootstrap
DOCKER_COMPOSE_DIR ?= $(CURDIR)
DOCKER_COMPOSE_FILE ?= $(DOCKER_COMPOSE_DIR)/docker-compose.yml

DOCKER_DOCKERFILE ?= Dockerfile
# All files that this docker image depends on
DOCKER_IMAGE_DEPENDS_ON ?=

__docker_image_deps_file := $(DOCKER_COMPOSE_DIR)/.image-deps
__docker_image_build_file := $(DOCKER_COMPOSE_DIR)/.image-build

DOCKER_NETWORK := docker network
DOCKER_COMPOSE := docker compose -f $(DOCKER_COMPOSE_FILE)
DOCKER := docker run --rm

$(__docker_image_deps_file): $(addprefix $(DOCKER_COMPOSE_DIR)/,$(DOCKER_DOCKERFILE) $(DOCKER_IMAGE_DEPENDS_ON))
	sha256sum $< > $@

$(__docker_image_build_file): $(__docker_image_deps_file)
	sha256sum $< | cut -c1-7 > $@
	DOCKER_COMPOSE_IMAGE_REV="$$(cat $@)" $(DOCKER_COMPOSE) build

docker-network-create: ## Create docker network
	@$(DOCKER_NETWORK) create $(ARGS) 2>/dev/null || true

docker-network-rm: ## Remove docker network
	@$(DOCKER_NETWORK) network rm $(ARGS)

# Docker Compose Build
docker-compose-build: $(__docker_image_build_file)
	DOCKER_COMPOSE_IMAGE_REV="$$(cat $@)" $(DOCKER_COMPOSE) build

# Docker Compose Push
docker-compose-push: ARGS :=
docker-compose-push-include-deps: ARGS := --include-deps
docker-compose-push docker-compose-push-include-deps: $(__docker_image_build_file)
	$(DOCKER_COMPOSE) push $(ARGS)

# Docker Compose Pull
docker-compose-pull: ARGS :=
docker-compose-pull-include-deps: ARGS := --include-deps
docker-compose-pull docker-compose-pull-include-deps:
	$(DOCKER_COMPOSE) pull $(ARGS)

# Docker Compose Up
docker-compose-up: ARGS := 
docker-compose-up-d: ARGS := -d 
docker-compose-up-d: ARGS := -d --remove-orphans
docker-compose-up docker-compose-up-d: docker-network-create $(__docker_image_build_file) ## Run: docker compose up
	@$(DOCKER_COMPOSE) up $(ARGS)

# Docker Compose Down
docker-compose-down: ARGS :=
docker-compose-down-v: ARGS := -v

docker-compose-down-rmi-local: ARGS := --rmi local
docker-compose-down-rmi-local: clean

docker-compose-down-rmi-all: ARGS := --rmi all
docker-compose-down-rmi-all: clean

docker-compose-down-v-rmi-all: ARGS := -v --rmi all
docker-compose-down-v-rmi-all: clean

docker-compose-down-remove-orphans: ARGS := --remove-orphans

docker-compose-down docker-compose-down-v docker-compose-down-rmi-local docker-compose-down-rmi-all docker-compose-down-remove-orphans:
	$(DOCKER_COMPOSE) down $(ARGS)

# Docker Compose Ps
docker-compose-ps: ARGS :=
docker-compose-ps-a: ARGS := --all
docker-compose-ps-filter: ARGS := --filter $(ARGS)

docker-compose-ps docker-compose-ps-a docker-compose-ps-filter:	
	$(DOCKER_COMPOSE) ps $(ARGS)

# Docker Compose Run
docker-compose-run: 
	$(DOCKER_COMPOSE) run $(ARGS)

docker-compose-run-rm:
docker-compose-run-rm:
	$(DOCKER_COMPOSE) run --rm $(ARGS)

# Docker Compose Image
docker-compose-images:
	$(DOCKER_COMPOSE) images

# Docker Compose Logs
docker-compose-logs: ARGS := $(ARGS)
docker-compose-logs-f: ARGS := -f $(ARGS)
docker-compose-logs-until: ARGS := --until=$(ARGS)
docker-compose-logs docker-compose-logs-f docker-compose-logs-until:
	$(DOCKER_COMPOSE) logs $(ARGS)

# Docker Images
docker-images-format: ARGS := --format $(or $(ARGS),'{{.Repository}}:{{.Tag}}')
docker-images-format:
	docker images $(ARGS)

docker-images-format-f: ARGS_0 := --format $(or $(ARGS_0),'{{.Repository}}:{{.Tag}}')
docker-images-format-f: ARGS_1 := -f $(or $(ARGS_1), "reference=$(DOCKER_COMPOSE_IMAGE_NAME):*") # Default Value
docker-images-format-f:
	docker images $(ARGS_0) $(ARGS_1)

docker-images-rm: ARGS := 
docker-images-rm-f: ARGS := -f $(ARGS)
docker-images-rm docker-images-rm-f:	
	docker image rm $(ARGS)

clean:
	@rm -f $(__docker_image_build_file) $(__docker_image_deps_file)