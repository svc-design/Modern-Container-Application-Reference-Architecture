import os
import sys
import hcl2
import subprocess
from jinja2 import Environment, FileSystemLoader

THIS_DIR = os.path.dirname(os.path.abspath(__file__))

def render_template( template_source, template_result, template_vars ):
    inventory_env      = Environment(loader=FileSystemLoader(THIS_DIR),
                         trim_blocks=True)
    inventory_template = inventory_env.get_template(template_source)
    inventory_output   = inventory_template.render(vars=template_vars)
    with open(template_result, "w+") as f:
        f.write(inventory_output)

def parse_hcl2(contents: str) -> dict:
    try:
        return hcl2.loads(contents)
    except Exception as error:
        print(file=sys.stderr)
        log.bad("Error parsing:")
        print(contents, file=sys.stderr)
        log.bad(f"Raising: {error.__class__.__name__}")
        raise

if __name__ == '__main__':


    cmd='bash -c "source tmp-env.sh && terraform output"'
    data=subprocess.getoutput(cmd)

    if not (data is None):
        dict=parse_hcl2(data)
        vars = {}
        for k, v in dict.items():
            vars[k] = v

        render_template('templates/temp-build.env', 'build.env', vars)
    else:
        print("terraform output return empty vaule")
