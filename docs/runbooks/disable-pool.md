# Runbook: Disable Pool

## Purpose

Reversibly stop Cursor workers during an incident or maintenance.

## Steps

1. Set `capacity.instance_count = 0` on the worker module (or scale via autoscaler `MIN_INSTANCES=0` if supported) and apply.
2. If autoscaler would restore capacity, also set autoscaler pool instances to `0` or disable its secret access.
3. Confirm no active instances in Cloud Console / `gcloud run worker-pools describe`.
4. Optionally disable the Cursor API key Secret Manager version.
5. Record incident ID in the change ticket.

## Restore

1. Re-enable secret version if disabled.
2. Set instance count back to desired floor.
3. Confirm workers reconnect in Cursor dashboard / fleet summary API.
