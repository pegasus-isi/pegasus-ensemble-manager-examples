#!/usr/bin/env python3
import sys

from glob import glob

output = []
for f in glob("*.txt"):
    with open(f, "r") as _if:
        output.append(_if.read().strip())

with open(sys.argv[1], "w") as of:
    of.write("\n".join(output))
    of.write("\n")