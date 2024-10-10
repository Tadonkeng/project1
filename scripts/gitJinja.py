#!/bin/python
import sys
import json
import os, argparse
from jinja2 import Template

parser = argparse.ArgumentParser()
parser.add_argument("--template-file",help="Path to the template file",required=True)
options = parser.parse_args()


data = json.loads(sys.stdin.read())


f = open(options.template_file)
my_template = f.read()
tm = Template(my_template)
output = tm.render(data)
print output
