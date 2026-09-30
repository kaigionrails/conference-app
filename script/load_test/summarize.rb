#!/usr/bin/env ruby
# Breaks a k6 run of script/load_test/talks.js down by minute, which is one
# step of PROFILE=step, so the rate at which latency breaks down stands out:
#
#   k6 run --out json=tmp/load_test/run.json.gz script/load_test/talks.js
#   ruby script/load_test/summarize.rb tmp/load_test/run.json.gz

require "json"
require "time"
require "zlib"

path = ARGV.fetch(0) { abort "usage: #{$0} <k6 --out json file>" }
input = path.end_with?(".gz") ? Zlib::GzipReader.open(path) : File.open(path)

durations = Hash.new { |h, k| h[k] = Hash.new { |hh, page| hh[page] = [] } }
counts = Hash.new { |h, k| h[k] = Hash.new(0) }
start = nil

input.each_line do |line|
  point = JSON.parse(line)
  next unless point["type"] == "Point"

  data = point["data"]
  tags = data["tags"] || {}
  metric = point["metric"]
  time = Time.iso8601(data["time"]).to_f

  # Minutes count from the first page view, not from setup's logins. vus
  # carries no scenario tag.
  if tags["scenario"] == "page_views"
    start ||= time
  elsif metric != "vus" || start.nil?
    next
  end
  minute = ((time - start) / 60).floor

  case metric
  when "http_req_duration" then durations[minute][tags["page"]] << data["value"]
  when "http_req_failed" then counts[minute]["failed_#{tags["page"]}"] += data["value"].to_i
  when "iterations" then counts[minute]["iterations"] += 1
  when "dropped_iterations" then counts[minute]["dropped"] += data["value"].to_i
  when "vus" then counts[minute]["vus"] = [counts[minute]["vus"], data["value"].to_i].max
  end
end

def percentile(values, p)
  return "-" if values.empty?

  sorted = values.sort
  sorted[((sorted.size - 1) * p).round].round.to_s
end

row = "%-4s %8s %6s %5s %8s %8s %8s %8s %8s %8s %8s"
puts format(row, "min", "iters/s", "drop", "vus", "talk p50", "talk p95", "talk p99", "talk max", "sw p95", "img p95", "failed")
(counts.keys | durations.keys).sort.each do |minute|
  talks = durations[minute]["talks"]
  c = counts[minute]
  failed = c.select { |k, _| k.start_with?("failed_") }.sum { |_, v| v }
  puts format(row, minute, format("%.1f", c["iterations"] / 60.0), c["dropped"], c["vus"],
    percentile(talks, 0.5), percentile(talks, 0.95), percentile(talks, 0.99), percentile(talks, 1.0),
    percentile(durations[minute]["sw"], 0.95), percentile(durations[minute]["image"], 0.95), failed)
end
puts "(durations in ms; the last minute may be partial)"
