# Entity Resolution logs

We wanted to investigate how common it was to overwrite a company number when we
'resolve' companies with OpenCorporates (a key step in our data import process
to dedupe and enhance our data). To do this we added some additional logging to
our import code (which is stored with PaperTrail) and then used the scripts here
to turn those logs into a CSV for analysis.

## Download logs

We used the [papertrail cli](https://github.com/papertrail/papertrail-cli) tool
to download the data and pipe it into a text file.

```shell
papertrail --min-time '4 days ago' EntityResolver > entity_resolver_log_msgs.txt
```

`EntityResolver` is a querystring that happens to match the log lines we're
interested (at the moment) but it could be anything from the log messages.

Note: you need to make sure you're getting all the logs here, double check the
timestamps and set `--min-time` accordingly.

## Strip out unnecessary stuff from the logs

As-per the papertrail-cli docs, I used `cut` to strip out some of the cruft from
the log files before processing them with Ruby:

```shell
cat entity_resolver_log_msgs.txt | cut -d ' ' -f 10- > entity_resolver_logs.txt
```

## Turn logs into a CSV

`entity_resolver_logs.rb` is a script to turn the log file into a csv. It uses a
regex and some basic string matching to strip out the cruft and extract data
from each log line. This depends on the log message's format, so if that changes
it will probably break.

This writes the output to `entity_resolver_logs.csv`
