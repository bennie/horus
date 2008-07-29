#!/usr/bin/perl -I../lib

# $Id: grab.pl,v 1.30 2008/07/29 00:22:43 ppollard Exp $

use Horus::Network;
use Horus::Hosts;

use Net::SSH::Expect;
use Net::SSH::Perl;

use Text::Diff;

require Math::BigInt::GMP; # For speed on Net::SSH::Perl;

use strict;

my $ver = (split ' ', '$Revision: 1.30 $')[1];

my $use_expect = 0;
my $quiet = 0;

my %machines;
my %skip;

map {$skip{$_}++} qw/fmso fmsq fmsr fmss sync-embarq syncn/;

my $fh = new Horus::Hosts;
my %all = $fh->all();

for my $id ( keys %all ) {
  $machines{$all{$id}} = undef;
}

map { $machines{$_} = 'fusion123' } qw/vz-fms01 vz-fms02 vz-page01
vz-page02 vz-sync01 vz-sync02 vz-db01 vz-db02/;

map { $machines{$_} = 'g00df3ll45' } qw/alqa alqa-fms01 alqa-page01 
alqa-sync01 bmqa-fms bmqa-page bmqa-sync nwhqa-fms nwhqa-page nwhqa-sync
telus-fms01 telus-fms02 telus-page01 telus-page02 telus-sync01 telus-sync02
bmqa-base nwh-fms01/;

$machines{build} = 'dev3695';
$machines{ns1} = 'Bungie1';

map { $machines{$_} = 'mypassword'; } qw/tickets horus/;

### Main

my $network = new Horus::Network;
my $hosts   = new Horus::Hosts;

our $ssh;

my %changes;

