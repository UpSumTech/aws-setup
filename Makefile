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

NAT_CF_FILES := $(call rfind,ansible/roles,nat_routing*/files/[^.]*.json)
NAT_TASK_FILES := $(call rfind,ansible/roles,nat_routing*/tasks/[^.]*.yml)
NAT_VAR_FILES := $(call rfind,ansible/roles,nat_routing*/vars/[^.]*.yml) \
	$(call rfind,ansible/group_vars, *)

SG_CF_FILES := $(call rfind,ansible/roles,security*/files/[^.]*.json)
SG_TASK_FILES := $(call rfind,ansible/roles,security*/tasks/[^.]*.yml)
SG_VAR_FILES := $(call rfind,ansible/roles,security*/vars/[^.]*.yml) \
	$(call rfind,ansible/group_vars, *)

KMS_CF_FILES := $(call rfind,ansible/roles,kms*/files/[^.]*.json)
KMS_TASK_FILES := $(call rfind,ansible/roles,kms*/tasks/[^.]*.yml)
KMS_VAR_FILES := $(call rfind,ansible/roles,kms*/vars/[^.]*.yml) \
	$(call rfind,ansible/group_vars, *)

BASTION_CF_FILES := $(call rfind,ansible/roles,bastion*/files/[^.]*.json)
BASTION_TASK_FILES := $(call rfind,ansible/roles,bastion*/tasks/[^.]*.yml)
BASTION_VAR_FILES := $(call rfind,ansible/roles,bastion*/vars/[^.]*.yml) \
	$(call rfind,ansible/group_vars, *)

EC2_CF_FILES := $(call rfind,ansible/roles,ec2*/files/[^.]*.json)
EC2_TASK_FILES := $(call rfind,ansible/roles,ec2*/tasks/[^.]*.yml)
EC2_VAR_FILES := $(call rfind,ansible/roles,ec2*/vars/[^.]*.yml) \
	$(call rfind,ansible/group_vars, *)

RDS_CF_FILES := $(call rfind,ansible/roles,rds*/files/[^.]*.json)
RDS_TASK_FILES := $(call rfind,ansible/roles,rds*/tasks/[^.]*.yml)
RDS_VAR_FILES := $(call rfind,ansible/roles,rds*/vars/[^.]*.yml) \
	$(call rfind,ansible/group_vars, *)

ELB_CF_FILES := $(call rfind,ansible/roles,elb*/files/[^.]*.json)
ELB_TASK_FILES := $(call rfind,ansible/roles,elb*/tasks/[^.]*.yml)
ELB_VAR_FILES := $(call rfind,ansible/roles,elb*/vars/[^.]*.yml) \
	$(call rfind,ansible/group_vars, *)

ROUTE53_CF_FILES := $(call rfind,ansible/roles,route53*/files/[^.]*.json)
ROUTE53_TASK_FILES := $(call rfind,ansible/roles,route53*/tasks/[^.]*.yml)
ROUTE53_VAR_FILES := $(call rfind,ansible/roles,route53*/vars/[^.]*.yml) \
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

build_iam: test_iam $(IAM_CF_FILES) $(IAM_VAR_FILES) $(IAM_TASK_FILES) ansible/build.yml
	$(AT)test ! -z "$(AWS_REGION)" || exit 1
	$(AT)./bin/run.py iam --region=$(AWS_REGION) --first-password=$(FIRST_PASSWORD) --key-name=$(KEY_NAME)

teardown_iam: test_iam $(IAM_CF_FILES) $(IAM_VAR_FILES) $(IAM_TASK_FILES) ansible/teardown.yml
	$(AT)test ! -z "$(AWS_REGION)" || exit 1
	$(AT)./bin/run.py iam --region=$(AWS_REGION) --first-password=noop --key-name=noop --delete

test_kms: deps $(KMS_CF_FILES) $(KMS_VAR_FILES) $(KMS_TASK_FILES)
	$(AT)echo $(KMS_CF_FILES) | xargs -n 1 -I {} aws cloudformation validate-template --template-body file:///$$(pwd)/{} | jq -r .
	$(AT)./bin/run.py kms --region=us-west-2 --dry-run

build_kms: test_kms $(KMS_CF_FILES) $(KMS_VAR_FILES) $(KMS_TASK_FILES) ansible/build.yml
	$(AT)test ! -z "$(AWS_REGION)" || exit 1
	$(AT)./bin/run.py kms --region=$(AWS_REGION)

teardown_kms: test_kms $(KMS_CF_FILES) $(KMS_VAR_FILES) $(KMS_TASK_FILES) ansible/teardown.yml
	$(AT)test ! -z "$(AWS_REGION)" || exit 1
	$(AT)./bin/run.py kms --region=$(AWS_REGION) --delete

test_vpc: deps $(VPC_CF_FILES) $(VPC_VAR_FILES) $(VPC_TASK_FILES)
	$(AT)echo $(VPC_CF_FILES) | xargs -n 1 -I {} aws cloudformation validate-template --template-body file:///$$(pwd)/{} | jq -r .
	$(AT)./bin/run.py vpc --region=us-west-2 --dry-run

