#!/bin/sh

# This one will do the inserts one per line with full statements:
#mysqldump --complete-insert --skip-extended-insert -u horus -pnochaos horus > horus.sql

mysqldump -u horus -pnochaos -h mysql01.fusionone.com horus > horus.sql
