# Extremely simple HTTP server that responds on port 8000 with a hello message.

DOCKER_HUB_ID ?= ibmosquito
SERVICE_NAME ?= web-hello-python
SERVICE_VERSION ?= 1.0.0
PATTERN_NAME ?= pattern-web-hello-python
ARCH ?= amd64
MATCH ?= "Hello"
TIME_OUT ?= 30

# Leave blank for open DockerHub containers
# CONTAINER_CREDS:=-r "registry.wherever.com:myid:mypw"
CONTAINER_CREDS ?=

default: build run

build:
	docker build -t $(DOCKER_HUB_ID)/$(SERVICE_NAME):$(SERVICE_VERSION) .

dev: stop build
	docker run -it -v `pwd`:/outside \
          --name ${SERVICE_NAME} \
          -p 8000:8000 \
          $(DOCKER_HUB_ID)/$(SERVICE_NAME):$(SERVICE_VERSION) /bin/bash

run: stop
	docker run -d \
          --name ${SERVICE_NAME} \
          --restart unless-stopped \
          -p 8000:8000 \
          $(DOCKER_HUB_ID)/$(SERVICE_NAME):$(SERVICE_VERSION)

check-syft:
	@echo "=================="
	@echo "Generating SBoM syft-output file..."
	@echo "=================="
	syft $(DOCKER_HUB_ID)/$(SERVICE_NAME):$(SERVICE_VERSION) > syft-output
	cat syft-output

# add SBOM for the source code 
check-grype:
	grype $(DOCKER_HUB_ID)/$(SERVICE_NAME):$(SERVICE_VERSION) > grype-output
	cat grype-output

sbom-policy-gen:
	@echo "=================="
	@echo "Generating service.policy.json file..."
	@echo "=================="
	./sbom-property-gen.sh

publish-service-policy:
	hzn exchange service addpolicy -f service.policy.json $(HZN_ORG_ID)/$(SERVICE_NAME)_$(SERVICE_VERSION)_$(ARCH)

publish-deployment-policy:
	hzn exchange deployment addpolicy -f deployment.policy.json $(HZN_ORG_ID)/policy-$(SERVICE_NAME)_$(SERVICE_VERSION)

test: run
	@echo "=================="
	@echo "Testing $(SERVICE_NAME)..."
	@echo "=================="
	./serviceTest.sh $(SERVICE_NAME) $(MATCH) $(TIME_OUT) && \
		{ docker rm -f ${SERVICE_NAME} >/dev/null; \
		echo "*** Service test succeeded! ***"; } || \
		{ docker rm -f ${SERVICE_NAME} >/dev/null; \
		echo "*** Service test failed! ***"; \
		false ;}


push:
	docker push $(DOCKER_HUB_ID)/$(SERVICE_NAME):$(SERVICE_VERSION) 

publish-service:
	@ARCH=$(ARCH) \
        SERVICE_NAME="$(SERVICE_NAME)" \
        SERVICE_VERSION="$(SERVICE_VERSION)"\
        SERVICE_CONTAINER="$(DOCKER_HUB_ID)/$(SERVICE_NAME):$(SERVICE_VERSION)" \
        hzn exchange service publish -O $(CONTAINER_CREDS) -f service.json --pull-image

publish-pattern:
	@ARCH=$(ARCH) \
        SERVICE_NAME="$(SERVICE_NAME)" \
        SERVICE_VERSION="$(SERVICE_VERSION)"\
        PATTERN_NAME="$(PATTERN_NAME)" \
	hzn exchange pattern publish -f pattern.json

stop:
	@docker rm -f ${SERVICE_NAME} >/dev/null 2>&1 || :

clean:
	@docker rmi -f $(DOCKER_HUB_ID)/$(SERVICE_NAME):$(SERVICE_VERSION) >/dev/null 2>&1 || :

agent-run: agent-stop
	@hzn register --pattern "${HZN_ORG_ID}/$(PATTERN_NAME)"

agent-stop:
	@hzn unregister -f

deploy-check:
	@hzn deploycheck all -t device -B deployment.policy.json --service-pol=service.policy.json --node-pol=node.policy.json

.PHONY: build dev run push publish-service publish-pattern test stop clean agent-run agent-stop
