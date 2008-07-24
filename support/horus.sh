#!/bin/sh
mysqldump --complete-insert --skip-extended-insert -u horus -pnochaos horus > horus.sql
