#!/usr/bin/perl -I../lib

# --quiet option shuts up everything but the change report.
# Other argv's will become the machines to process

# --noconfigsave will stop the config save
# --config=foo Deal only with the textconfig foo.
# --noreport will skip emailing the change report.

# $Id: grab.pl,v 1.50 2008/08/22 06:19:37 ppollard Exp $

use Horus::Network;
use Horus::Hosts;

use Getopt::Long;
use Net::SSH::Expect;
use Net::SSH::Perl;

use Text::Diff;

require Math::BigInt::GMP; # For speed on Net::SSH::Perl;

use strict;

### Parse ARGV

my $use_expect = 0;

my $config_to_save = undef;           # --config=foo, Override what config to process
my $email = 'dcops@fusionone.com';    # --email=foo, Email that change report is sent to
my $noconfigsave = 0;                 # --noconfigsave, do not update configs in the DB
my $noreport = 0;                     # --noreport, supress emailing the change report
my $subject = 'Server Change Report'; # --subject, change the report email subject line
my $quiet = 0;                        # --quiet, supress STDOUT run-time info

my $ret = GetOptions(
            'config=s' => \$config_to_save, 'email=s' => \$email,  noconfigsave => \$noconfigsave,
            noreport => \$noreport, 'subject=s' => \$subject, quiet => \$quiet
);

debug( $noreport ? "Report will NOT be sent.\n" : "Report will go to $email\n" );
debug("Configs will NOT be saved.\n") if $noconfigsave;
debug("Only checking for the following config: $config_to_save\n") if $config_to_save;
debug("\n");

### Global Vars

my $ver = (split ' ', '$Revision: 1.50 $')[1];

my %uptime; # Track uptimes for the report

### Sort out the hosts

my $fh = new Horus::Hosts;
my %all = $fh->all();

my @override;

if ( scalar @ARGV ) {
  for my $name (@ARGV) {
    my @possible = $fh->by_name($name);
    push @override, $possible[0] if $possible[0];
  }
}

### Main

my $network = new Horus::Network;
my $hosts = new Horus::Hosts;

our $ssh;

my %changes;
my %skipped;

