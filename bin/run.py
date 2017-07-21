#!/usr/bin/env python

######## Imports ###########

import sys
from docopt import docopt
import os
import json
import time
from tempfile import NamedTemporaryFile
from ansible.parsing.dataloader import DataLoader
from ansible.vars import VariableManager
from ansible.inventory import Inventory
from ansible.executor import playbook_executor

############# Classes required for ansible playbook ###############

class Options(object):
    """
    Options class to replace Ansible OptParser
    """
    def __init__(self, verbosity=None, inventory=None, listhosts=None, subset=None, module_paths=None, extra_vars=None,
                 forks=None, ask_vault_pass=None, vault_password_files=None, new_vault_password_file=None,
                 output_file=None, tags=None, skip_tags=None, one_line=None, tree=None, ask_sudo_pass=None, ask_su_pass=None,
                 sudo=None, sudo_user=None, become=None, become_method=None, become_user=None, become_ask_pass=None,
                 ask_pass=None, private_key_file=None, remote_user=None, connection=None, timeout=None, ssh_common_args=None,
                 sftp_extra_args=None, scp_extra_args=None, ssh_extra_args=None, poll_interval=None, seconds=None, check=None,
                 syntax=None, diff=None, force_handlers=None, flush_cache=None, listtasks=None, listtags=None, module_path=None):
        self.verbosity = verbosity
        self.inventory = inventory
        self.listhosts = listhosts
        self.subset = subset
        self.module_paths = module_paths
        self.extra_vars = extra_vars
        self.forks = forks
        self.ask_vault_pass = ask_vault_pass
        self.vault_password_files = vault_password_files
        self.new_vault_password_file = new_vault_password_file
        self.output_file = output_file
        self.tags = tags
        self.skip_tags = skip_tags
        self.one_line = one_line
        self.tree = tree
        self.ask_sudo_pass = ask_sudo_pass
        self.ask_su_pass = ask_su_pass
        self.sudo = sudo
        self.sudo_user = sudo_user
        self.become = become
        self.become_method = become_method
        self.become_user = become_user
        self.become_ask_pass = become_ask_pass
        self.ask_pass = ask_pass
        self.private_key_file = private_key_file
        self.remote_user = remote_user
        self.connection = connection
        self.timeout = timeout
        self.ssh_common_args = ssh_common_args
        self.sftp_extra_args = sftp_extra_args
        self.scp_extra_args = scp_extra_args
        self.ssh_extra_args = ssh_extra_args
        self.poll_interval = poll_interval
        self.seconds = seconds
        self.check = check
        self.syntax = syntax
        self.diff = diff
        self.force_handlers = force_handlers
        self.flush_cache = flush_cache
        self.listtasks = listtasks
        self.listtags = listtags
        self.module_path = module_path

######### Internal function ###########

def _run_playbook(group, extra_vars={}, dry_run=True):
    """Runs the ansible playbook
    Instead of running ansible as a executable, run ansible through it's API
    """

    #  Initialize objects required for the playbook execution
    variable_manager = VariableManager()
    loader = DataLoader()
    options = Options()

    if extra_vars['stack_status'] == 'absent':
        playbook = os.path.join(os.getcwd(), 'ansible/teardown.yml')
    else:
        playbook = os.path.join(os.getcwd(), 'ansible/build.yml')

    #  Modify the objects to be able to run the playbook
    variable_manager.extra_vars = extra_vars

    options.connection='local'
    options.tags=[group]
    options.check=dry_run

    hosts = NamedTemporaryFile(delete=False)
    hosts.write("""[localhost]
    %s
    """ % 'localhost')
    hosts.close()

    passwords = {'become_pass': None}

    inventory = Inventory(loader=loader, variable_manager=variable_manager, host_list=hosts.name)
    variable_manager.set_inventory(inventory)

    #  Run the playbook
    pbex = playbook_executor.PlaybookExecutor(
        playbooks=[playbook],
        inventory=inventory,
        variable_manager=variable_manager,
        loader=loader,
        options=options,
        passwords=passwords)
    pbex.run()
    stats = pbex._tqm._stats

    os.remove(hosts.name)
    return stats

######### Public API documentation ###########

__doc__="""Create cloudformation stacks

Usage:
    run.py iam --first-password=<first_password> --key-name=<key_name> --region=<region> [--delete] [--dry-run]
    run.py vpc --region=<region> [--delete] [--dry-run]
    run.py sg --region=<region> [--delete] [--dry-run]
    run.py kms --region=<region> [--delete] [--dry-run]
    run.py bastion --key-name=<key_name> --region=<region> [--delete] [--dry-run]
    run.py rds --db-name=<db_name> --db-user=<db_user> --db-password=<db_password> --db-engine=<db_engine> --region=<region> [--delete] [--dry-run]
    run.py ec2 --key-name=<key_name> --region=<region> [--delete] [--dry-run]
    run.py elb --region=<region> [--delete] [--dry-run]
    run.py (-h | --help)

Options:
    -h --help                           This displays the help menu.
    --region=<region>                   The region of the cloudformation stacks.
    --first-password=<first_password>   The first password with which the users are being created.
    --key-name=<key_name>               The key name that will allow ssh access to ec2 instance.
    --db-name=<db_name>                 The name of the database.
    --db-user=<db_user>                 The username of the database.
    --db-password=<db_password>         The password of the database.
    --db-engine=<db_engine>             The database engine. Valid values are mysql|postgres|mariadb.
    --delete                            This option will delete the stacks.
    --dry-run                           This option will perform a dry run of the stacks.
"""

######### Entrypoint ###########

def main(args=None):
    """Entrypoint
    Main entrypoint of the program
    """

    current_time = int(time.time())
    dry_run = True if args['--dry-run'] else False
    stack_status = 'absent' if args['--delete'] else 'present'

    extra_vars = dict(
        current_time=current_time,
        region=args['--region'],
        ansible_python_interpreter="/usr/bin/env python",
        stack_status=stack_status,
        ansible_check_mode=dry_run,
        aws_access_key=os.environ['AWS_ACCESS_KEY_ID'],
        aws_secret_key=os.environ['AWS_SECRET_ACCESS_KEY'])

    if args['iam']:
        extra_vars['first_password'] = args['--first-password'] or os.environ['FIRST_PASSWORD']
        extra_vars['key_name'] = args['--key-name']
        _run_playbook('iam', extra_vars=extra_vars, dry_run=dry_run)
    elif args['bastion']:
        extra_vars['key_name'] = args['--key-name']
        _run_playbook('bastion', extra_vars=extra_vars, dry_run=dry_run)
    elif args['rds']:
        extra_vars['db_name'] = args['--db-name']
        extra_vars['db_user'] = args['--db-user']
        extra_vars['db_password'] = args['--db-password']
        extra_vars['db_engine'] = args['--db-engine']
        _run_playbook('rds', extra_vars=extra_vars, dry_run=dry_run)
    elif args['ec2']:
        extra_vars['key_name'] = args['--key-name']
        _run_playbook('ec2', extra_vars=extra_vars, dry_run=dry_run)
    else:
        _run_playbook(sys.argv[1], extra_vars=extra_vars, dry_run=dry_run)

######### Self executing script ##########
if __name__ == '__main__':
    args = docopt(__doc__, argv=sys.argv[1:])
    main(args)
