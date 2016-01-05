#!/usr/bin/env ruby
#
# check-cpu-usage.rb
#
# Author: Matteo Cerutti <matteo.cerutti@hotmail.co.uk>
#

require 'sensu-plugin/check/cli'
require 'json'
require 'socket'

class CheckCpuUsage < Sensu::Plugin::Check::CLI
  @@metrics = ['user', 'nice', 'system', 'idle', 'iowait', 'irq', 'softirq', 'steal', 'guest', 'guest_nice']

  option :metric,
         :description => "Comma separated list of metrics to monitor (default: ALL)",
         :short => "-m <#{@@metrics.join(',')}>",
         :long => "--metric <#{@@metrics.join(',')}>",
         :proc => proc { |s| s.split(',') },
         :default => @@metrics

  option :ignore_metric,
         :description => "Comma separated list of metrics to ignore",
         :short => "-i <#{@@metrics.join(',')}>",
         :long => "--ignore-metric <#{@@metrics.join(',')}>",
         :proc => proc { |s| s.split(',') },
         :default => []

  @@metrics.each do |metric|
    option "warn_#{metric}".to_sym,
           :description => "Warn if USAGE exceeds the current system #{metric} usage",
           :long => "--warn-#{metric} <USAGE>",
           :proc => proc(&:to_i),
           :default => nil

    option "crit_#{metric}".to_sym,
           :description => "Critical if USAGE exceeds the current system #{metric} usage",
           :long => "--crit-#{metric} <USAGE>",
           :proc => proc(&:to_i),
           :default => nil
  end

  option :sleep,
         :description => "Sleep N seconds when sampling metrics",
         :short => "-s <SECONDS>",
         :long => "--sleep <SECONDS>",
         :default => 1,
         :proc => proc(&:to_i)

  option :warn,
         :description => "Warn if USAGE exceeds the overall system cpu usage (default: 80)",
         :short => "-w <USAGE>",
         :long => "--warn <USAGE>",
         :default => 80,
         :proc => proc(&:to_i)

  option :crit,
         :description => "Critical if USAGE exceeds the overall system cpu usage (default: 90)",
         :short => "-c <USAGE>",
         :long => "--critical <USAGE>",
         :default => 90,
         :proc => proc(&:to_i)

  def initialize()
    super

    raise "Warning CPU usage threshold must be lower than the critical threshold" if config[:warn] >= config[:crit]

    # sanity checks
    @@metrics.each do |metric|
      raise "Must specify both warning and critical thresholds for CPU #{metric}" if (config["warn_#{metric}".to_sym] and config["crit_#{metric}".to_sym].nil?) or (config["warn_#{metric}".to_sym].nil? and config["crit_#{metric}".to_sym])

      if config["warn_#{metric}".to_sym] and config["crit_#{metric}".to_sym]
        raise "Warning CPU #{metric} threshold must be lower than the critical threshold" if config["warn_#{metric}".to_sym] >= config["crit_#{metric}".to_sym]
      end
    end
  end

  def send_client_socket(data)
    sock = UDPSocket.new
    sock.send(data + "\n", 0, "127.0.0.1", 3030)
  end

  def send_ok(check_name, msg)
    event = {"name" => check_name, "status" => 0, "output" => "OK: #{msg}", "handler" => config[:handler]}
    send_client_socket(event.to_json)
  end

  def send_warning(check_name, msg)
    event = {"name" => check_name, "status" => 1, "output" => "WARNING: #{msg}", "handler" => config[:handler]}
    send_client_socket(event.to_json)
  end

  def send_critical(check_name, msg)
    event = {"name" => check_name, "status" => 2, "output" => "CRITICAL: #{msg}", "handler" => config[:handler]}
    send_client_socket(event.to_json)
  end

  def send_unknown(check_name, msg)
    event = {"name" => check_name, "status" => 3, "output" => "UNKNOWN: #{msg}", "handler" => config[:handler]}
    send_client_socket(event.to_json)
  end

  def get_cpustats()
    cpu = {}

    stats = %x[cat /proc/stat]
    values = stats[/^cpu\s*(.*)$/, 1].split(' ').map(&:to_i)

    # missing guest time (kernel < 2.6.24)
    values << 0 if values.size < 9

    # missing guest_nice time (kernel < 2.6.33)
    values << 0 if values.size < 10

    @@metrics.each_with_index do |metric, index|
      cpu[metric] = values[index]
    end

    cpu
  end

  def run
    stats_before = get_cpustats()
    sleep(config[:sleep]) if config[:sleep] > 0
    stats_after = get_cpustats()
    stats_diff = {}
    total_diff = 0

    metrics = config[:metric] - config[:ignore_metric]
    metrics.each do |metric|
      stats_diff[metric] = stats_after[metric] - stats_before[metric]
      total_diff += stats_diff[metric]
    end

    # calculate percentage of total time for each metric
    usage = {}
    metrics.each do |metric|
      usage[metric] = 100 * stats_diff[metric] / total_diff
    end

    usage.each do |metric, value|
      check_name = "cpu-usage-#{metric}"

      if config["warn_#{metric}".to_sym] and config["crit_#{metric}".to_sym]
        if value >= config["crit_#{metric}".to_sym]
          send_critical(check_name, "CPU #{metric} time is too high - Current: #{value}% (>= #{config["crit_#{metric}".to_sym]}%)") if value >= config["crit_#{metric}".to_sym]
        elsif value >= config["warn_#{metric}".to_sym]
          send_warning(check_name, "High CPU #{metric} time - Current: #{value}% (>= #{config["warn_#{metric}".to_sym]}%)") if value >= config["warn_#{metric}".to_sym]
        else
          send_ok(check_name, "CPU #{metric} time is normal - Current: #{value}% (<= #{config["warn_#{metric}".to_sym]}%)")
        end
      else
        send_ok(check_name, "CPU #{metric} not monitored")
      end
    end

    config[:ignore_metrics].each do |metric|
      send_ok(check_name, "CPU #{metric} time not monitored")
    end

    # overall cpu usage
    usage['overall'] = 100 * (total_diff - stats_diff['idle']) / total_diff

    critical("CPU usage is too high - Current: #{usage['overall']}% (>= #{config[:crit]}%)") if usage['overall'] >= config[:crit]
    warning("High CPU usage - Current: #{usage['overall']}% (>= #{config[:warn]}%)") if usage['overall'] >= config[:warn]
    ok("CPU usage is normal - Current: #{usage['overall']}% (<= #{config[:warn]}%)")
  end
end
