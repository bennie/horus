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

for my $host (@logwatch, @ops, @telus, @vzwv) {
  my $ssh = Net::SSH::Perl->new($host,{ debug => 1 });
  eval $ssh->login('root');
  if ($@) {
    print "$host fail\n";
  } else {
    print "$host good\n";
  }
}
