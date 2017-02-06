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
IAM_CF_FILES := $(call rfind,ansible/roles,iam*/files/[^.]*.json)
IAM_VAR_FILES := $(call rfind,ansible/roles,iam*/vars/[^.]*.yml) \
	$(call rfind,ansible/group_vars, *)

VPC_CF_FILES := $(call rfind,ansible/roles,vpc*/files/[^.]*.json)
VPC_VAR_FILES := $(call rfind,ansible/roles,vpc*/vars/[^.]*.yml) \
	$(call rfind,ansible/group_vars, *)

EC2_CF_FILES := $(call rfind,ansible/roles,ec2*/files/[^.]*.json)
EC2_VAR_FILES := $(call rfind,ansible/roles,ec2*/vars/[^.]*.yml) \
	$(call rfind,ansible/group_vars, *)

DEPS_STATEFILE = .make/done_deps

OS := $(call get_os)

FIRST_PASSWORD ?= $(shell echo $$FIRST_PASSWORD)

##########################################################################################
## Public targets

.DEFAULT_GOAL := deps
.PHONY : deps test_iam build_iam teardown_iam test_ec2 build_ec2 teardown_ec2 clean help

deps: $(DEPS_STATEFILE)

test_iam: deps $(IAM_CF_FILES)
	$(AT)echo $(IAM_CF_FILES) | xargs -n 1 -I {} aws cloudformation validate-template --template-body file:///$$(pwd)/{} | jq -r .
	$(AT)./bin/run.py iam --region=us-west-2 --first-password=noop --key-name=noop --dry-run

build_iam: test_iam $(IAM_CF_FILES) $(IAM_VAR_FILES) ansible/build_iam.yml
	$(AT)[[ ! -z "$(AWS_REGION)" ]] || exit 1
	$(AT)./bin/run.py iam --region=$(AWS_REGION) --first-password=$(FIRST_PASSWORD) --key-name=$(KEY_NAME)

teardown_iam: test_iam $(IAM_CF_FILES) $(IAM_VAR_FILES) ansible/teardown_iam.yml
	$(AT)[[ ! -z "$(AWS_REGION)" ]] || exit 1
	$(AT)./bin/run.py iam --region=$(AWS_REGION) --first-password=noop --key-name=noop --delete

test_vpc: deps $(VPC_CF_FILES)
	$(AT)echo $(VPC_CF_FILES) | xargs -n 1 -I {} aws cloudformation validate-template --template-body file:///$$(pwd)/{} | jq -r .
	$(AT)./bin/run.py vpc --region=us-west-2 --dry-run

build_vpc: test_vpc $(VPC_CF_FILES) $(VPC_VAR_FILES) ansible/build_iam.yml
	$(AT)[[ ! -z "$(AWS_REGION)" ]] || exit 1
	$(AT)./bin/run.py vpc --region=$(AWS_REGION)

teardown_vpc: test_vpc $(VPC_CF_FILES) $(VPC_VAR_FILES) ansible/teardown_iam.yml
	$(AT)[[ ! -z "$(AWS_REGION)" ]] || exit 1
	$(AT)./bin/run.py vpc --region=$(AWS_REGION) --delete

test_ec2: deps $(EC2_CF_FILES)
	$(AT)echo $(EC2_CF_FILES) | xargs -n 1 -I {} aws cloudformation validate-template --template-body file:///$$(pwd)/{} | jq -r .
	$(AT)./bin/run.py ec2 --region=us-west-2 --key-name=noop --dry-run

build_ec2: test_ec2 $(EC2_CF_FILES) $(EC2_VAR_FILES) ansible/build_iam.yml
	$(AT)[[ ! -z "$(AWS_REGION)" ]] || exit 1
	$(AT)./bin/run.py ec2 --region=$(AWS_REGION) --key-name=$(KEY_NAME)

teardown_ec2: test_iam $(EC2_CF_FILES) $(EC2_VAR_FILES) ansible/teardown_iam.yml
	$(AT)[[ ! -z "$(AWS_REGION)" ]] || exit 1
	$(AT)./bin/run.py ec2 --region=$(AWS_REGION) --key-name=noop --delete

clean:
	$(AT)rm -rf .make

help :
	echo make deps
	echo make test_iam
	echo make build_iam
	echo make teardown_iam
	echo make test_ec2
	echo make build_ec2
	echo make teardown_ec2
	echo make clean
	echo make help

##########################################################################################
## Plumbing

$(DEPS_STATEFILE) : .env requirements.txt
	mkdir -p .make
	$(AT)[[ ! -z "$$VIRTUAL_ENV" ]] || exit 1
	pip install -r requirements.txt
	touch $(DEPS_STATEFILE)
