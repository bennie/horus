#!/bin/sh
mysqldump --no-data -u horus -pnochaos -h localhost horus > schema.sql
