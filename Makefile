#############################################################################
#  Description:
#
#  Copyright (c) 2021 Nokia
#############################################################################
this_dir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
uid := $(shell id -u)
gid := $(shell id -g)
word1 = $(word 1,$(subst _, ,$@))
word2 = $(word 2,$(subst _, ,$@))
word3 = $(word 3,$(subst _, ,$@))
word4 = $(word 4,$(subst _, ,$@))
JOBS ?= $(shell nproc)

##########################################
.DEFAULT_GOAL := help

BLDENV ?= buster

.PHONY: help

help = \
"The following targets may be used: \n\
  make all                    ; compile all source and make pkg \n\
  make clean                  ; clean all build objects \n\
  make clobber                ; clobber all build objects \n\
  make bcmsdk_all             ; compile sdk source only \n\
  make bcm-$(BLDENV)             ; Make the base build docker \n\
  make bcm-$(BLDENV)-$$USER      ; Make the local user docker \n\
  \n\
  make pkg_deb                  ; make debian pkg(s) \n\
  make pkg_rpm                  ; make rpm pkg(s) \n\
  \n\
  Envirionment Variables:   Desc:             Default:\n\
  V                         Verbosity         V= \n\
  JOBS                      Jobs in docker    JOBS=$(JOBS)\n\
  \n\
"
help:
	@/bin/echo -e $(help)


##########################################
# jump into a build docker
DOCKER_NAME := bcm$(subst /,_,$(this_dir))
DOCKER_BASE := bcm-$(BLDENV)
DOCKER_USER := bcm-$(BLDENV)-$(USER)
DOCKER_RUN := docker run  -v $(this_dir):/ws --cap-add SYS_MODULE --rm --name $(DOCKER_NAME)
DOCKER_BASE_TAG = $(shell cat build-container/Dockerfile-$(BLDENV) | sha1sum | awk '{print substr($$1,0,11);}')
DOCKER_USER_TAG = $(shell cat build-container/Dockerfile-$(BLDENV) build-container/Dockerfile-user | sha1sum | awk '{print substr($$1,0,11);}')

.PHONY: bash kill $(DOCKER_USER) $(DOCKER_BASE)

Makefile: ;

bash: $(DOCKER_USER)
	@echo "****** Starting docker for $@ ******"
	@$(DOCKER_RUN) -it -w /ws $(DOCKER_USER):$(DOCKER_USER_TAG) bash

kill:
	docker kill $(DOCKER_NAME)

# all other targets are made while in the docker
%: $(DOCKER_USER)
	echo "****** Starting make in docker for target \"$@\" ******"
	$(DOCKER_RUN) -t -w /ws $(DOCKER_USER):$(DOCKER_USER_TAG) \
	  $(MAKE) JOBS=$(JOBS) V=$(V) -f secondary.mk $@


#################################
# DOCKER_BASE
#################################
# We build a base docker that retains root priv.  It will
# be used as the base docker for the DOCKER_USER, user private build docker.
$(DOCKER_BASE):
	@docker inspect $(DOCKER_BASE):$(DOCKER_BASE_TAG) > /dev/null 2>&1 || \
	( echo "****** Building $(DOCKER_BASE):$(DOCKER_BASE_TAG)" && sleep 2 && docker build \
	  --build-arg https_proxy=$(HTTPS_PROXY) --build-arg http_proxy=$(HTTP_PROXY) \
	  --build-arg HTTPS_PROXY=$(HTTPS_PROXY) --build-arg HTTP_PROXY=$(HTTP_PROXY) \
	  --build-arg NO_PROXY=$(NO_PROXY)  --build-arg no_proxy=$(NO_PROXY) \
	  -f build-container/Dockerfile-$(BLDENV) \
	  -t $(DOCKER_BASE):$(DOCKER_BASE_TAG) build-container/ ; )

#################################
# DOCKER_USER
#################################
# This is the user specifc docker.  It is derived from DOCKER_BASE
# above and all it does is make the current uid/gid as the user so that the build
# runs with same permissions as the user.
build-container/Dockerfile-user: ;
.Dockerfile-user: $(DOCKER_BASE) build-container/Dockerfile-user
	cat build-container/Dockerfile-user | \
	sed "s,%DOCKER_BASE_TAG%,$(DOCKER_BASE_TAG),g" | \
	sed "s,%BLDENV%,$(BLDENV),g" > $@

$(DOCKER_USER): $(DOCKER_BASE) .Dockerfile-user
	@docker inspect $(DOCKER_USER):$(DOCKER_USER_TAG) > /dev/null 2>&1  || \
	( echo "****** Building $(DOCKER_USER):$(DOCKER_USER_TAG)" && sleep 2 && docker build \
	--no-cache \
	--build-arg UID=$(uid) --build-arg GID=$(gid) \
	--build-arg https_proxy=$(HTTPS_PROXY) --build-arg http_proxy=$(HTTP_PROXY) \
	--build-arg HTTPS_PROXY=$(HTTPS_PROXY) --build-arg HTTP_PROXY=$(HTTP_PROXY) \
	--build-arg NO_PROXY=$(NO_PROXY)  --build-arg no_proxy=$(NO_PROXY) \
	-f .Dockerfile-user \
	-t $(DOCKER_USER):$(DOCKER_USER_TAG) build-container/ ) ;
	rm -f .Dockerfile-user


$(V).SILENT:
# dependencies

