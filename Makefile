##########################################################################################
## Functions

rfind = $(shell find '$(1)' -path '$(2)')
uname_s = $(shell uname -s)
get_os = $(if $(findstring Darwin,$(call uname_s)),MAC,LINUX)

##########################################################################################
## Variables

CURRENT_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
VIRTUALENV_NAME := $(shell pyenv virtualenvs | grep '\*' | cut -f2 -d ' ')

DEBUG := off
AT_off :=
AT_on := @
AT = $(AT_$(DEBUG))

IAM_CF_FILES := $(call rfind,ansible/roles,iam*/files/[^.]*.json)
IAM_TASK_FILES := $(call rfind,ansible/roles,iam*/tasks/[^.]*.yml)
IAM_VAR_FILES := $(call rfind,ansible/roles,iam*/vars/[^.]*.yml) \
	$(call rfind,ansible/group_vars, *)

VPC_CF_FILES := $(call rfind,ansible/roles,vpc*/files/[^.]*.json)
VPC_TASK_FILES := $(call rfind,ansible/roles,vpc*/tasks/[^.]*.yml)
VPC_VAR_FILES := $(call rfind,ansible/roles,vpc*/vars/[^.]*.yml) \
	$(call rfind,ansible/group_vars, *)

SG_CF_FILES := $(call rfind,ansible/roles,security*/files/[^.]*.json)
SG_TASK_FILES := $(call rfind,ansible/roles,security*/tasks/[^.]*.yml)
SG_VAR_FILES := $(call rfind,ansible/roles,security*/vars/[^.]*.yml) \
	$(call rfind,ansible/group_vars, *)

EC2_CF_FILES := $(call rfind,ansible/roles,bastion*/files/[^.]*.json) \
	$(call rfind,ansible/roles,ec2*/files/[^.]*.json)
EC2_TASK_FILES := $(call rfind,ansible/roles,bastion*/tasks/[^.]*.yml) \
	$(call rfind,ansible/roles,ec2*/tasks/[^.]*.yml)
EC2_VAR_FILES := $(call rfind,ansible/roles,ec2*/vars/[^.]*.yml) \
	$(call rfind,ansible/roles,bastion*/vars/[^.]*.yml) \
	$(call rfind,ansible/group_vars, *)

DEPS_STATEFILE = .make/done_deps

OS := $(call get_os)

FIRST_PASSWORD ?= $(shell echo $$FIRST_PASSWORD)

##########################################################################################
## Public targets

.DEFAULT_GOAL := deps
.PHONY : deps \
	test_iam \
	build_iam \
	teardown_iam \
	test_vpc \
	build_vpc \
	teardown_vpc \
	test_sg \
	build_sg \
	teardown_sg \
	test_ec2 \
	build_ec2 \
	teardown_ec2 \
	clean \
	help

deps: $(DEPS_STATEFILE)

test_iam: deps $(IAM_CF_FILES) $(IAM_VAR_FILES) $(IAM_TASK_FILES)
	$(AT)echo $(IAM_CF_FILES) | xargs -n 1 -I {} aws cloudformation validate-template --template-body file:///$$(pwd)/{} | jq -r .
	$(AT)./bin/run.py iam --region=us-west-2 --first-password=noop --key-name=noop --dry-run

build_iam: test_iam $(IAM_CF_FILES) $(IAM_VAR_FILES) $(IAM_TASK_FILES) ansible/build_iam.yml
	$(AT)[[ ! -z "$(AWS_REGION)" ]] || exit 1
	$(AT)./bin/run.py iam --region=$(AWS_REGION) --first-password=$(FIRST_PASSWORD) --key-name=$(KEY_NAME)

teardown_iam: test_iam $(IAM_CF_FILES) $(IAM_VAR_FILES) $(IAM_TASK_FILES) ansible/teardown_iam.yml
	$(AT)[[ ! -z "$(AWS_REGION)" ]] || exit 1
	$(AT)./bin/run.py iam --region=$(AWS_REGION) --first-password=noop --key-name=noop --delete

