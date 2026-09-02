Create a queuejob hook that checks the specifications of the job request and accepts or rejects the job .

vi interactive_reject.py

```python
import pbs
import sys
INTERACTIVE_QUEUE=“dev”
BATCH_QUEUE=[“workq”,“batchq”,“high”]
try:
# Get the hook event information and parameters
# This will be for the ‘queuejob’ event type.
    e = pbs.event()

    # Get the information for the job being queued
    j = e.job
    if ( hasattr(j.queue, "name")):
    pbs.logmsg(pbs.LOG_ERROR, "queue has name %s" % j.queue.name)
    else:
        j.queue = pbs.server().queue(str(pbs.server().default_queue))
        pbs.logmsg(pbs.LOG_ERROR, "queue has name %s" % j.queue.name)
    if str(j.queue) in BATCH_QUEUE:
        if j.interactive:
            e.reject("Interactive Jobs are not allowed in this queue")
except SystemExit:
    pass
```

Config the hook
```
[root@pbspro ]#qmgr -c "c h intcheck event=queuejob"
[root@pbspro ]#qmgr -c "i h intcheck application/x-python default interactive_reject.py"
```

Test the hook
```
[root@pbspro ]# qsub -I -X -q workq
qsub: Interactive Jobs are not allowed in this queue
```

Disable a hook:
```bash
qmgr -c "s h <hook name> enabled=False"

qmgr -c "s h intcheck enabled=False"
```
Note:
- Update the queue names in the BATCH_QUEUE and INTERACTIVE_QUEUE in the .py file


Create PBS container hook
```bash
qmgr -c "list hook"
qmgr -c "list pbshook"
qmgr -c "export pbshook PBS_hpc_container application/x-config default" > container_config.json
qmgr -c "import pbshook PBS_hpc_container application/x-config default container_config.json"
qmgr -c "export hook pbs_cgroups application/x-config default" > pbs_cgroups_config.json
qmgr -c "import hook pbs_cgroups application/x-config default pbs_cgroups_config.json"
```

GPU management:
```bash
https://github.com/PBSPro/nvidia-dcgm-pbspro-connector
https://www.altair.com/resource/boosting-your-gpu-performance-in-a-complex-hpc-environment
https://www.altair.com/newsroom/articles/Understanding-GPU-Usage-Influencing-Job-Scheduling-with-Altair-PBS-Professional
```