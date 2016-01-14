# Sensu plugin for monitoring the system CPU usage

A sensu plugin to monitor the system's CPU usage with the option to generate events on specific metrics (e.g. user time, system time)

The plugin generates multiple OK/WARN/CRIT/UNKNOWN events via the sensu client socket (https://sensuapp.org/docs/latest/clients#client-socket-input)
so that you do not miss state changes when monitoring multiple metrics.

## Usage

The plugin accepts the following command line options:

```
Usage: check-cpu-usage.rb (options)
    -c, --critical <USAGE>           Critical if USAGE exceeds the overall system cpu usage (default: 90)
        --crit-guest <USAGE>         Critical if USAGE exceeds the current system guest usage
        --crit-guest_nice <USAGE>    Critical if USAGE exceeds the current system guest_nice usage
        --crit-idle <USAGE>          Critical if USAGE exceeds the current system idle usage
        --crit-iowait <USAGE>        Critical if USAGE exceeds the current system iowait usage
        --crit-irq <USAGE>           Critical if USAGE exceeds the current system irq usage
        --crit-nice <USAGE>          Critical if USAGE exceeds the current system nice usage
        --crit-softirq <USAGE>       Critical if USAGE exceeds the current system softirq usage
        --crit-steal <USAGE>         Critical if USAGE exceeds the current system steal usage
        --crit-system <USAGE>        Critical if USAGE exceeds the current system system usage
        --crit-user <USAGE>          Critical if USAGE exceeds the current system user usage
        --handlers <HANDLERS>        Comma separated list of handlers
    -i <user,nice,system,idle,iowait,irq,softirq,steal,guest,guest_nice>,
        --ignore-metric              Comma separated list of metrics to ignore
    -m <user,nice,system,idle,iowait,irq,softirq,steal,guest,guest_nice>,
        --metric                     Comma separated list of metrics to monitor (default: ALL)
    -s, --sleep <SECONDS>            Sleep N seconds when sampling metrics
    -w, --warn <USAGE>               Warn if USAGE exceeds the overall system cpu usage (default: 80)
        --warn-guest <USAGE>         Warn if USAGE exceeds the current system guest usage
        --warn-guest_nice <USAGE>    Warn if USAGE exceeds the current system guest_nice usage
        --warn-idle <USAGE>          Warn if USAGE exceeds the current system idle usage
        --warn-iowait <USAGE>        Warn if USAGE exceeds the current system iowait usage
        --warn-irq <USAGE>           Warn if USAGE exceeds the current system irq usage
        --warn-nice <USAGE>          Warn if USAGE exceeds the current system nice usage
        --warn-softirq <USAGE>       Warn if USAGE exceeds the current system softirq usage
        --warn-steal <USAGE>         Warn if USAGE exceeds the current system steal usage
        --warn-system <USAGE>        Warn if USAGE exceeds the current system system usage
        --warn-user <USAGE>          Warn if USAGE exceeds the current system user usage
```

By default, all metrics are taken into consideration when calculating the overall cpu usage.

Use the --handlers command line option to specify which handlers you want to use for the generated events.

## Author
Matteo Cerutti - <matteo.cerutti@hotmail.co.uk>
