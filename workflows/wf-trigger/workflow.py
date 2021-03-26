#!/usr/bin/env python3
import argparse
import logging
import sys

from datetime import datetime
from pathlib import Path

from Pegasus.api import *

logging.basicConfig(level=logging.DEBUG)

def parse_args(args):
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--inputs",
        nargs="+",
        required=True,
        help="workflow input files"
    )

    return parser.parse_args(args)

if __name__=="__main__":
    args = parse_args(sys.argv[1:])

    # --- working directory setup ----------------------------------------------
    WORK_DIR = Path.home() / "workflows"
    WORK_DIR.mkdir(exist_ok=True)

    TOP_DIR = Path(__file__).parent.resolve()

    # --- properties setup -----------------------------------------------------
    props = Properties()
    props["pegasus.mode"] = "development"

    # specify abs path to catalogs
    sc_file = str(TOP_DIR / "sites.yml")
    rc_file = str(TOP_DIR / "replicas.yml")
    tc_file = str(TOP_DIR / "transformations.yml")
    props_file = str(TOP_DIR / "pegasus.properties")

    props["pegasus.catalog.site.file"] = sc_file
    props["pegasus.catalog.replica.file"] = rc_file
    props["pegasus.catalog.transformation.file"] = tc_file
    props.write(props_file)

    # --- output dir setup ---------------------------------------------------------
    sc = SiteCatalog()
    # override default local site
    local_site = Site(name="local")
    local_shared_scratch = Directory(Directory.SHARED_SCRATCH, path=WORK_DIR / "scratch") \
                            .add_file_servers(
                                FileServer(
                                    url="file://" + str(WORK_DIR / "scratch"), 
                                    operation_type=Operation.ALL
                                )
                            )

    local_local_storage = Directory(Directory.LOCAL_STORAGE, path=WORK_DIR / "outputs/workflow-trigger") \
                            .add_file_servers(FileServer(
                                    url="file://" + str(WORK_DIR / "outputs/workflow-trigger"),
                                    operation_type=Operation.ALL
                                )
                            )

    local_site.add_directories(local_shared_scratch, local_local_storage)
    sc.add_sites(local_site)
    sc.write(sc_file)


    # --- input files ----------------------------------------------------------
    rc = ReplicaCatalog()
    ifs = []
    for f in args.inputs:
        p = Path(f)
        _if = File(p.name)
        ifs.append(_if)
        rc.add_replica("local", _if, p.resolve())

    rc.write(rc_file)

    # --- executables ----------------------------------------------------------
    tc = TransformationCatalog()
    combine = Transformation(
                    "combine",
                    site="local",
                    pfn=Path(__file__).parent.resolve() / "combine.py",
                    is_stageable=True
                )

    tc.add_transformations(combine)
    tc.write(tc_file)

    # --- workflow -------------------------------------------------------------
    wf = Workflow("trigger-workflow")

    of = File("out_{}.txt".format(int(datetime.now().timestamp())))
    combine_job = Job("combine")\
                    .add_args(of)\
                    .add_inputs(*ifs)\
                    .add_outputs(of)

    wf.add_jobs(combine_job)

    wf.plan(conf=props_file)