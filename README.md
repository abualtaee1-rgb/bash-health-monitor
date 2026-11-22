# Bash Health Monitor

A small Bash script that checks memory and disk usage on a Linux server, logs the result with a UTC timestamp, and flags a warning when usage passes a threshold. Cron runs it every 5 minutes. This is the second project in my DevOps portfolio, after my [hardened Ubuntu server lab](https://github.com/abualtaee1-rgb/linux-homelab).

Tested on Ubuntu Server 26.04 LTS (VirtualBox VM).

## What it does

- Measures memory usage (from `free`) and disk usage on `/` (from `df`) as percentages.
- Compares each against a threshold (80% by default) and prints `OK` or `WARNING`.
- Starts every run with a UTC timestamp header, so each block in the log can be tied to a time.

Example output:

```
=== Health check 2026-11-21 16:06:01 UTC ===
Memory usage: 24%
OK: Memory usage is within limits
Disk usage: 14%
OK: Disk usage is within limits
```

## How to run it

```bash
chmod +x health-check.sh
./health-check.sh
```

To run it automatically every 5 minutes and append to a log, add this line with `crontab -e`:

```
*/5 * * * * /home/<user>/scripts/health-check.sh >> /home/<user>/health.log 2>&1
```

Full paths are needed because cron has a minimal environment. `2>&1` sends error messages to the log too, otherwise cron tries to mail them and they are lost.

## Evidence

Files in [`docs/evidence-m2`](docs/evidence-m2):

- `crontab.txt`: the schedule I used
- `health-log-sample.txt`: a sample of the log written by cron

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

## What broke and how I fixed it

**1. My cron job did nothing and showed no error.** I had copied the `tar` backup example from the crontab comments into my line, so cron tried to create an archive instead of running my script. The filename was also misspelled. Cron sends errors to email, which doesn't exist on this server, so the log stayed empty. I replaced the command with the full script path and added `2>&1`.

**2. A variable name that failed silently.** My warning message used `${THRESHOLD}`, but I had defined `MEM_THRESHOLD`. Bash treats an undefined variable as an empty string and gives no error, so the message would have read "above %". I found it by reading the code and testing the warning branch.

**3. The disk check used the memory threshold.** I had copied the memory block and forgot to rename one variable. My first test lowered both thresholds at once, so both warnings fired and the mistake stayed hidden. Testing each threshold on its own showed it.

**4. `[14: command not found`.** I left out the space after `[` in an `if` test. In Bash, `[` is a command and needs a space before its arguments.

**5. Line endings.** Git on Windows can convert shell scripts to CRLF, which breaks the `#!/bin/bash` line when the file goes back to Linux. I added a `.gitattributes` file that forces LF for `.sh` files.

## Limitations and next steps

- If the server is off, cron doesn't make up the missed runs, so the log has a gap.
- Warnings are only written to the log. There is no email or chat alert.
- Timestamps are in UTC, which is how the server's clock is set.
