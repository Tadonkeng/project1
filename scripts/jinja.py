#!/bin/python
import sys
import json
import os
from jinja2 import Template


data = json.loads(sys.stdin.read())


f = open('konvoy-cluster.yaml.template')
my_template = f.read()

tm = Template(my_template)

output = tm.render(data)
print output
