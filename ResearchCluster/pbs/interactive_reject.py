import pbs
import sys
INTERACTIVE_QUEUE="dev"
BATCH_QUEUE=["platinum","gold","silver"]


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
            e.reject("Interactive Jobs are not allowed in this queue. Please use the queue dev for interactive jobs. Contact system admin to add you into the dev queue.")
except SystemExit:
    pass
