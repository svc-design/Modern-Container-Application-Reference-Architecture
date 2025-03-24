import os
import sys
import yaml
import argparse
from pathlib import Path
from jinja2 import Environment, FileSystemLoader

THIS_DIR = os.path.dirname(os.path.abspath(__file__))

def load_config( config_name ):
    with open(f"../envs/{config_name}", 'r') as config_file:
        config = yaml.safe_load(config_file)
    return config

def render_template( template_source, template_result, template_vars ):
    inventory_env      = Environment(loader=FileSystemLoader(THIS_DIR),
                         trim_blocks=True)
    inventory_template = inventory_env.get_template(template_source)
    inventory_output   = inventory_template.render(vars=template_vars)
    with open(template_result, "w+") as f:
        f.write(inventory_output)

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument( "-c", "--config", dest='config', help="iac resources config yaml" )

    args = parser.parse_args()
    if args.config:
        config = load_config( args.config )
        print(f"Loaded config: {args.config}" )
        vars = {
            'config': args.config,
            'firewall_rules': config.get('firewall_rules', []),
        }
        print("templated main.tf")
        render_template('templates/main.tf', 'main.tf', vars)
        print("templated variables.tf")
        render_template('templates/variables.tf', 'variables.tf', vars)