build_vpc: test_vpc $(VPC_CF_FILES) $(VPC_VAR_FILES) $(VPC_TASK_FILES) ansible/build.yml
	$(AT)test ! -z "$(AWS_REGION)" || exit 1
	$(AT)./bin/run.py vpc --region=$(AWS_REGION)

teardown_vpc: test_vpc $(VPC_CF_FILES) $(VPC_VAR_FILES) $(VPC_TASK_FILES) ansible/teardown.yml
	$(AT)test ! -z "$(AWS_REGION)" || exit 1
	$(AT)./bin/run.py vpc --region=$(AWS_REGION) --delete

test_sg: deps $(SG_CF_FILES) $(SG_VAR_FILES) $(SG_TASK_FILES)
	$(AT)echo $(SG_CF_FILES) | xargs -n 1 -I {} aws cloudformation validate-template --template-body file:///$$(pwd)/{} | jq -r .
	$(AT)./bin/run.py sg --region=us-west-2 --dry-run

build_sg: test_sg $(SG_CF_FILES) $(SG_VAR_FILES) $(SG_TASK_FILES) ansible/build.yml
	$(AT)test ! -z "$(AWS_REGION)" || exit 1
	$(AT)./bin/run.py sg --region=$(AWS_REGION)

teardown_sg: test_sg $(SG_CF_FILES) $(SG_VAR_FILES) $(SG_TASK_FILES) ansible/teardown.yml
	$(AT)test ! -z "$(AWS_REGION)" || exit 1
	$(AT)./bin/run.py sg --region=$(AWS_REGION) --delete

test_nat: deps $(NAT_CF_FILES) $(NAT_VAR_FILES) $(NAT_TASK_FILES)
	$(AT)echo $(NAT_CF_FILES) | xargs -n 1 -I {} aws cloudformation validate-template --template-body file:///$$(pwd)/{} | jq -r .
	$(AT)./bin/run.py nat --region=us-west-2 --key-name=noop --dry-run

build_nat: test_nat $(NAT_CF_FILES) $(NAT_VAR_FILES) $(NAT_TASK_FILES) ansible/build.yml
	$(AT)test ! -z "$(AWS_REGION)" || exit 1
	$(AT)./bin/run.py nat --region=$(AWS_REGION) --key-name=$(KEY_NAME)

teardown_nat: test_nat $(NAT_CF_FILES) $(NAT_VAR_FILES) $(NAT_TASK_FILES) ansible/teardown.yml
	$(AT)test ! -z "$(AWS_REGION)" || exit 1
	$(AT)./bin/run.py nat --region=$(AWS_REGION) --key-name=$(KEY_NAME) --delete

test_bastion: deps $(BASTION_CF_FILES) $(BASTION_VAR_FILES) $(BASTION_TASK_FILES)
	$(AT)echo $(BASTION_CF_FILES) | xargs -n 1 -I {} aws cloudformation validate-template --template-body file:///$$(pwd)/{} | jq -r .
	$(AT)./bin/run.py bastion --region=us-west-2 --key-name=noop --dry-run

build_bastion: test_bastion $(BASTION_CF_FILES) $(BASTION_VAR_FILES) $(BASTION_TASK_FILES) ansible/build.yml
	$(AT)test ! -z "$(AWS_REGION)" || exit 1
	$(AT)./bin/run.py bastion --region=$(AWS_REGION) --key-name=$(KEY_NAME)

teardown_bastion: test_bastion $(BASTION_CF_FILES) $(BASTION_VAR_FILES) $(BASTION_TASK_FILES) ansible/teardown.yml
	$(AT)test ! -z "$(AWS_REGION)" || exit 1
	$(AT)./bin/run.py bastion --region=$(AWS_REGION) --key-name=noop --delete

test_rds: deps $(RDS_CF_FILES) $(RDS_VAR_FILES) $(RDS_TASK_FILES)
	$(AT)echo $(RDS_CF_FILES) | xargs -n 1 -I {} aws cloudformation validate-template --template-body file:///$$(pwd)/{} | jq -r .
	$(AT)./bin/run.py rds --db-name='foo' --db-user='bar' --db-password='blah' --db-engine='mysql' --region=us-west-2 --dry-run

build_rds: test_rds $(RDS_CF_FILES) $(RDS_VAR_FILES) $(RDS_TASK_FILES) ansible/build.yml
	$(AT)test ! -z "$(AWS_REGION)" || exit 1
	$(AT)./bin/run.py rds --db-name=$(DB_NAME) --db-user=$(DB_USER) --db-password=$(DB_PASSWORD) --db-engine=$(DB_ENGINE) --region=$(AWS_REGION)

teardown_rds: test_rds $(RDS_CF_FILES) $(RDS_VAR_FILES) $(RDS_TASK_FILES) ansible/teardown.yml
	$(AT)test ! -z "$(AWS_REGION)" || exit 1
	$(AT)./bin/run.py rds --db-name=$(DB_NAME) --db-user=$(DB_USER) --db-password=$(DB_PASSWORD) --db-engine=$(DB_ENGINE) --region=$(AWS_REGION) --delete

