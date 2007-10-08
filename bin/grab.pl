#!/usr/bin/perl -Ilib

use Fusionone::Hosts;

require Math::BigInt::GMP; # For speed on Net::SSH::Perl;
use Net::SSH::Perl;

use strict;

my %machines;

map { $machines{$_} = undef; } qw/al-fms01 al-fms02 alqa al-sync01 dba
dbb dbc dbd db-embarq dbwh2 demo-vm fms01-palmbeta fmsa fmsb fmse
fms-embarq fmsf fmsg fmsh fmsj fmsk fmsp1 fmsp2 frogger log02-palmbeta
pagea pageb pagec paged pagee pageg pageh pagej pageo pagep palmweb01
straylight sync02-palmbeta synca syncaa syncab syncb synce sync-embarq
syncf syncg synch syncj synck syncl syncm syncn synco syncp syncq
straylight frogger sawmill/;

map { $machines{$_} = 'fusion123' } qw/vz-fms01 vz-fms02 vz-page01
vz-page02 vz-sync01 vz-sync02 vz-db01 vz-db02/;

# ducati fmsab fmsl pagel pageq vm-fms vm-page

my @telus = ();#qw/172.26.23.11 172.26.23.12 172.26.23.13 172.26.23.139/;


# ops

for my $host ( sort keys %machines ) {
  my ($stdout, $stderr, $exit, $ssh);

  eval {
    $ssh = Net::SSH::Perl->new($host,( protocol=>'2,1',  debug => 0 ));
    $ssh->login('root',$machines{$host});
  };

  if ($@) { print "$host: connection failed.\n"; next; }

  ($stdout, $stderr, $exit) = $ssh->cmd('uname -m');

  chomp $stdout;
  my $arch = $stdout;

  ($stdout, $stderr, $exit) = $ssh->cmd('uname -s');

  chomp $stdout;
  my $os = $stdout;

  ($stdout, $stderr, $exit) = $ssh->cmd('uname -r');

  chomp $stdout;
  my $os_version = $stdout;

  print "$host : $os $os_version ($arch)\n";
}
