#!/bin/bash 
source ./util.sh

__setup
__start_ensemble_mgr
################################################################################
##### BEGIN EXAMPLE ENSEMBLE MANAGER USAGE #####################################
################################################################################

echo "Creating ensemble called 'myruns'"
pegasus-em create myruns

echo "Configuring myruns ensemble"
pegasus-em config myruns --max-planning=2 --max-running=2

echo "Adding a workflow that will fail due to a missing input file"
pegasus-em submit myruns.wf-1-will-fail ./workflows/wf-will-fail/workflow.py

# Set value to alter the number additional workflows generated for this example.
NUM_WORKFLOWS=3
__generate_workflow_scripts $NUM_WORKFLOWS

echo "Adding generated workflows"
let i=1
for wf_script in "${GENERATED_WORKFLOWS[@]}"; do
    pegasus-em submit myruns.wf-$i $wf_script
    pegasus-em priority myruns.wf-$i -p $i
    echo "    added $wf_script as myruns.wf-$i"
    let i=$i+1
done

echo "Monitor all workflows in myruns"
timeout --foreground 120 watch -n 1 pegasus-em workflows myruns

echo "See status output for myruns.wf-1"
pegasus-em status myruns.wf-1

echo "See pegasus-analyzer output for myruns.wf-1-will-fail"
pegasus-em analyze myruns.wf-1-will-fail

echo "Fixing failed workflow; re-running"
echo "sample input" > workflows/wf-will-fail/if.txt
pegasus-em rerun myruns.wf-1-will-fail

timeout --foreground 240 watch -n 1 pegasus-em workflows myruns

################################################################################
##### END EXAMPLE ENSEMBLE MANAGER USAGE #######################################
################################################################################
rm -f ./workflows/wf-will-fail/if.txt
__cleanup_generated_workflows
__teardown





