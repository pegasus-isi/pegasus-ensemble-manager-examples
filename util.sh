#!/bin/bash

# Sets up example environment by clearing files/logs/db from previous run. 
__setup() {
    # Clear any files generated from a previous run of this example. This ensures
    # that you may run this example multiple times in a consistent environment.
    # In production, you would not remove any of the files created in ~/.pegasus/.
    rm -f ~/.pegasus/workflow.db \
        ~/.pegasus/ensembles/myruns/*.log \
        ~/.pegasus/ensembles/myruns/*.plan*

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
    pegasus-em server --verbose --debug > em_logs 2>&1 &
    EM_PID=$!
    echo "Started pegasus-ensemble manager in the background at pid: $EM_PID, see em_logs for logs"
    sleep 5
}

# Generate N python workflow scripts where each workflow resides in ./workflows/wf-<i>/workflow.py
# Number of workflows N is given by the first argument parameter
# Sets GENERATED_WORKFLOWS to be an array of paths to all the generated workflow scripts
__generate_workflow_scripts() {
    NUM_WORKFLOWS=$1
    GENERATED_WORKFLOWS=()
    GENERATED_WORKFLOW_DIRS=()
    echo "Generating $NUM_WORKFLOWS workflow scripts."
    for i in $(seq 1 $NUM_WORKFLOWS); do
        mkdir -p workflows/wf-$i
        sed "s/workflow-1/workflow-$i/g" ./workflows/sample_workflow.py \
            > workflows/wf-$i/workflow.py

        chmod u+x workflows/wf-$i/workflow.py
        GENERATED_WORKFLOWS+=("workflows/wf-$i/workflow.py")
        GENERATED_WORKFLOW_DIRS+=("workflows/wf-$i")
        echo -e "\tgenerated ./workflows/wf-$i/workflow.py"
    done
}

# Remove any directories generated from __generate_workflow_scripts()
__cleanup_generated_workflows() {
    for d in "${GENERATED_WORKFLOW_DIRS[@]}"; do
        echo "Removing workflow directory: $d"
        rm -r $d
    done
}

# Stops the started ensemble manager
__teardown() {
    # stop the pegasus-ensemble manager (typically, leave it on)
    echo "Shutting down ensemble manager at pid: $EM_PID"
    kill $EM_PID
}