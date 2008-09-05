=head1 Horus::Conf (Conf.pm)

=cut

package Horus::Conf;

use strict;

$Horus::Conf::VERSION = '$Revision: 1.7 $';

sub new {
  my     $self = {};
  bless  $self;
         $self->_initialize();
  return $self;
}

sub _initialize {
  my $self = shift @_;
  $self->{debug} = 0;
}

sub DESTROY {
  my $self = shift @_;
}

###
### Private Methods
###

sub _debug {
  my $self = shift @_;
  my $text = shift @_;

  if ($self->{debug} > 0) {
    print "DEBUG: $text\n";
  }  
}

###
### Public Methods
###

=head1 Methods:

=head2 config_files()

Returns an array of files to be tracked.

=cut

sub config_files {
  my @configs = qw@
  /etc/bashrc
  /etc/exports
  /etc/fstab
  /etc/hosts
  /etc/inittab
  /etc/issue
  /etc/issue.net
  /etc/lftp.conf
  /etc/modprobe.conf
  /etc/motd
  /etc/named.conf
  /etc/nsswitch.conf
  /etc/ntp.conf
  /etc/passwd
  /etc/profile
  /etc/resolv.conf
  /etc/sudoers
  /etc/vsftpd.ftpusers
  /etc/vsftpd.user_list
  /etc/vsftpd/vsftpd.conf
  /etc/vfstab
  /etc/xinetd.conf
  /etc/yum.conf

  /etc/pam.d/system-auth
  /etc/rc.d/rc.local
  /etc/selinux/config
  /etc/snmp/snmpd.conf
  /etc/ssh/sshd_config
  /etc/sysconfig/authconfig
  /etc/sysconfig/iptables
  /etc/sysconfig/iptables-config
  /etc/sysconfig/network
  
  /root/.bash_logout
  /root/.bash_profile
  /root/.bashrc
  /root/.ssh/authorized_keys2
  /root/.ssh/authorized_keys
  
  /etc/VRTSvcs/conf/config/main.cf

  /etc/httpd/conf/httpd.conf 

  /etc/sysconfig/vmware-release /etc/vmware/license.cfg /etc/vmware/esx.conf

  /etc/vmware/config /etc/vmware/locations

  /fusionone/apache/conf/httpd.conf
  /fusionone/bin/f1
  /fusionone/smfe/server/default/data/pingfederate-admin-user.xml
  /fusionone/sync/classes_ce.inf
  /fusionone/tomcat/conf/server.xml

  /fusionone/webapp/mb/WEB-INF/classes/pfagent.propertries
  /fusionone/webapp/admin/WEB-INF/classes/papi.properties
  /fusionone/webapp/fms/WEB-INF/classes/f1papi.conf

  /fusionone/webapps/mb/WEB-INF/classes/pfagent.propertries
  /fusionone/webapps/admin/WEB-INF/classes/papi.properties
  /fusionone/webapps/fms/WEB-INF/classes/f1papi.conf
@;

  #push @configs, '/tmp/packages.txt'; # Temp comment out

  for my $type ( qw/ifcfg route/ ) {
    for my $eth ( qw/eth bond/ ) {
      for my $n ( 0 .. 9 ) {
        push @configs, "/etc/sysconfig/network-scripts/$type-$eth$n";
      }
    }
  }

  for my $n ( 0 .. 9 ) {
    for my $eth ( qw/hme qfe/ ) {
      push @configs, '/etc/hostname.' . $eth . $n;
    }
  }

  return sort @configs;
}

=head1 Authorship:

  (c) 2008, Horus, Inc. 

  Work by Phil Pollard
  $Revision: 1.7 $ $Date: 2008/09/05 04:30:40 $

=cut

1;
