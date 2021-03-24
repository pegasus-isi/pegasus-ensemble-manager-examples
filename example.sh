#!/bin/bash 

# Sets up example environment by clearing files/logs/db from previous run. 
__setup() {
    # Clear any files generated from a previous run of this example. This ensures
    # that you may run this example multiple times in a consistent environment.
    # In production, you would not remove any of the files created in ~/.pegasus/.
    rm -f ~/.pegasus/workflow.db \
        ~/.pegasus/ensembles/myruns/*.log \
        ~/.pegasus/ensembles/myruns/*.plan* \
        ./workflows/wf-will-fail/if.txt

    # Setup a fresh instance of the pegasus database in ~/.pegasus/workflow.db. 
    #  Typically, it is not needed to invoke this command as this database will
    #  already exist with information from previous workflow runs. 
    pegasus-db-admin create
}

# Starts the ensemble manager in the background.
# Saves the PID of ensemble manager service so we can kill it at the end of the example.
#  The ensemble manager is a long running process and you will typically leave it running. 
__start_ensemble_mgr() {
    # Ensemble manager configuration. This will specify the interval in seconds
    # at which the ensemble manager polls its database for new work. By default
    # this value is set to 60, but has been lowered to 5 specifically in this example
    # so that we can observe the state changes that take place as workflows are
    # added to an ensemble. In production, workflows can run for hours or days.
    # As such, the default 60 second interval will not have a significant impact
    # on the wall time of your worklfows. 
    echo "EM_INTERVAL = 5" >> ~/.pegasus/service.py

    # Start up the ensemble manager in the background, and give it a moment to 
    # fully start before progressing through the example usage script. 
    echo "Starting pegasus-ensemble manager in the background, see em_logs for logs"
    pegasus-em server --verbose --debug > em_logs 2>&1 &
    EM_PID=$!
    sleep 5
}

# Generate N python workflow scripts where each workflow resides in ./workflows/wf-<i>/workflow.py
# Number of workflows N is given by the first argument parameter
# Sets GENERATED_WORKFLOWS to be an array of paths to all the generated workflow scripts
__generate_workflow_scripts() {
    NUM_WORKFLOWS=$1
    GENERATED_WORKFLOWS=()
    echo "Generating $NUM_WORKFLOWS workflow scripts."
    for i in $(seq 1 $NUM_WORKFLOWS); do
        mkdir -p workflows/wf-$i
        sed "s/workflow-1/workflow-$i/g" sample_workflow.py \
            > workflows/wf-$i/workflow.py

        chmod u+x workflows/wf-$i/workflow.py
        GENERATED_WORKFLOWS+=("workflows/wf-$i/workflow.py")
        echo -e "\tgenerated ./workflows/wf-$i/workflow.py"
    done
}

# Teardown example environment by clearing generated files.
# Stops the started ensemble manager
__teardown() {
    # remove generated workflows
    ls workflows \
        | grep -P "wf-[0-9]" \
        | xargs -d "\n" printf -- "workflows/%s\n" \
        | xargs -n1 rm -r

    # stop the pegasus-ensemble manager (typically, leave it on)
    kill $EM_PID
}

__setup
__start_ensemble_mgr
################################################################################
##### BEGIN EXAMPLE ENSEMBLE MANAGER USAGE #####################################
################################################################################

echo "Creating ensemble called 'myruns'"
pegasus-em create myruns

echo "Configuring myruns ensemble"
pegasus-em config myruns --max-planning=2 --max-running=2

echo "Adding a workflow that will fail due to a msising input file"
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
__teardown





