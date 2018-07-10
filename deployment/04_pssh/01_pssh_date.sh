#!/bin/sh

sshpass -f passwd pssh -i -A -h hosts_pcroom_new -O "StrictHostKeyChecking no" -- "date"
