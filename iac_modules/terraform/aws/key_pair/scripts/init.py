import os
import sys
import hvac
import subprocess
from pathlib import Path
from jinja2 import Environment, FileSystemLoader

app_dir = sys.argv[1]
home_dir = str(Path.home())
THIS_DIR = os.path.dirname(os.path.abspath(__file__))


def run_cmd(cmd):
    retcode, output = subprocess.getstatusoutput( cmd )
    assert retcode == 0
    return output

def read_vault_vars(vault_url, vault_token, vault_path, vault_secret):
    client = hvac.Client(url=vault_url,token=vault_token)
    client.is_authenticated()

    client.secrets.kv.v2.configure(
      max_versions=20,
      mount_point=vault_path,
    )

    request = client.secrets.kv.v2.read_secret_version(mount_point=vault_path, path=vault_secret)
    return request

def render_template( template_source, template_result, template_vars ):
    inventory_env      = Environment(loader=FileSystemLoader(THIS_DIR),
                         trim_blocks=True)
    inventory_template = inventory_env.get_template(template_source)
    inventory_output   = inventory_template.render(vars=template_vars)
    with open(template_result, "w+") as f:
        f.write(inventory_output)


if __name__ == '__main__':

    ak                      = os.environ['ak']
    sk                      = os.environ['sk']
    region                  = os.environ['region']
    az                      = os.environ['az']
    iac_state_s3            = os.environ['tf_s3']
    iac_state_key           = os.environ['tf_key']

    key_name                = os.environ['key_name']

    vars = {}

    vars.update( { 
    'count': { 
         'ak': ak, 
         'sk': sk, 
         'region': region,
         'az': az
         },
    'iac_state': {
          's3': iac_state_s3,
          'key': iac_state_key 
        },
    'key_name': key_name
    } )
  
    print("set input-variables")
    render_template('templates/temp-input-variables', 'input-variables.yaml', vars)

    print("set iac provider configure")
    render_template('templates/temp-provider.tf', 'provider.tf', vars)
    
    print("set aws-cli: region")
    set_aws_region="aws configure set region {region}".format(region=vars['count']['region'])
    print(set_aws_region)
    run_cmd(set_aws_region)

    print("set aws-cli: ak")
    set_aws_ak="aws configure set aws_access_key_id {ak}".format(ak=vars['count']['ak'])
    run_cmd(set_aws_ak)

    print("set aws-cli: sk")
    set_aws_sk="aws configure set aws_secret_access_key {sk}".format(sk=vars['count']['sk'])
    run_cmd(set_aws_sk)

    assume_role="bash scripts/sts.sh {iac_dir}".format(iac_dir=app_dir)
    subprocess.run(args=assume_role, input='4', shell=True, encoding='utf-8')