for my $hostid ( scalar @override ? sort @override : sort { lc($all{$a}) cmp lc($all{$b}) } keys %all ) {
  my $ref = $fh->get($hostid);
  if ( $ref->{skip} > 0 ) {
    $skipped{$hostid}++;
    next;
  }

  my $ret = &open_connection($hostid);
  next unless $ret;

  $changes{$hostid}{changes} = {};

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
    $type = 'DB'   if $ref->{name} =~ /db/i;
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
    warn "Can't parse the uptime string for time info." unless $uptime =~ /up(\s.+\s)\d+ user/;
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

    $uptime{$hostid}{years} = $years;
    $uptime{$hostid}{days} = $days;    
    $uptime{$hostid}{hours} = $hours;    
    $uptime{$hostid}{mins} = $mins;
    $uptime{$hostid}{string} = $years ? sprintf('%d years, %d days, %02d:%02d', $years, $days, $hours, $mins)
                             : $days  ? sprintf('%d days, %02d:%02d', $days, $hours, $mins)
                             : sprintf('%02d:%02d', $hours, $mins);
  }

  # configs
  
  my @configs = qw@/etc/fstab /etc/named.conf /etc/sudoers /etc/issue /etc/passwd /etc/snmp/snmpd.conf 
                   /etc/sysconfig/network /etc/resolv.conf /etc/ssh/sshd_config /etc/selinux/config 
                   /etc/yum.conf /etc/hosts /fusionone/tomcat/conf/server.xml /etc/motd /etc/issue.net
                   /fusionone/apache/conf/httpd.conf /etc/bashrc /etc/profile /etc/rc.d/rc.local
                   /fusionone/bin/f1 /etc/nsswitch.conf /etc/pam.d/system-auth /etc/sysconfig/authconfig
                   /root/.bash_profile /root/.bash_logout /root/.bashrc /etc/sysconfig/iptables-config
                   /etc/sysconfig/iptables /etc/sysconfig/vmware-release
                   /fusionone/smfe/server/default/data/pingfederate-admin-user.xml
                   /fusionone/webapp/mb/WEB-INF/classes/pfagent.propertries
                   /root/.ssh/authorized_keys /root/.ssh/authorized_keys2
                   /fusionone/webapps/admin/WEB-INF/classes/papi.properties@;

  for my $type ( qw/ifcfg route/ ) {
    for my $eth ( qw/eth0 eth1/ ) {
      push @configs, "/etc/sysconfig/network-scripts/$type-$eth";
    }
  }

  @configs = ( $config_to_save ) if $config_to_save;

  for my $config ( @configs ) {
    my $data = run("if [ -f $config ]; then cat $config; fi");
    if ( $data ) {
      my $old = $hosts->config_get($hostid,$config);
      my $diff = diff(\$old,\$data, { STYLE => "Table" });

      if ( $diff ) {
        $diff = "Note: No data previously stored for this file.\n" . $diff unless $old;      
        $changes{$hostid}{changes}{$config} = $diff;
      }
      my $ret = $noconfigsave ? 'X' : $hosts->config_set($hostid,$config,$data);
      debug(" Update returned $ret ($config)\n");
    }
  }
  
  # Linux

  next unless $os eq 'Linux';
  
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
    my $file = '/var/run/f1/' . $run;
    my $data = run("if [ -f $file ]; then cat $file; fi");
    next unless $data;
    my $ret = $hosts->data_set($hostid,$run,$data);
    debug(" Update returned $ret ($run)\n");
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
    my $ret = $hosts->update($hostid,{ machine_brand => $machine_brand });
    debug(" Update returned $ret (machine_brand)\n");
  }

  if ( $machine_model ) {
    my $ret = $hosts->update($hostid,{ machine_model => $machine_model });
    debug(" Update returned $ret (machine_model)\n");
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

&change_report();

### SSH Subroutines

# Open a connection
sub open_connection {
  my $hostid = shift @_;
  my $ref = $fh->get($hostid);

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

sub change_report {
  my $detail;
  
  # Uptimes
 
  my @uptimes = sort { $uptime{$b}{years} <=> $uptime{$a}{years} || $uptime{$b}{days} <=> $uptime{$a}{days} || $uptime{$b}{hours} <=> $uptime{$a}{hours} || $uptime{$b}{mins} <=> $uptime{$a}{mins} } keys %uptime;
  my @best_uptime = map { $uptimes[$_] if  $uptimes[$_] } ( 0 .. 9 );
  my @worst_uptime = map { pop @uptimes if scalar(@uptimes) } ( 0 .. 9 );
 
  my $best_uptime = '<ul>';
  for my $up (@best_uptime) {
    $best_uptime .= "<li> $uptime{$up}{string} - <b>".&href($all{$up})."</b>\n";
  }
  $best_uptime .= '</ul>';

  my $worst_uptime = '<ul>';
  for my $up (@worst_uptime) {
    $worst_uptime .= "<li> $uptime{$up}{string} - <b>".&href($all{$up})."</b>\n";
  }
  $worst_uptime .= '</ul>';
   
  # Sort out what hosts changed, didn't change, and were skipped
 
  my @nochange; my @change;
  for my $hostid ( sort keys %changes ) {
    my $count = scalar(keys %{$changes{$hostid}{changes}});
    my $host = $all{$hostid};
    if ( $count ) {
      push @change, $host; #"<a href='#$host'>$host</a>";
      $detail .= "\n<p><b><font size='+1'><a name='#$host'></a>$host</font></b></p>\n";
      $detail .= "\n<p>$count config changes noted.</p>\n";
      for my $file ( sort keys %{$changes{$hostid}{changes}} ) {
        my $table = &reformat_table($changes{$hostid}{changes}{$file});
        $detail .= "\nFile: <tt>$file</tt><br />\n$table\n";
      }
    } else {
      push @nochange, $host unless $skipped{$hostid};
    }
  }

  my @skip = sort map { $all{$_} } keys %skipped;

  # Print the report

  open REPORT, '>/tmp/change.html';
  print REPORT "To: $email\nFrom: horus\@horus.fusionone.com\nSubject: $subject\nContent-Type: text/html; charset=\"us-ascii\"\n\n";
  print REPORT "<html><body>\n\n";

  print REPORT "<hr noshade /><font size='+2'><b>Change Report</b></font><hr noshade />\n"
             . scalar(localtime)."<br /><small>Report version $ver</small>\n"
             . "<p>Changes were found on these hosts:</p><blockquote>" . join(', ', map {&href($_)} @change ) . "</blockquote>\n"
             . "<p>We skipped checking the following hosts:</p><blockquote>" . join(', ', map {&href($_)} @skip ) . "</blockquote>\n"
             . "<p>The following hosts appear unchaged:</p><blockquote>".  join(', ', map {&href($_)} @nochange ) . "</blockquote>\n";

  print REPORT "<hr noshade /><font size='+2'><b>General Stats</b></font><hr noshade />\n"
             . "<p>Highest uptimes:</p>$best_uptime<p>Lowest uptimes:</p>$worst_uptime";

  print REPORT "<hr noshade /><font size='+2'><b>Change Detail</b></font><hr noshade />\n" if $detail;

  print REPORT '<table border="0" bgcolor="#000000" cellpadding="0" cellspacing="0"><tr><td><table border="0" bgcolor="#000000" cellpadding="5" cellspacing="1">'
             . '<tr><td bgcolor="#666699"><b>Color Key</b></td></tr>'
             . '<tr><td bgcolor="#FFFACD">This is a modified line.</td></tr>'
             . '<tr><td bgcolor="#99CC99">This is a new line.</td></tr>'
             . '<tr><td bgcolor="#CC9999">This is a deleted line.</td></tr>'
             . '</table></td></tr></table>' if $detail;

  print REPORT $detail if $detail;
  
  print REPORT "\n</body></html>\n";
  close REPORT;

  exec("/usr/sbin/sendmail $email < /tmp/change.html") unless $noreport;
  
  print "Skipping emaling the report.\n";
}

sub debug {
  return if $quiet;
  print STDERR @_;
}

sub href {
  return '<a href=\'http://horus.fusionone.com/index.cgi/host/'.$_[0].'\'>'.$_[0]."</a>\n";
}

# Reformat the diff table to HTML
sub reformat_table {
  my $raw = shift @_;
  chomp $raw;
  
  my $out = '<table border="0" bgcolor="#000000" cellpadding="0" cellspacing="0"><tr><td><table border="0" bgcolor="#000000" cellpadding="5" cellspacing="1">';
  my $header = '<tr><td bgcolor="#666699">Line</td><td bgcolor="#666699">Old Data</td><td bgcolor="#666699">Line</td><td bgcolor="#666699">New Data</td></tr>';

  $out .= $header;

  my @lines = split "\n", $raw;

  if ( $lines[0] =~ /^Note/ ) { # new file

    $header = '<tr><td bgcolor="#666699">Line</td><td bgcolor="#666699">New Data</td></tr>';
    $out = ( shift @lines ) ."\n". '<table border="0" bgcolor="#000000" cellpadding="0" cellspacing="0"><tr><td><table border="0" bgcolor="#000000" cellpadding="5" cellspacing="1">' . $header;

    $lines[0] =~ /\+([\-]+)\+([\-]+)\+([\-]+)\+([\-]+)\+/ or die "Bad parse on new lines?!";

    my $l1 = length($1); # Use the top line to measure
    my $v1 = length($2); # text width to parse out line
    my $l2 = length($3); # numbers and data
    my $v2 = length($4);

    shift @lines; pop @lines; # remove top and bottom border

    for my $line ( @lines ) {
      warn "BAD TABLE PARSE!" and return '<pre>'.$raw.'</pre>' unless
        $line =~ /([\|\*\+])(.{$l1})([\|\*\+])(.{$v1})([\|\*\+])(.{$l2})([\|\*\+])(.{$v2})([\|\*\+])/;
      my ($col1,$line1,$col2,$val1,$col3,$line2,$col4,$val2,$col5) = ($1,$2,$3,$4,$5,$6,$7,$8,$9);

      $out .= $header and next if $col1 eq '+'; # Breaker row.

      $val1 =~ s/</&lt;/g;   $val1 =~ s/>/&gt;/g;   # Safe HTML viewing
      $val2 =~ s/</&lt;/g;   $val2 =~ s/>/&gt;/g;   #
      $val1 =~ s/ /&nbsp;/g; $val2 =~ s/ /&nbsp;/g; #

      $out .= "<tr><td bgcolor='#99CC99' align='center'><tt>$line2</tt></td>\n<td bgcolor='#99CC99' nowrap><tt>$val2</tt></td></tr>\n";
      }
    $out .= '</table></td></tr></table>';

    return $out;


  } elsif ( $lines[0] =~ /\+([\-]+)\+([\-]+)\+([\-]+)\+([\-]+)\+/ ) { # 4 column change table
    my $l1 = length($1); # Use the top line to measure
    my $v1 = length($2); # text width to parse out line
    my $l2 = length($3); # numbers and data
    my $v2 = length($4);
    
    shift @lines; pop @lines; # remove top and bottom border
    
    for my $line ( @lines ) {
      warn "BAD TABLE PARSE!" and return '<pre>'.$raw.'</pre>' unless
        $line =~ /([\|\*\+])(.{$l1})([\|\*\+])(.{$v1})([\|\*\+])(.{$l2})([\|\*\+])(.{$v2})([\|\*\+])/;
      my ($col1,$line1,$col2,$val1,$col3,$line2,$col4,$val2,$col5) = ($1,$2,$3,$4,$5,$6,$7,$8,$9);

      $out .= $header and next if $col1 eq '+'; # Breaker row.

      $val1 =~ s/</&lt;/g;   $val1 =~ s/>/&gt;/g;   # Safe HTML viewing
      $val2 =~ s/</&lt;/g;   $val2 =~ s/>/&gt;/g;   #
      $val1 =~ s/ /&nbsp;/g; $val2 =~ s/ /&nbsp;/g; #

      my $color1 = '#FFFFFF';
      my $color2 = '#FFFFFF';

      $color1 = $color2 = '#FFFACD' if $col1 eq '*' and $col5 eq '*'; # Line modified
      $color1 = '#CC9999' if $col1 eq '*' and $col3 eq '*' and $col5 eq '|'; # Line deleted
      $color2 = '#99CC99' if $col1 eq '|' and $col3 eq '*' and $col5 eq '*'; # Line added
      
      $out .= "<tr><td bgcolor='$color1' align='center'><tt>$line1</tt></td>\n<td bgcolor='$color1' nowrap><tt>$val1</tt></td>\n<td bgcolor='$color2' align='center'><tt>$line2</tt></td>\n<td bgcolor='$color2' nowrap><tt>$val2</tt></td></tr>\n"
    }
    $out .= '</table></td></tr></table>';

    return $out;

  } elsif ( $lines[0] =~ /\+([\-]+)\+([\-]+)\+([\-]+)\+/ ) { # 3 column change table
    my $l1 = length($1); # Use the top line to measure
    my $v1 = length($2); # text width to parse out line
    my $v2 = length($3); # numbers and data

    shift @lines; pop @lines; # remove top and bottom border
    
    for my $line ( @lines ) {
      warn "BAD TABLE PARSE!" and return '<pre>'.$raw.'</pre>' unless
        $line =~ /([\|\*\+])(.{$l1})([\|\*\+])(.{$v1})([\|\*\+])(.{$v2})([\|\*\+])/;
      my ($col1,$line1,$col2,$val1,$col3,$val2,$col5) = ($1,$2,$3,$4,$5,$6,$7);

      my $line2 = $line1; # This format omits the second line number columns

      $out .= $header and next if $col1 eq '+'; # Breaker row.

      $val1 =~ s/</&lt;/g;   $val1 =~ s/>/&gt;/g;   # Safe HTML viewing
      $val2 =~ s/</&lt;/g;   $val2 =~ s/>/&gt;/g;   #
      $val1 =~ s/ /&nbsp;/g; $val2 =~ s/ /&nbsp;/g; #

      my $color1 = '#FFFFFF';
      my $color2 = '#FFFFFF';

      $color1 = $color2 = '#FFFACD' if $col1 eq '*' and $col5 eq '*'; # Line modified
      $color1 = '#CC9999' if $col1 eq '*' and $col3 eq '*' and $col5 eq '|'; # Line deleted
      $color2 = '#99CC99' if $col1 eq '|' and $col3 eq '*' and $col5 eq '*'; # Line added
      
      $out .= "<tr><td bgcolor='$color1' align='center'><tt>$line1</tt></td>\n<td bgcolor='$color1' nowrap><tt>$val1</tt></td>\n<td bgcolor='$color2' align='center'><tt>$line2</tt></td>\n<td bgcolor='$color2' nowrap><tt>$val2</tt></td></tr>\n"
    }
    $out .= '</table></td></tr></table>';

    return $out;

  } else {
    return '<pre>'.$raw.'</pre>';
  }
}
