0 18 * * * horus cd /home/horus/bin && ./grab.pl --quiet --archive --email=dcops@fusionone.com
0 9 * * * horus cd /home/horus/bin && ./grab.pl --quiet --noconfigsave --email=ppollard@fusionone.com
0 */4 * * * horus cd /home/horus/bin; ./report-esx.pl | ./report-update.pl vmhosts
0 12 * * * horus cd /home/horus/bin; ./report-backups.pl | ./report-update.pl backups

