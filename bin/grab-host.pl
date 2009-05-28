#!/usr/bin/perl -I../lib

# $Id: grab-host.pl,v 1.8 2009/05/28 22:07:39 ppollard Exp $

use Horus::Conf;
use Horus::Network;
use Horus::Hosts;

use Getopt::Long;
use Net::SSH::Expect;
use Net::SSH::Perl;

use Text::Diff;
use Storable;

require Math::BigInt::GMP; # For speed on Net::SSH::Perl;

use strict;

### Global Vars

my $ver = (split ' ', '$Revision: 1.8 $')[1];

my $use_expect = 0;

my $co = '/usr/bin/co'; # RCS utils
my $ci = '/usr/bin/ci';

my $changesref = retrieve('changes.store') or die "CAN'T OPEN CHANGES FILE.";
my $optionsref = retrieve('options.store') or die "CAN'T OPEN OPTIONS FILE.";
my $skippedref = retrieve('skipped.store') or die "CAN'T OPEN SKIP FILE.";
my $uptimeref  = retrieve('uptime.store')  or die "CAN'T OPEN UPTIME FILE.";

my $noconfigsave = $optionsref->{noconfigsave};
my $quiet        = $optionsref->{quiet};
my @configs_to_save = defined $optionsref->{configs_to_save} ? @{ $optionsref->{configs_to_save} } : ();

my $hostid = shift @ARGV;
die "Bad Host ID: \"$hostid\"" unless $hostid =~ /^\d+$/;

### Main

my $conf    = new Horus::Conf;
my $hosts   = new Horus::Hosts;
my $network = new Horus::Network;

our $ssh;

my $ref = $hosts->get($hostid);

if ( $ref->{skip} > 0 ) {
  $skippedref->{$hostid}++;
  &close_configs();
  exit;
}

my $ret = &open_connection($hostid);
exit unless $ret;

$changesref->{$hostid}->{changes} = {};

my $arch = run('uname -m');
debug("ARCH: $arch\n");

my $os; my $os_version; my $os_release;

$os = run('uname -s');
if ( $os =~ /CYGWIN/ ) {
  $os_release = "($os)";

  $os = 'Windows';
  $os_release = '(Cyg NT 5.0)' if $os_release eq '(CYGWIN_NT-5.0)';

  # Check if Boot.ini has more detail
  my $bootini = run('cat /cygdrive/c/boot.ini');
  $os_release = $4 if $bootini =~ /(WINNT|WINDOWS)=\"((Microsoft )?Windows )(.+?)(, Standard)?\" /;
}
debug("OS: $os\n");

$os_version = run('uname -r');
$os_version = 'Cygwin ' . $os_version if $os eq 'Windows';
  
debug("OS VERSION: $os_version\n");

$os_release = run('if [ -f /etc/vmware-release ]; then cat /etc/vmware-release; else if [ -f /etc/redhat-release ]; then cat /etc/redhat-release; fi; fi') unless $os_release;

$os_release = 'CentOS '.$1 if $os_release =~ /CentOS release (\d(\.\d)?) \(Final\)/;

$os_release = 'RH 9' if $os_release =~ /Red Hat Linux release 9 \(Shrike\)/;
$os_release = 'RH'.$1.'L 4' if $os_release =~ /Red Hat Enterprise Linux (\w)S release 4 \(Nahant\)/;

$os_release = 'RH'.$1.'L '.$2.'.'.$3 if $os_release =~ /Red Hat Enterprise Linux (\w)S release (\d) \(\w+ Update (\d)\)/;