test_vpc: deps $(VPC_CF_FILES) $(VPC_VAR_FILES) $(VPC_TASK_FILES)
	$(AT)echo $(VPC_CF_FILES) | xargs -n 1 -I {} aws cloudformation validate-template --template-body file:///$$(pwd)/{} | jq -r .
	$(AT)./bin/run.py vpc --region=us-west-2 --dry-run

build_vpc: test_vpc $(VPC_CF_FILES) $(VPC_VAR_FILES) $(VPC_TASK_FILES) ansible/build_iam.yml
	$(AT)[[ ! -z "$(AWS_REGION)" ]] || exit 1
	$(AT)./bin/run.py vpc --region=$(AWS_REGION)

teardown_vpc: test_vpc $(VPC_CF_FILES) $(VPC_VAR_FILES) $(VPC_TASK_FILES) ansible/teardown_iam.yml
	$(AT)[[ ! -z "$(AWS_REGION)" ]] || exit 1
	$(AT)./bin/run.py vpc --region=$(AWS_REGION) --delete

test_sg: deps $(SG_CF_FILES) $(SG_VAR_FILES) $(SG_TASK_FILES)
	$(AT)echo $(SG_CF_FILES) | xargs -n 1 -I {} aws cloudformation validate-template --template-body file:///$$(pwd)/{} | jq -r .
	$(AT)./bin/run.py sg --region=us-west-2 --dry-run

build_sg: test_ec2 $(SG_CF_FILES) $(SG_VAR_FILES) $(SG_TASK_FILES) ansible/build_iam.yml
	$(AT)[[ ! -z "$(AWS_REGION)" ]] || exit 1
	$(AT)./bin/run.py sg --region=$(AWS_REGION)

teardown_sg: test_iam $(SG_CF_FILES) $(SG_VAR_FILES) $(SG_TASK_FILES) ansible/teardown_iam.yml
	$(AT)[[ ! -z "$(AWS_REGION)" ]] || exit 1
	$(AT)./bin/run.py sg --region=$(AWS_REGION) --delete

test_ec2: deps $(EC2_CF_FILES) $(EC2_VAR_FILES) $(EC2_TASK_FILES)
	$(AT)echo $(EC2_CF_FILES) | xargs -n 1 -I {} aws cloudformation validate-template --template-body file:///$$(pwd)/{} | jq -r .
	$(AT)./bin/run.py ec2 --region=us-west-2 --key-name=noop --dry-run

build_ec2: test_ec2 $(EC2_CF_FILES) $(EC2_VAR_FILES) $(EC2_TASK_FILES) ansible/build_iam.yml
	$(AT)[[ ! -z "$(AWS_REGION)" ]] || exit 1
	$(AT)./bin/run.py ec2 --region=$(AWS_REGION) --key-name=$(KEY_NAME)

teardown_ec2: test_iam $(EC2_CF_FILES) $(EC2_VAR_FILES) $(EC2_TASK_FILES) ansible/teardown_iam.yml
	$(AT)[[ ! -z "$(AWS_REGION)" ]] || exit 1
	$(AT)./bin/run.py ec2 --region=$(AWS_REGION) --key-name=noop --delete

clean:
	$(AT)rm -rf .make

help :
	echo make deps
	echo make test_iam
	echo make build_iam
	echo make teardown_iam
	echo make test_vpc
	echo make build_vpc AWS_REGION=us-west-1
	echo make teardown_vpc AWS_REGION=us-west-1
	echo make test_sg
	echo make build_sg AWS_REGION=us-west-1
	echo make teardown_sg AWS_REGION=us-west-1
	echo make test_ec2
	echo make build_ec2 AWS_REGION=us-west-1 KEY_NAME=bastion-key
	echo make teardown_ec2 AWS_REGION=us-west-1 KEY_NAME=bastion-key
	echo make clean
	echo make help

##########################################################################################
## Plumbing

$(DEPS_STATEFILE) : .env requirements.txt
	mkdir -p .make
	$(AT)[[ ! -z "$$VIRTUAL_ENV" ]] || exit 1
	pip install -r requirements.txt
	touch $(DEPS_STATEFILE)
