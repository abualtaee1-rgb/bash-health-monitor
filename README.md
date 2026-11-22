## Log rotation

The log grows with every cron run, so I added a `logrotate` config ([`logrotate-health-check.conf`](docs/evidence-m2/logrotate-health-check.conf)):

```
/home/vboxuser/health.log
{
  rotate 4
  weekly
  missingok
  compress
  notifempty
  create vboxuser vboxuser
}
```

- `weekly` and `rotate 4`: rotate once a week and keep the 4 most recent old logs.
- `compress`: old logs are gzipped.
- `missingok` and `notifempty`: no error if the log is missing, and no rotation of an empty log.
- `create vboxuser vboxuser`: logrotate runs as root, so I set the new file's owner explicitly so the cron job (running as `vboxuser`) can keep writing to it.

I forced a rotation with `logrotate -f` and checked the result: the old log became a `.gz` file, a new empty `health.log` appeared, and cron wrote the next block into it ([listing](docs/evidence-m2/logrotate-result.txt)).