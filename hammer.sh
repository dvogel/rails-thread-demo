#!/usr/bin/env bash

set -o errexit
# set -o xtrace

for n in $(seq 5 -1 1); do
	curl --silent "http://localhost:3000/sleep?seconds=${n}" &
	sleep 0.1
done

wait
echo

