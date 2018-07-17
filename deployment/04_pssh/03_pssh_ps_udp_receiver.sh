#!/bin/sh

sshpass -f passwd pssh -i -A -h "$1" -O "StrictHostKeyChecking no" -- "ps aux | grep udp-receiver"