test_ec2: deps $(EC2_CF_FILES) $(EC2_VAR_FILES) $(EC2_TASK_FILES)
	$(AT)echo $(EC2_CF_FILES) | xargs -n 1 -I {} aws cloudformation validate-template --template-body file:///$$(pwd)/{} | jq -r .
	$(AT)./bin/run.py ec2 --region=us-west-2 --key-name=noop --dry-run

build_ec2: test_ec2 $(EC2_CF_FILES) $(EC2_VAR_FILES) $(EC2_TASK_FILES) ansible/build.yml
	$(AT)test ! -z "$(AWS_REGION)" || exit 1
	$(AT)./bin/run.py ec2 --region=$(AWS_REGION) --key-name=$(KEY_NAME)

teardown_ec2: test_ec2 $(EC2_CF_FILES) $(EC2_VAR_FILES) $(EC2_TASK_FILES) ansible/teardown.yml
	$(AT)test ! -z "$(AWS_REGION)" || exit 1
	$(AT)./bin/run.py ec2 --region=$(AWS_REGION) --key-name=noop --delete

test_elb: deps $(ELB_CF_FILES) $(ELB_VAR_FILES) $(ELB_TASK_FILES)
	$(AT)echo $(ELB_CF_FILES) | xargs -n 1 -I {} aws cloudformation validate-template --template-body file:///$$(pwd)/{} | jq -r .
	$(AT)./bin/run.py elb --region=us-west-2 --dry-run

build_elb: test_elb $(ELB_CF_FILES) $(ELB_VAR_FILES) $(ELB_TASK_FILES) ansible/build.yml
	$(AT)test ! -z "$(AWS_REGION)" || exit 1
	$(AT)./bin/run.py elb --region=$(AWS_REGION)

teardown_elb: test_elb $(ELB_CF_FILES) $(ELB_VAR_FILES) $(ELB_TASK_FILES) ansible/teardown.yml
	$(AT)test ! -z "$(AWS_REGION)" || exit 1
	$(AT)./bin/run.py elb --region=$(AWS_REGION) --delete

test_route53: deps $(ROUTE53_CF_FILES) $(ROUTE53_VAR_FILES) $(ROUTE53_TASK_FILES)
	$(AT)echo $(ROUTE53_CF_FILES) | xargs -n 1 -I {} aws cloudformation validate-template --template-body file:///$$(pwd)/{} | jq -r .
	$(AT)./bin/run.py route53 --region=us-west-2 --domain=$(ROOT_DOMAIN) --subdomain=$(SUB_DOMAIN) --dry-run

build_route53: test_route53 $(ROUTE53_CF_FILES) $(ROUTE53_VAR_FILES) $(ROUTE53_TASK_FILES) ansible/build.yml
	$(AT)test ! -z "$(AWS_REGION)" || exit 1
	$(AT)./bin/run.py route53 --region=$(AWS_REGION) --domain=$(ROOT_DOMAIN) --subdomain=$(SUB_DOMAIN)

teardown_route53: test_route53 $(ROUTE53_CF_FILES) $(ROUTE53_VAR_FILES) $(ROUTE53_TASK_FILES) ansible/teardown.yml
	$(AT)test ! -z "$(AWS_REGION)" || exit 1
	$(AT)./bin/run.py route53 --region=$(AWS_REGION) --domain=$(ROOT_DOMAIN) --subdomain=$(SUB_DOMAIN) --delete

clean:
	$(AT)rm -rf .make

help :
	echo make deps
	echo make test_iam
	echo make build_iam
	echo make teardown_iam
	echo make test_vpc
	echo make build_vpc AWS_REGION=us-west-2
	echo make teardown_vpc AWS_REGION=us-west-2
	echo make test_sg
	echo make build_sg AWS_REGION=us-west-2
	echo make teardown_sg AWS_REGION=us-west-2
	echo make test_ec2
	echo make build_ec2 AWS_REGION=us-west-2 KEY_NAME=bastion-key
	echo make teardown_ec2 AWS_REGION=us-west-2 KEY_NAME=bastion-key
	echo make test_bastion
	echo make build_bastion AWS_REGION=us-west-2 KEY_NAME=bastion-key
	echo make teardown_bastion AWS_REGION=us-west-1 KEY_NAME=bastion-key
	echo make test_rds
	echo make build_rds AWS_REGION=us-west-2 DB_USER=root DB_PASSWORD=welcome2mysql DB_NAME=sample_webapp DB_ENGINE=mysql
	echo make teardown_rds AWS_REGION=us-west-2 DB_USER=root DB_PASSWORD=welcome2mysql DB_NAME=sample_webapp DB_ENGINE=mysql
	echo make clean
	echo make help

##########################################################################################
## Plumbing

$(DEPS_STATEFILE) : .env requirements.txt
	mkdir -p .make
	$(AT)test ! -z "$$VIRTUAL_ENV" || exit 1
	pip install -r requirements.txt
	touch $(DEPS_STATEFILE)
