#!/usr/bin/perl -I../lib

# $Id: grab.pl,v 1.17 2008/07/23 18:39:23 ppollard Exp $

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
alqa-sync01 bmqa-fms bmqa-page bmqa-sync nwhqa-fms nwhqa-page nwhqa-sync/;

### Main

my $ethernet = new Fusionone::Ethernet;
my $hosts    = new Fusionone::Hosts;

our $ssh;

for my $host ( sort keys %machines ) {
  my $conf = {
    host => $host,
    user => 'root',
    raw_pty => 1,
    timeout => 2
  };

  $conf->{password} = $machines{$host} if $machines{$host};

  print "\nTrying $host " .( $conf->{password} ? 'with' : 'without' ). " a password\n";

  our $ssh = Net::SSH::Expect->new(%$conf);

  if ( $conf->{password} ) {

    my $logintext;
    eval { $logintext = $ssh->login(); };
    if ( $@ ) { warn $@; next; }

    if ( $logintext !~ /Welcome/ and $logintext !~ /Last login/ ) {
      die "Login failed: \n\n$logintext\n\n";
    }

  } else {

    unless ( $ssh->run_ssh() ) {
      warn "SSH Process couldn't start: $!";
      next;
    }

    my $read;
    eval { $read = $ssh->read_all(2); };
    if ( $@ ) { warn $@; next; }

    unless ( $read =~ /[>\$\#]\s*\z/ ) {
      warn "Where is the remote prompt? $read";
      next;
    }

  }

  $ssh->exec("stty raw -echo"); # Turn off echo

  my $arch = run('uname -m');
  print "ARCH: $arch\n";

  my $os = run('uname -s');
  print "OS: $os\n";

  my $os_release = run('if [ -f /etc/redhat-release ]; then cat /etc/redhat-release; fi');

  $os_release = 'RH'.$1.'L 4' if $os_release =~ /Red Hat Enterprise Linux (\w)S release 4 \(Nahant\)/;
  $os_release = 'RH'.$1.'L 4.'.$2 if $os_release =~ /Red Hat Enterprise Linux (\w)S release 4 \(Nahant Update (\d)\)/;
  $os_release = 'CentOS 4.6' if $os_release =~ /CentOS release 4.6 \(Final\)/;
  $os_release = 'CentOS 5'   if $os_release =~ /CentOS release 5 \(Final\)/;
  print "OS RELEASE: $os_release\n";  

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
      osrelease => $os_release,
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
      osrelease => $os_release,
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

  # Brand of HW

  my $machine_brand;

  my $stdout = run('cat /var/log/dmesg');

  if ( $stdout =~ /ACPI:\s+MCFG\s+\(v001\s+HP\s+ProLiant/ ) {
    $machine_brand = 'HP';
  }

  if ( $stdout =~ /ACPI: MCFG \(v001 IBM/ ) {
    $machine_brand = 'IBM';
  }

  if ( $stdout =~ /ACPI: RSDP \(v000 ACPIAM                                \) \@ 0x00000000000f8140/ && $stdout =~ /ACPI: RSDT \(v001 A M I  OEMRSDT  0x05000631 MSFT 0x00000097\) \@ 0x00000000cfff0000/ && $stdout =~ /ACPI: FADT \(v002 A M I  OEMFACP  0x05000631 MSFT 0x00000097\) \@ 0x00000000cfff0200/ && $stdout =~ /ACPI: MADT \(v001 A M I  OEMAPIC  0x05000631 MSFT 0x00000097\) \@ 0x00000000cfff0390/ && $stdout =~ /ACPI: SPCR \(v001 A M I  OEMSPCR  0x05000631 MSFT 0x00000097\) \@ 0x00000000cfff0420/ && $stdout =~ /ACPI: OEMB \(v001 A M I  AMI_OEM  0x05000631 MSFT 0x00000097\) \@ 0x00000000cfffe040/ && $stdout =~ /ACPI: DSDT \(v001  TUNA_ TUNA_160 0x00000160 INTL 0x02002026\) \@ 0x0000000000000000/ ) {
    $machine_brand = 'Penguin';
  }

  if ( $machine_brand ) {
    my $ret = $hosts->update($id,{ machine_brand => $machine_brand });
    print " Update returned $ret (machine_brand)\n";
  }

  # Net devices

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
