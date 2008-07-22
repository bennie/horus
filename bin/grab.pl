#!/usr/bin/perl -I../lib

=head schema
+----------------+--------------+------+-----+---------+----------------+
| Field          | Type         | Null | Key | Default | Extra          |
+----------------+--------------+------+-----+---------+----------------+
| id             | int(11)      |      | PRI | NULL    | auto_increment |
| name           | varchar(255) | YES  | MUL | unknown |                |
| os             | varchar(64)  | YES  |     | NULL    |                |
| osversion      | varchar(255) | YES  |     | NULL    |                |
| arch           | varchar(24)  | YES  |     | NULL    |                |
| tz             | char(3)      | YES  |     | NULL    |                |
| snmp           | int(11)      | YES  |     | 0       |                |
| snmp_community | varchar(24)  | YES  |     | NULL    |                |
| ntp            | int(11)      | YES  |     | 0       |                |
| ntphost        | varchar(255) | YES  |     | NULL    |                |
+----------------+--------------+------+-----+---------+----------------+
=cut

use Fusionone::Ethernet;
use Fusionone::Hosts;

require Math::BigInt::GMP; # For speed on Net::SSH::Perl;
use Net::SSH::Perl;

use strict;

my %machines;

for my $cust ( qw/al bm nwh telus/ ) {
  for my $type ( qw/fms page sync/ ) {
    for my $num ( qw/01 02/ ) {
      $machines{"$cust-$type$num"} = undef;
    }
  }
}

map { $machines{$_} = undef; } qw/alqa dba dbb dbc dbd db-embarq dbwh2
demo-vm fms01-palmbeta fmsa fmsb fmse fms-embarq fmsf fmsg fmsh fmsi
fmsj fmsk fmso fmsp fmsq fmsr fmss fmsp1 fmsp2 frogger log02-palmbeta
pagea pageb pagec paged pagee pageg pageh pagej pageo pagep palmweb01
straylight sync02-palmbeta synca syncb synce sync-embarq syncf syncg
synch synci syncj synck syncl syncn syncp straylight frogger sawmill/;

map { $machines{$_} = 'fusion123' } qw/vz-fms01 vz-fms02 vz-page01
vz-page02 vz-sync01 vz-sync02 vz-db01 vz-db02/;

# ducati fmsab fmsl pagel pageq vm-fms vm-page ops

my @telus = ();#qw/172.26.23.11 172.26.23.12 172.26.23.13 172.26.23.139/;

### Main

my $ethernet = new Fusionone::Ethernet;
my $hosts    = new Fusionone::Hosts;

for my $host ( sort keys %machines ) {
  my ($stdout, $stderr, $exit, $ssh);

  eval {
    $ssh = Net::SSH::Perl->new($host,( protocol=>'2,1',  debug => 1 ));
    $ssh->login('root',$machines{$host});
  };

  if ($@) { print "$host: connection failed.\n$@"; next; }

  ($stdout, $stderr, $exit) = $ssh->cmd('uname -m');

  chomp $stdout;
  my $arch = $stdout;

  ($stdout, $stderr, $exit) = $ssh->cmd('uname -s');

  chomp $stdout;
  my $os = $stdout;

  ($stdout, $stderr, $exit) = $ssh->cmd('uname -r');

  chomp $stdout;
  my $os_version = $stdout;

  ($stdout, $stderr, $exit) = $ssh->cmd('date +%Z');

  chomp $stdout;
  my $tz = $stdout;

  print "$host : $os $os_version ($arch)\n";

  my $possible = $hosts->by_name($host);

  print " Possible hosts: " . join(',',@$possible) . "\n";

  my $id;

  if ( scalar(@$possible) < 1 ) {
    $id = $hosts->add({
      arch => $arch,
      name => $host,
      os => $os,
      osversion => $os_version,
      tz => $tz
    });
    print " Added host: $id\n";
  } elsif ( scalar(@$possible) == 1 ) {
    $id = $possible->[0];
    my $ret = $hosts->update($id,{
      arch => $arch,
      name => $host,
      os => $os,
      osversion => $os_version,
      tz => $tz
    });
    print " Update returned $ret\n";
  }

  # Linux   

  next unless $os eq 'Linux';
  
  my $snmp = &is_running_linux($ssh,'snmpd');
  my $ntp  = &is_running_linux($ssh,'ntpd');

  my $ret = $hosts->update($id,{
    snmp => $snmp,
    ntp  => $ntp,
  });
  print " Update returned $ret (ntp,snmp)\n";

  my $ntphost;

  if ( $ntp == 1 ) {
    ($stdout,$stderr,$exit) = $ssh->cmd('egrep \'^server\' /etc/ntp.conf | grep -v 127.127.1.0 | head -1');
    chomp $stdout;

    if ( $stdout =~ /^server\s+(\S+)/ ) {
      $ntphost = $1;
      my $ret = $hosts->update($id,{ ntphost => $ntphost });
      print " Update returned $ret (ntphost)\n";
    }
  }

  my $snmp_community;

  if ( $snmp == 1 ) {
    ($stdout,$stderr,$exit) = $ssh->cmd('egrep \'^com2sec.*notConfigUser.*default\' /etc/snmp/snmpd.conf');
    chomp $stdout;

    if ( $stdout =~ /\s+(\S+)\s*$/ ) {
      $snmp_community = $1;
      my $ret = $hosts->update($id,{ snmp_community => $snmp_community });
      print " Update returned $ret (snmp_community)\n";
    }
  }

  my %dev = &net_devices_linux($ssh);  
  for my $dev ( keys %dev ) {
    next if $dev{$dev} =~ /00.00.00.00.00.00/;
    if ( $ethernet->exists($dev{$dev}) ) {
      my $ret = $ethernet->update($dev{$dev},{ host_id => $id, host_interface => $dev });
      print " Update returned $ret ($dev)\n";
    } else {
      my $ret = $ethernet->add({ address => $dev{$dev}, host_id => $id, host_interface => $dev });
      print " Insert returned $ret ($dev)\n";
    }
  }
}

### Subroutines

# is a service running

sub is_running_linux {
  my $ssh  = shift @_;
  my $serv = shift @_;
  my ($stdout, $stderr, $exit) = $ssh->cmd('chkconfig --list '.$serv);
  chomp $stdout;

  return -1 unless $stdout =~ /\w+\s+0:\w+\s+1:\w+\s+2:\w+\s+3:(\w+)\s+4:\w+\s+5:(\w+)\s+6:\w+/;

  return 1 if $1 eq 'on' and $2 eq 'on';
  return 0 if $1 eq 'off' and $2 eq 'off';

  warn "Service $serv is configured badly. ($1:$2)";

  return -1;
}

sub net_devices_linux {
  my $ssh  = shift @_;
  my ($stdout, $stderr, $exit) = $ssh->cmd('ifconfig -a | grep HWaddr');

  my %out;

  for my $line ( split /\n/, $stdout ) {
    next unless $line =~ /(\w+\d+)(:\d+)?\s+.+HWaddr\s+([0-9A-Fa-f:]+)/;
    $out{$1} = $3;
  }

  return %out;
}
