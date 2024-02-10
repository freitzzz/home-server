# monitoring

This folder contains bash scripts I use to monitor events of the services I run in my home server, alerting myself with notifications in a Telegram group channel. To keep the scripts alive between `SSH` sessions, I make use of `screen` to create daemon bash sessions (`sudo apt-get install screen -y`). 

## Environment

The scripts require the `.env` to exist and contain all environment variables that power the normal operation of the monitoring sessions.

```bash
cp .env.tpl .env
# Now assign the expected values in each variable
nano .env
```

## Lifecycle

To start the monitoring, run the `start.sh` script. To stop it, run the `stop.sh` script.