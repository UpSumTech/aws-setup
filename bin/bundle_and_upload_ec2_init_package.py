#!/usr/bin/env python2.7
#########################################################
######################## Imports ########################
#########################################################
import boto3
import botocore
import os
import shutil
import sys
import zipfile
import tempfile

#########################################################
####################### Global vars #####################
#########################################################
bucket_name = None # global and gets mutated at the entrypoint of the program
version = None # global and gets mutated at the entrypoint of the program
package_name = 'ec2setup.zip'
files_to_upload = [
        "setup-users-groups.sh",
        "harden-os.sh",
        "get-os-info.sh",
        "fetch-service-artifacts.sh",
        "get-initd-scripts.sh",
        "start-services.sh"]

#########################################################
#################### Helper functions ###################
#########################################################
def die(msg):
    sys.stderr.write("ERROR: %s\n" % msg)
    sys.exit(1)

def _get_s3_dest():
    return os.path.join(version, package_name)

def _is_version_present():
    key_exists = False
    s3 = boto3.resource('s3')
    try:
        s3.Object(bucket_name, _get_s3_dest()).load()
    except botocore.exceptions.ClientError as err:
        if err.response['Error']['Code'] == '404':
            key_exists = False
        else:
            raise
    return key_exists

#########################################################
################# Higher level functions ################
#########################################################
def validate():
    if not 'aws-setup' in os.environ.get('VIRTUAL_ENV',''):
        die("you need to 'workon aws-setup'")
    if not os.environ.get('AWS_ACCESS_KEY_ID') or not os.environ.get('AWS_SECRET_ACCESS_KEY'):
        die("The AWS_* env vars are missing")
    if _is_version_present():
        die("The version you are trying to create alrady exists")

def create_init_package():
    package_file_path = os.path.join(tmpdir, package_name)
    zf = zipfile.ZipFile(package_file_path, 'w')
    source_file_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)), '../scripts/ec2/init-package')
    try:
        for filename in files_to_upload:
            file_to_upload = os.path.join(source_file_dir, filename)
            zf.write(file_to_upload, os.path.basename(file_to_upload), compress_type = zipfile.ZIP_DEFLATED)
    finally:
        zf.close()

def upload_package_to_s3():
    client = boto3.client('s3')
    local_source = os.path.join(tmpdir, package_name)
    client.upload_file(local_source, bucket_name, _get_s3_dest())

#########################################################
###################### Entrypoint #######################
#########################################################
def main(args):
    global bucket_name
    global version
    bucket_name = args[0]
    version = args[1]
    validate()
    create_init_package()
    upload_package_to_s3()

if __name__ == '__main__':
    try:
        tmpdir = tempfile.mkdtemp()
        main(sys.argv[1:])
    finally:
        shutil.rmtree(tmpdir) # Remember to always clean your tmpdirs
