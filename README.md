# aws-setup

## Description

The aim of this project is to create a fully automated aws setup for running web apps

Currently, the iam setup is being worked on.

Initial goals are to setup managed policies for with superuser and developer level access
for logical collection of services provided by aws
  - analytics
  - application
  - compute
  - database
  - log
  - messaging
  - networking
  - storage and filesystem

Also setup separate groups that users can belong to
  - account admin
  - developer
  - superuser
  - group admin
  - user admin

Also a separate group for each of the service cluster mentioned above with superuser and developer level permissions
  - analytics-superuser-group
  - application-superuser-group
  - compute-superuser-group
  - database-superuser-group
  - log-superuser-group
  - messaging-superuser-group
  - networking-superuser-group
  - storage-and-fs-superuser-group

  - analytics-developer-group
  - application-developer-group
  - compute-developer-group
  - database-developer-group
  - log-developer-group
  - messaging-developer-group
  - networking-developer-group
  - storage-and-fs-developer-group

  The managed policies are tied to the various service cluster groups and the superuser and developer groups
  The account admin is only in charge of account level stuff like billing payments etc.
  The user admin can manage users and the group admin can manage groups
  The developer has quite a lot of priviledges. They can create most stacks.
  The superuser has higher access to aws services than developers.

  Make sure you have deleted the access keys of your root user.

  A more detailed view of this setup will be provided later.

### Pre-requirements
1. AWS credentials

    Export your aws credentials on your shell like so

    ```shell
    export AWS_ACCESS_KEY_ID="<your aws access key id>"
    export AWS_SECRET_ACCESS_KEY="<your aws secret access key>"
    export AWS_ACCESS_KEY="$AWS_ACCESS_KEY_ID"
    export AWS_SECRET_KEY="$AWS_SECRET_ACCESS_KEY"
    export AWS_ACCOUNT_ID="<your aws account id>"
    ```

2. Set up dependencies:

    There's a few system level dependencies which needs to be installed.
    They are
    - jq
    - awscli

    For a mac, if you have homebrew installed already you can install the dependencies like so
    ```shell
    [[ "$(uname -s)" =~ Darwin && -z "$(command -v jq)" ]] && brew install jq
    [[ "$(uname -s)" =~ Darwin && -z "$(command -v awscli)" ]] && brew install awscli
    # xargs is also a system level dependency, which hopefully you already have installed.
    ```
    For Linux, you can install jq from source and awscli from pip. Or you can also try linuxbrew.

    Assuming the system dependencies are already met, you will have to create a virtualenv for installing the python dependencies.
    And then install the project dependencies using a make target.
    ```shell
    mkvirtualenv aws-setup
    make deps
    ```

### Development

1. For running the tests

    As of now the tests simply check the fiollowing
    - that your cloudformation templates are valid
    - and you ansible playbook is valid

    ```shell
    make test
    ```

2. To setup the aws setup

    ```shell
    make build AWS_REGION=<valid aws region> FIRST_PASSWORD=<first password for users>
    ```

3. To teardown the aws setup

    ```shell
    make teardown AWS_REGION=<valid aws region>
    ```

### For contributing
  - Make sure the playbooks run
  - Make sure you can build and teardown
  - Make sure if you keep updating the readme
