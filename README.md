# Pegasus Ensemble Manager Examples

Provided are runnable examples which showcase usage of the 
[Pegasus Ensemble Manager](https://pegasus.isi.edu/documentation/reference-guide/pegasus-service.html#ensemble-manager). Each example file, `<num>_<example name>.sh`, 
will run a set of  `pegasus-em` commands, which illustrate the usage of this tool. 

Each script begins by starting up the ensemble manager in the background and
clearing any files generated from previous runs. Following that, a number of
`pegasus-em` commands will be issued. To show that the ensemble manager is running,
`timeout --foreground <int> watch -n 1 <some command>` commands are placed in 
specific parts of the script to make the ensemble manager's work visible. Lastly, 
the script ends by shutting down the ensemble manager.

## Prerequisites

These examples are meant to be run inside of the 
[Pegasus Docker tutorial container](https://pegasus.isi.edu/documentation/user-guide/tutorial.html).
As such, ensure that you have Docker installed on your machine before proceeding. 

## Usage

1. `docker run --privileged --rm -p 9999:8888 pegasus/tutorial:5.0.0`
2. Go to `http://localhost:9999` and enter the password `scitech` when prompted.
3. On the right side, select `New` -> `Terminal`
4. git clone `https://github.com/pegasus-isi/pegasus-ensemble-manager-examples.git`
5. `cd pegasus-ensemble-manager-examples`
6. run desired example script (e.g. `./01_example_basic_usage)`

## Examples

### 01_example_basic_usage

`01_example_basic_usage.sh` demonstrates basic usage of the ensemble manager. 

The following commands are used:
- `pegasus-em create`
- `pegasus-em config`
- `pegasus-em submit`
- `pegasus-em priority`
- `pegasus-em workflows`
- `pegasus-em status`
- `pegasus-em analyze`
- `pegasus-em rerun`

In this scenario, a number of sample workflow scripts are generated and then
added to an ensemble. By editing the `NUM_WORKFLOWS` value, you can vary the number
of generated sample workflows for the example run. Following that, ensemble 
monitoring commands are used.

One of the workflows added will fail (on purpose). This script then illustrates 
how to re-run the workflow after the error has been resolved. 

### 02_example_file_pattern_trigger

`02_example_file_pattern_trigger.sh` demonstrates usage of the file pattern
triggering capabilities. 

The following commands are used: 
- `pegasus-em create`
- `pegsus-em file-pattern-trigger`
- `pegasus-em workflows` 

In this example, a process is started in that background
which periodically writes files to some designated input directory. As the ensemble
manager processes these input files, they are moved into a designated subdirectory
called `processed`. This will be made evident when running the example. 

The trigger periodically watches this directy and submits workflows to an ensemble
as files come in.