$os_release = 'RHEL '.$1.'.'.$2 if $os_release =~ /Red Hat Enterprise Linux Server release (\d)\.(\d) \(/;

$os_release = 'VM ESX '.$1 if $os_release =~ /VMware ESX Server (\d) \(Dali\)/;

$os_release = "$os $os_version" if $os eq 'SunOS' and not $os_release;

debug("OS RELEASE: $os_release\n");

my $tz = run('date +%Z');
debug("TZ: $tz\n");

my $uptime = run('uptime');
debug("UP: $uptime\n");

my $ret = $hosts->update($hostid,{
    arch => $arch,
    #name => $host,
    os => $os,
    osrelease => $os_release,
    osversion => $os_version,
    uptime => $uptime,
    tz => $tz
});
debug(" Update returned $ret\n");

# Type

unless ( $ref->{type} ) {
  my $type;
  $type = 'DB'   if $ref->{name} =~ /db/i or $ref->{name} =~ /mysql/i;
  $type = 'SMFE' if $ref->{name} =~ /smfe/i;
  $type = 'Page' if $ref->{name} =~ /page/i;
  $type = 'Sync' if $ref->{name} =~ /sync/i;
  $type = 'FMS'  if $ref->{name} =~ /fms/i;
  if ( $type ) {
    $ret = $hosts->update($hostid,{ type => $type });
    debug(" Update returned $ret (type)\n");
  }
}

# Category

unless ( $ref->{category} ) {
  my $category;
  $category = 'Demo'       if $ref->{name} =~ /demo/i;
  $category = 'Production' if $ref->{name} =~ /prod/i;
  $category = 'QA'         if $ref->{name} =~ /qa/i;
  $category = 'Test'       if $ref->{name} =~ /test/i;
  $category = 'Validation' if $ref->{name} =~ /v-(fms|page|sync|smfe|db)/i and not $category;
  if ( $category ) {
    $ret = $hosts->update($hostid,{ category => $category });
    debug(" Update returned $ret (category)\n");
  }
}

# Remember uptimes for the change report

if ( $uptime ) {
  warn "Can't parse the uptime string for time info." unless $uptime =~ /up(\s.+\s)(\d+ users,\s+)?load average/;
  my $up = $1;

  my $years = 0;
  my $days  = 0;
  my $hours = 0;
  my $mins  = 0;    
    
  $hours = $1 and $mins = $2 if $up =~ / (\d+):(\d+),/;    

  $days  = $1 if $up =~ / (\d+) day/;
  $hours = $1 if $up =~ / (\d+) hour/;
  $mins  = $1 if $up =~ / (\d+) min/;

  if ( $days > 365 ) {
    $years = int($days/365);
    $days = $days - ($years * 365);
  }

  $uptimeref->{$hostid}->{years} = $years;
  $uptimeref->{$hostid}->{days} = $days;    
  $uptimeref->{$hostid}->{hours} = $hours;    
  $uptimeref->{$hostid}->{mins} = $mins;
  $uptimeref->{$hostid}->{string} = $years ? sprintf('%d years, %d days, %02d:%02d', $years, $days, $hours, $mins)
                                  : $days  ? sprintf('%d days, %02d:%02d', $days, $hours, $mins)
                                  : sprintf('%02d:%02d', $hours, $mins);
}

# RPM list - Builds it as /tmp/packages.txt - Maybe a better way?
  
run('if [ -f /usr/bin/yum ]; then yum list installed | tail --lines=+2 | sed -e "s/ *installed//" > /tmp/packages.txt; fi');
  
# configs
  
my @configs = $conf->config_files();

@configs = ( @configs_to_save ) if scalar @configs_to_save > 0;

for my $config ( @configs ) {
  my $data = run("if [ -f $config ]; then cat $config; fi");
  my $old = $hosts->config_get($hostid,$config);
  my $diff = diff(\$old,\$data, { STYLE => "Table" });    

  if ( $data or $old ) {

    # Config
      
    if ( $diff ) {
      $diff = "Note: No data previously stored for this file.\n" . $diff unless $old;      
      $changesref->{$hostid}->{changes}->{$config} = $diff;
    }
    my $ret = $noconfigsave ? 'X' : $hosts->config_set($hostid,$config,$data);
    debug(" Update returned $ret ($config)\n");

    # RCS

    my $oldrcs = $hosts->config_get_rcs($hostid,$config);
    my $newrcs;
    unlink('/tmp/rcs') if -f '/tmp/rcs';
    unlink('/tmp/rcs,v') if -f '/tmp/rcs,v';

    if ( $oldrcs =~ /^\s*$/ ) {
      open TMPFILE, '>/tmp/rcs';
      print TMPFILE $data;
      close TMPFILE;

      system("echo 'Initial import' | $ci -i -q /tmp/rcs");

      open RCSFILE, '</tmp/rcs,v';
      $newrcs = join('',<RCSFILE>);
      close RCSFILE;

    } else {

      open RCSFILE, '>/tmp/rcs,v';
      print RCSFILE $oldrcs;
      close RCSFILE;

      system("$co -l -q /tmp/rcs");

      open TMPFILE, '>/tmp/rcs';
      print TMPFILE $data;
      close TMPFILE;

      system("$ci -u -q -m'Updated by grab.pl' /tmp/rcs");
        
      open RCSFILE, '</tmp/rcs,v';
      $newrcs = join('',<RCSFILE>);
      close RCSFILE;
    }

    if ( $newrcs and $newrcs ne $oldrcs ) {
      my $ret = $noconfigsave ? 'X' : $hosts->config_set_rcs($hostid,$config,$newrcs);
      debug(" RCS update returned $ret ($config)\n");
    }

    unlink('/tmp/rcs');
    unlink('/tmp/rcs,v');
  }
}

# Brand of HW

my $machine_brand; my $machine_model;

# Try dmidecode for HW info
  
if ( $os eq 'Linux' ) {
  my $dmidecode = run('dmidecode');
  
  if ( $dmidecode =~ /System Information(.+?)Handle/s ) {
    my $systeminfo = $1;

    $machine_brand = $1 if $systeminfo =~ /Manufacturer: (.+?)$/m;
    $machine_model = $1 if $systeminfo =~ /Product Name: (.+?)$/m;

    $machine_brand = 'Penguin' if $machine_brand eq 'InventecESC' or $machine_brand eq 'To Be Filled By O.E.M.';

    $machine_model = 'Altus 1300'   if $machine_brand eq 'Penguin' and $machine_model eq 'IR2300';
    $machine_model = 'Altus 1600SS' if $machine_brand eq 'Penguin' and $machine_model eq 'IR2400';
    $machine_model = 'Altus 2200'   if $machine_brand eq 'Penguin' and $machine_model eq 'IR2350';
    
    $machine_brand = 'VMware' if $machine_brand eq 'VMware, Inc.';
  }

  # Fallback to dmesg

  if ( not $machine_brand and not $machine_model ) {
    my $stdout = run('cat /var/log/dmesg');
    ($machine_brand,$machine_model) = &parse_dmesg($stdout);
  }
}
  
# Solaris - PRTconf

if ( $os eq 'SunOS' ) {
  my $prtconf = run('prtconf');
  if ( $prtconf =~ /System Peripherals \(Software Nodes\):\n\n(.+?)\n/s ) {
     ($machine_brand,$machine_model) = split ',', $1, 2;
  }
}

# Save if we found anything

if ( $machine_brand ) {
  my $ret = $hosts->update($hostid,{ machine_brand => $machine_brand });
  debug(" Update returned $ret (machine_brand)\n");
}

if ( $machine_model ) {
  my $ret = $hosts->update($hostid,{ machine_model => $machine_model });
  debug(" Update returned $ret (machine_model)\n");
}

### RAM

my $ram;

if ( $os eq 'Linux' or $os eq 'VMkernel' ) {
  $ram = run('if [ -e /sbin/esxcfg-info -o -e /usr/sbin/esxcfg-info ]; then esxcfg-info -w | grep "Physical Mem\." | sed -e \'s/[^0123456789]*\([012346789]\)/\1/\'; else if [ -f /proc/meminfo ]; then grep MemTotal /proc/meminfo | sed -e \'s/MemTotal:\s*//\'; fi; fi');
}

if ( $ram ) {

  if ( $ram =~ /^(\d+)( bytes)?$/ ) { # ESX puts info in bytes. Upgrade it to kB
    $ram = sprintf('%d kB', $ram / 1024);
  }

  if ( $ram =~ /^(\d\d\d\d+) kB$/ ) {
    my $mb = $1 / 1000;  
    if ( $mb > 1000 ) {
      $ram = sprintf('%0.2f GB', $mb / 1000 );
    } else {
      $ram = sprintf('%0.2f MB', $mb);
    }
  }
  
  my $ret = $hosts->update($hostid,{ ram => $ram });
  debug(" Update returned $ret (ram)\n");
}

### Linux only from here on

unless ( $os eq 'Linux' ) {
  
  my $snmp = &is_running_linux('snmpd');
  my $ntp  = &is_running_linux('ntpd');

  my $ret = $hosts->update($hostid,{
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
      my $ret = $hosts->update($hostid,{ ntphost => $ntphost });
      debug(" Update returned $ret (ntphost)\n");
    }
  }

  # SNMP host

  my $snmp_community;

  if ( $snmp == 1 ) {
    my $stdout = run('egrep \'^com2sec.*notConfigUser.*default\' /etc/snmp/snmpd.conf');

    if ( $stdout =~ /\s+(\S+)\s*$/ ) {
      $snmp_community = $1;
      my $ret = $hosts->update($hostid,{ snmp_community => $snmp_community });
      debug(" Update returned $ret (snmp_community)\n");
    }
  }

  # Last run times
  
  for my $run( qw/last_backup last_ostune last_yum/ ) {
    my $file = '/var/f1/' . $run;
    my $data = run("if [ -f $file ]; then cat $file; fi");
    next unless $data;
    my $ret = $hosts->data_set($hostid,$run,$data);
    debug(" Update returned $ret ($run)\n");
  }

  # Net devices

  my %dev = &net_devices_linux($ssh);  
  for my $dev ( keys %dev ) {
    next if $dev{$dev} =~ /00.00.00.00.00.00/;
    if ( $network->exists($dev{$dev}) ) {
      my $ret = $network->update($dev{$dev},{ host_id => $hostid, host_interface => $dev });
      debug(" Update returned $ret ($dev)\n");
     } else {
      my $ret = $network->add({ address => $dev{$dev}, host_id => $hostid, host_interface => $dev });
      debug(" Insert returned $ret ($dev)\n");
    }
  }
}

&close_configs;

### SSH Subroutines

# Open a connection
sub open_connection {
  my $hostid = shift @_;
  my $ref = $hosts->get($hostid);

  my $host = $ref->{name};
  my $user = $ref->{username};
  my $pass = $ref->{password};

  $user = 'root' unless length $user;

  debug("\nTrying $host " .( $user && $pass ? 'with' : 'without' ). " a password\n");

  if ( $use_expect ) {

    my $conf = {
      host => $host,
      user => $user,
      raw_pty => 1,
      timeout => 2
    };

    $conf->{password} = $pass if $pass;

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

   my @conf = (protocol=>'2,1', debug=>0);
   push @conf, 'identity_files' => [] if length $user and length $pass;
  
    our $ssh = Net::SSH::Perl->new($host, @conf );
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

sub close_configs {
  store $changesref, 'changes.store';
  store $optionsref, 'options.store';
  store $skippedref, 'skipped.store';
  store $uptimeref, 'uptime.store';
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

# Where are the net devices
sub net_devices_linux {
  my $stdout = run('ifconfig -a | grep HWaddr');

  my %out;

  for my $line ( split /\n/, $stdout ) {
    next unless $line =~ /(\w+\d+)(:\d+)?\s+.+HWaddr\s+([0-9A-Fa-f:]+)/;
    $out{$1} = $3;
  }

  return %out;
}

### Subroutines

sub debug {
  return if $quiet;
  print STDERR @_;
}

# dmesg is the fallback to try and figure out hardware info

sub parse_dmesg {
  my $stdout = shift @_;
  my $machine_brand; my $machine_model;
  
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

  return ( $machine_brand, $machine_model );
}