for my $host ( scalar @ARGV ? @ARGV : sort keys %machines ) {
  next if $skip{$host};
  my $ret = &open_connection($host,'root',$machines{$host});
  next unless $ret;

  $changes{$host}{changes} = {};

  my $arch = run('uname -m');
  debug("ARCH: $arch\n");

  my $os; my $os_version; my $os_release;

  $os = run('uname -s');
  if ( $os =~ /CYGWIN/ ) {
    $os_release = $os;    
  
    $os = 'Windows';
    $os_release = 'Cyg NT 5.0' if $os_release eq 'CYGWIN_NT-5.0';
  }
  debug("OS: $os\n");

  $os_version = run('uname -r');
  debug("OS VERSION: $os_version\n");

  $os_release = run('if [ -f /etc/vmware-release ]; then cat /etc/vmware-release; else if [ -f /etc/redhat-release ]; then cat /etc/redhat-release; fi; fi') unless $os_release;

  $os_release = 'CentOS '.$1 if $os_release =~ /CentOS release (\d(\.\d)?) \(Final\)/;

  $os_release = 'RH 9' if $os_release =~ /Red Hat Linux release 9 \(Shrike\)/;
  $os_release = 'RH'.$1.'L 4' if $os_release =~ /Red Hat Enterprise Linux (\w)S release 4 \(Nahant\)/;
  $os_release = 'RH'.$1.'L 4.'.$2 if $os_release =~ /Red Hat Enterprise Linux (\w)S release 4 \(Nahant Update (\d)\)/;

  $os_release = 'VM ESX '.$1 if $os_release =~ /VMware ESX Server (\d) \(Dali\)/;

  $os_release = "$os $os_version" if $os eq 'SunOS' and not $os_release;

  debug("OS RELEASE: $os_release\n");

  my $tz = run('date +%Z');
  debug("TZ: $tz\n");

  my $uptime = run('uptime');
  debug("UP: $uptime\n");

  my $possible = $hosts->by_name($host);
  debug(" Possible host ids: " . join(',',@$possible) . "\n");

  my $id;

  if ( scalar(@$possible) < 1 ) {
    $id = $hosts->add({
      arch => $arch,
      name => $host,
      os => $os,
      osrelease => $os_release,
      osversion => $os_version,
      uptime => $uptime,
      tz => $tz
    });
    debug(" Added host: $id\n");
  } elsif ( scalar(@$possible) == 1 ) {
    $id = $possible->[0];
    my $ret = $hosts->update($id,{
      arch => $arch,
      name => $host,
      os => $os,
      osrelease => $os_release,
      osversion => $os_version,
      uptime => $uptime,
      tz => $tz
    });
    debug(" Update returned $ret\n");
  }

  # Linux   

  next unless $os eq 'Linux';
  
  my $snmp = &is_running_linux('snmpd');
  my $ntp  = &is_running_linux('ntpd');

  my $ret = $hosts->update($id,{
    snmp => $snmp,
    ntp  => $ntp,
  });
  debug(" Update returned $ret (ntp,snmp)\n");

  # NTP host

  my $ntphost;

  if ( $ntp == 1 ) {
    my $stdout = run('egrep \'^server\' /etc/ntp.conf | grep -v 127.127.1.0 | head -1');

    if ( $stdout =~ /^server\s+(\S+)/ ) {
      $ntphost = $1;
      my $ret = $hosts->update($id,{ ntphost => $ntphost });
      debug(" Update returned $ret (ntphost)\n");
    }
  }

  # SNMP host

  my $snmp_community;

  if ( $snmp == 1 ) {
    my $stdout = run('egrep \'^com2sec.*notConfigUser.*default\' /etc/snmp/snmpd.conf');

    if ( $stdout =~ /\s+(\S+)\s*$/ ) {
      $snmp_community = $1;
      my $ret = $hosts->update($id,{ snmp_community => $snmp_community });
      debug(" Update returned $ret (snmp_community)\n");
    }
  }

  # Brand of HW

  my $machine_brand; my $machine_model;

  my $stdout = run('cat /var/log/dmesg');
 
  # DL 360
  if ( $stdout =~ /ACPI:\s+MCFG\s+\(v001\s+HP\s+ProLiant/ ) {
    $machine_brand = 'HP';
    $machine_model = 'DL 360';
  }

  # VZ DBs
  if ( $stdout =~ /ACPI: MCFG \(v001 IBM/ ) {
    $machine_brand = 'IBM';
  }

  # VZ Blade
  
  if ( $stdout =~ /ACPI: RSDP \(v000 IBM                                   \) \@ 0x00000000000fdfe0/ && $stdout =~ /ACPI: RSDT \(v001 IBM    SERLEWIS 0x00001000 IBM  0x45444f43\) \@ 0x00000000cffa7380/ && $stdout =~ /ACPI: FADT \(v002 IBM    SERLEWIS 0x00001000 IBM  0x45444f43\) \@ 0x00000000cffa72c0/ && $stdout =~ /ACPI: MADT \(v001 IBM    SERLEWIS 0x00001000 IBM  0x45444f43\) \@ 0x00000000cffa7200/ && $stdout =~ /ACPI: SRAT \(v001 AMD    HAMMER   0x00000001 AMD  0x00000001\) \@ 0x00000000cffa70c0/ && $stdout =~ /ACPI: DSDT \(v001 IBM    SERLEWIS 0x00001000 INTL 0x02002025\) \@ 0x0000000000000000/ ) {
    $machine_brand = 'IBM';
    $machine_model = 'Blade';
  }
  
  # Penguin
  if ( $stdout =~ /ACPI: RSDP \(v000 ACPIAM                                \) \@ 0x00000000000f8140/ && $stdout =~ /ACPI: RSDT \(v001 A M I  OEMRSDT  0x05000631 MSFT 0x00000097\) \@ 0x00000000cfff0000/ && $stdout =~ /ACPI: FADT \(v002 A M I  OEMFACP  0x05000631 MSFT 0x00000097\) \@ 0x00000000cfff0200/ && $stdout =~ /ACPI: MADT \(v001 A M I  OEMAPIC  0x05000631 MSFT 0x00000097\) \@ 0x00000000cfff0390/ && $stdout =~ /ACPI: SPCR \(v001 A M I  OEMSPCR  0x05000631 MSFT 0x00000097\) \@ 0x00000000cfff0420/ && $stdout =~ /ACPI: OEMB \(v001 A M I  AMI_OEM  0x05000631 MSFT 0x00000097\) \@ 0x00000000cfffe040/ && $stdout =~ /ACPI: DSDT \(v001  TUNA_ TUNA_160 0x00000160 INTL 0x02002026\) \@ 0x0000000000000000/ ) {
    $machine_brand = 'Penguin';
    $machine_model = 'Altus 1300';
  }
  
  # VM?
  if ( $stdout =~ /ACPI: FADT \(v001 INTEL  440BX/ && $stdout =~ /ACPI: BOOT \(v001 PTLTD  \$SBFTBL\$/ && $stdout =~ /ACPI: DSDT \(v001 PTLTD  Custom/ ) {
    $machine_brand = 'VM';
    $machine_model = 'ESX';
  }

  if ( $machine_brand ) {
    my $ret = $hosts->update($id,{ machine_brand => $machine_brand });
    debug(" Update returned $ret (machine_brand)\n");
  }

  if ( $machine_model ) {
    my $ret = $hosts->update($id,{ machine_model => $machine_model });
    debug(" Update returned $ret (machine_model)\n");
  }

  # configs
  
  my @configs = qw@/etc/fstab /etc/named.conf /etc/sudoers /etc/issue /etc/passwd /etc/snmp/snmp.conf /etc/sysconfig/network@;
  for my $type ( qw/ifcfg route/ ) {
    for my $eth ( qw/eth0 eth1/ ) {
      push @configs, "/etc/sysconfig/network-scripts/$type-$eth";
    }
  }

  for my $config ( @configs ) {
    my $data = run("if [ -f $config ]; then cat $config; fi");
    if ( $data ) {
      my $old = $hosts->config_get($id,$config);
      my $diff = diff(\$old,\$data, { STYLE => "Table" });

      if ( $diff ) {
        $diff = "Note: No data previously stored for this file.\n" . $diff unless $old;      
        $changes{$host}{changes}{$config} = $diff;
      }
      my $ret = $hosts->config_set($id,$config,$data);
      debug(" Update returned $ret ($config)\n");
    }
  }

  # Net devices

  my %dev = &net_devices_linux($ssh);  
  for my $dev ( keys %dev ) {
    next if $dev{$dev} =~ /00.00.00.00.00.00/;
    if ( $network->exists($dev{$dev}) ) {
      my $ret = $network->update($dev{$dev},{ host_id => $id, host_interface => $dev });
      debug(" Update returned $ret ($dev)\n");
    } else {
      my $ret = $network->add({ address => $dev{$dev}, host_id => $id, host_interface => $dev });
      debug(" Insert returned $ret ($dev)\n");
    }
  }
}

&change_report();

### SSH Subroutines

sub debug {
  return if $quiet;
  print STDERR @_;
}

sub change_report {
  my $detail;
  my @nochange;
  for my $host ( sort keys %changes ) {
    my $count = scalar(keys %{$changes{$host}{changes}});
    if ( $count ) {
      $detail .= "\n================== $host ==================\n";
      $detail .= "\n$count config changes noted.\n";
      for my $file ( sort keys %{$changes{$host}{changes}} ) {
        $detail .= "\nFile: $file\n$changes{$host}{changes}{$file}\n";
      }
    } else {
      push @nochange, $host;
    }
  }

  #print "<pre>\n\n";
  print "CHANGE REPORT: ($ver)\n\nThe following hosts have no identified changes: ", join(', ',@nochange), "\n\n";
  print "CHANGE DETAIL:$detail" if $detail;
  #print "\n\n<\\pre>\n";
}

# Open a connection
sub open_connection {
  my $host = shift @_;
  my $user = shift @_;
  my $pass = shift @_;

  debug("\nTrying $host " .( $pass ? 'with' : 'without' ). " a password\n");

  if ( $use_expect ) {

    my $conf = {
      host => $host,
      user => $user,
      raw_pty => 1,
      timeout => 2
    };

    $conf->{password} = $machines{$host} if $machines{$host};

    our $ssh = Net::SSH::Expect->new(%$conf);

    if ( $conf->{password} ) {
      my $logintext;
      eval { $logintext = $ssh->login(); };
      if ( $@ ) { warn $@; return 0; }

      if ( $logintext !~ /Welcome/ and $logintext !~ /Last login/ ) {
        warn "Login failed: \n\n$logintext\n\n";
        return 0;
      }

    } else {
      unless ( $ssh->run_ssh() ) {
        warn "SSH Process couldn't start: $!";
        return 0;
      }

      my $read;
      eval { $read = $ssh->read_all(2); };
      if ( $@ ) { warn $@; return 0; }

      unless ( $read =~ /[>\$\#]\s*\z/ ) {
        warn "Where is the remote prompt? $read";
        return 0;
      }

      $ssh->exec("stty raw -echo"); # Turn off echo
    }

  } else {
  
    our $ssh = Net::SSH::Perl->new($host, (protocol=>'2,1', debug=>0) );
    eval { $ssh->login($user,$pass); };
    if ( $@ ) { warn $@; return 0; }

  }
  
  return 1;
}

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

### Subroutines

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

# Whar are the net devices
sub net_devices_linux {
  my $stdout = run('ifconfig -a | grep HWaddr');

  my %out;

  for my $line ( split /\n/, $stdout ) {
    next unless $line =~ /(\w+\d+)(:\d+)?\s+.+HWaddr\s+([0-9A-Fa-f:]+)/;
    $out{$1} = $3;
  }

  return %out;
}
