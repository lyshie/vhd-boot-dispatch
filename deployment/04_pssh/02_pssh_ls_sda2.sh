#!/bin/sh

sshpass -f passwd pssh -i -A -h "$1" -O "StrictHostKeyChecking no" -- "ls -lh /mnt/sda2/"
