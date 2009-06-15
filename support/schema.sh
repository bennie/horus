#!/bin/sh
mysqldump --no-data -u horus -pnochaos -h mysql01.fusionone.com horus > schema.sql
