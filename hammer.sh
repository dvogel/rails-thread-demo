#!/usr/bin/env bash

set -o errexist
set -o xtrace

for n in $(seq 5 -1 1); do
	curl -D- "http://localhost:3000/sleep?seconds=${n}" &
done

wait

