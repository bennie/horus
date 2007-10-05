#!/usr/bin/perl

use Net::SSH::Perl;
use strict;

my @logwatch = qw/al-fms01 al-fms02 alqa al-sync01 dba dbb dbc dbd
db-embarq dbwh2 demo-vm fms01-palmbeta fmsa fmsb fmse fms-embarq fmsf
fmsg fmsh fmsj fmsk fmsp1 fmsp2 frogger log02-palmbeta pagea pageb pagec
paged pagee pageg pageh pagej pageo pagep palmweb01 straylight
sync02-palmbeta synca syncaa syncab syncb synce sync-embarq syncf syncg
synch syncj synck syncl syncm syncn synco syncp syncq/;

# ducati fmsab fmsl pagel pageq vm-fms vm-page

my @ops = qw/straylight ops frogger/;

my @telus = qw/172.26.23.11 172.26.23.12 172.26.23.13 172.26.23.139/;

my @vzwv = qw/vz-fms01 vz-fms02 vz-page01 vz-page02 vz-sync01 vz-sync02
vz-db01 vz-db02/;

my @hosts = grep /^(fms|page|sync).$/, @logwatch, @ops, @telus, @vzwv;

for my $host (@hosts) {
  my $ssh = Net::SSH::Perl->new($host,( protocol=>'2,1',  debug => 0 ));
  $ssh->login('root');

  print "$host : ";
  my ($stdout, $stderr, $exit) = $ssh->cmd('uname -a ');
  print $stdout;
}
