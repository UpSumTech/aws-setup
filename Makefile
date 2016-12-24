##########################################################################################
## Functions

rfind = $(shell find '$(1)' -path '$(2)')
uname_s = $(shell uname -s)
get_os = $(if $(findstring Darwin,$(call uname_s)),MAC,LINUX)

##########################################################################################
## Variables

CURRENT_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
VIRTUALENV_NAME := $(shell cat .env | cut -d' ' -f2)

DEBUG := off
AT_off :=
AT_on := @
AT = $(AT_$(DEBUG))

TASK_FILES := $(call rfind,ansible/roles,**/tasks/[^.]*.yml)
CF_FILES := $(call rfind,ansible/roles,**/files/[^.]*.json)
VAR_FILES := $(call rfind,ansible/roles,**/vars/[^.]*.yml) \
	$(call rfind,ansible/group_vars, *)

DEPS_STATEFILE = .make/done_deps

OS := $(call get_os)

##########################################################################################
## Public targets

.DEFAULT_GOAL := deps
.PHONY : deps test build teardown clean help

deps: $(DEPS_STATEFILE)

test: deps $(CF_FILES)
	$(AT)echo $(CF_FILES) | xargs -n 1 -I {} aws cloudformation validate-template --template-body file:///$$(pwd)/{} | jq -r .
	$(AT)./bin/run.py iam --region=$(AWS_REGION) --first-password=$(FIRST_PASSWORD) --dry-run

build: test $(TASK_FILES) $(CF_FILES) $(VAR_FILES) ansible/main.yml
	$(AT)[[ ! -z "$(AWS_REGION)" ]] || exit 1
	$(AT)./bin/run.py iam --region=$(AWS_REGION) --first-password=$(FIRST_PASSWORD)

teardown: test $(TASK_FILES) $(CF_FILES) $(VAR_FILES) ansible/main.yml
	$(AT)[[ ! -z "$(AWS_REGION)" ]] || exit 1
	$(AT)./bin/run.py iam --region=$(AWS_REGION) --first-password=$(FIRST_PASSWORD) --delete

clean:
	$(AT)rm -rf .make

help :
	echo make deps
	echo make build
	echo make clean
	echo make help

##########################################################################################
## Plumbing

$(DEPS_STATEFILE) : .env requirements.txt
	mkdir -p .make
	$(AT)[[ ! -z "$$VIRTUAL_ENV" ]] || exit 1
	pip install -r requirements.txt
	touch $(DEPS_STATEFILE)
