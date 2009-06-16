0 18 * * * horus cd /home/horus/bin && ./grab.pl --quiet --email=dcops@fusionone.com
0 9 * * * horus cd /home/horus/bin && ./grab.pl --quiet --noconfigsave --email=ppollard@fusionone.com
0 8 * * * horus cd /home/horus/bin && ./report-esx.pl | ./report-update.pl vmhosts
