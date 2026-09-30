#!/bin/sh
# Samples the Lightsail host while script/load_test/talks.js runs against it:
#
#   ssh -p 9922 ubuntu@<host> 'sh -s' < script/load_test/monitor.sh | tee tmp/load_test/host.log
#
# Memory is what runs out first on this host, which production, staging and
# cfp-app share. Stop the test if "avail" keeps falling or swap starts growing.
INTERVAL=${INTERVAL:-5}
REDIS=${REDIS:-conference-app-redis}

while :; do
  echo "--- $(date +%T) load $(cut -d' ' -f1-3 /proc/loadavg)"
  free -m | awk 'NR == 2 { print "mem used=" $3 "MB avail=" $7 "MB" } NR == 3 { print "swap used=" $3 "MB" }'
  docker stats --no-stream --format '{{.Name}} cpu={{.CPUPerc}} mem={{.MemUsage}}'
  docker exec "$REDIS" redis-cli INFO memory | grep -E '^used_memory_human' | tr -d '\r'
  docker exec "$REDIS" redis-cli INFO stats | grep -E '^evicted_keys' | tr -d '\r'
  sleep "$INTERVAL"
done
