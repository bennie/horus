#!/usr/bin/perl -I../lib

use Fusionone::Ethernet;
use Fusionone::Hosts;

use Net::SSH::Expect;
use strict;

my $use_expect = 1;

my %machines;

my $fh = new Fusionone::Hosts;
my %all = $fh->all();

for my $id ( keys %all ) {
  $machines{$all{$id}} = undef;
}

map { $machines{$_} = 'fusion123' } qw/vz-fms01 vz-fms02 vz-page01
vz-page02 vz-sync01 vz-sync02 vz-db01 vz-db02/;

map { $machines{$_} = 'g00df3ll45' } qw/alqa alqa-fms01 alqa-page01 
alqa-sync01 bmqa-fms bmqa-page bmqa-sync/;

### Main

my $ethernet = new Fusionone::Ethernet;
my $hosts    = new Fusionone::Hosts;

our $ssh;

for my $host ( sort keys %machines ) {
  my $conf = {
    host => $host,
    user => 'root',
    raw_pty => 1
  };

  $conf->{password} = $machines{$host} if $machines{$host};

  print "\nTrying $host " .( $conf->{password} ? 'with' : 'without' ). " a password\n";

  our $ssh = Net::SSH::Expect->new(%$conf);

  if ( $conf->{password} ) {
    my $logintext = $ssh->login();
    if ( $logintext !~ /Welcome/ ) {
      die "Login failed: \n\n$logintext\n\n";
    }
  } else {
    $ssh->run_ssh() or die "SSH Process couldn't start: $!";
    my $read = $ssh->read_all(2);
    unless ( $read =~ /[>\$\#]\s*\z/ ) {
      warn "Where is the remote prompt? $read";
      next;
    }
  }

  $ssh->exec("stty raw -echo"); # Turn off echo

  my $arch = run('uname -m');
  print "ARCH: $arch\n";

  my $os = run('uname -s');
  my $release = run('if [ -f /etc/redhat-release ]; then cat /etc/redhat-release; fi');

  $os = 'RHEL 4.6' if $release =~ /Red Hat Enterprise Linux ES release 4 \(Nahant Update 6\)/;
  $os = 'CentOS 4.6' if $release =~ /CentOS release 4.6 \(Final\)/;
  print "OS: $os\n";

  warn "Unknown release: $release" if $os eq 'Linux' and length $release;

  my $os_version = run('uname -r');
  print "OS VERSION: $os_version\n";  

  my $tz = run('date +%Z');
  print "TZ: $tz\n";

  my $possible = $hosts->by_name($host);
  print " Possible host ids: " . join(',',@$possible) . "\n";

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
  
  my $snmp = &is_running_linux('snmpd');
  my $ntp  = &is_running_linux('ntpd');

  my $ret = $hosts->update($id,{
    snmp => $snmp,
    ntp  => $ntp,
  });
  print " Update returned $ret (ntp,snmp)\n";

  my $ntphost;

  if ( $ntp == 1 ) {
    my $stdout = run('egrep \'^server\' /etc/ntp.conf | grep -v 127.127.1.0 | head -1');

    if ( $stdout =~ /^server\s+(\S+)/ ) {
      $ntphost = $1;
      my $ret = $hosts->update($id,{ ntphost => $ntphost });
      print " Update returned $ret (ntphost)\n";
    }
  }

  my $snmp_community;

  if ( $snmp == 1 ) {
    my $stdout = run('egrep \'^com2sec.*notConfigUser.*default\' /etc/snmp/snmpd.conf');

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

# Run a command on the remote host
sub run {
  my $command = shift @_;
  our $ssh;

  if ( $use_expect ) {
    my @ret = split "\n", $ssh->exec($command);
    pop @ret;
    return join("\n",@ret);
  } else {
    my ($stdout,$stderr,$exit) = $ssh->cmd($command);
    chomp $stdout;
    return $stdout;
  }
}

# is a service running
sub is_running_linux {
  my $serv = shift @_;

  my $stdout = run('chkconfig --list '.$serv);

  return -1 unless $stdout =~ /\w+\s+0:\w+\s+1:\w+\s+2:\w+\s+3:(\w+)\s+4:\w+\s+5:(\w+)\s+6:\w+/;

  return 1 if $1 eq 'on' and $2 eq 'on';
  return 0 if $1 eq 'off' and $2 eq 'off';

  warn "Service $serv is configured badly. ($1:$2)";

  return -1;
}

sub net_devices_linux {
  my $stdout = run('ifconfig -a | grep HWaddr');

  my %out;

  for my $line ( split /\n/, $stdout ) {
    next unless $line =~ /(\w+\d+)(:\d+)?\s+.+HWaddr\s+([0-9A-Fa-f:]+)/;
    $out{$1} = $3;
  }

  return %out;
}
