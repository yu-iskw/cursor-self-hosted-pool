# Troubleshooting

| Symptom                                 | Checks                                                                                                |
| --------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Worker never appears in Cursor UI       | `CURSOR_API_KEY` type (service account key), egress to `api2.cursor.sh`, management port/`PORT`, logs |
| Secret access denied                    | Secret IAM binding, secret ID/version, runtime SA                                                     |
| Revision failed                         | Image digest pull permissions, VPC, probe port                                                        |
| Autoscaler no-ops                       | Fleet API auth, `WORKER_SERVICE_NAME`, Run IAM on worker pool, `ignore_changes` conflict              |
| Terraform wants to reset instance count | Enable `ignore_manual_instance_count_changes` on worker module                                        |

See [compatibility.md](compatibility.md) for provider and Cursor constraints.
