=head1 Horus::Conf (Conf.pm)

=cut

package Horus::Conf;

use strict;

$Horus::Conf::VERSION = '$Revision: 1.5 $';

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
  my @configs = qw@/etc/fstab /etc/vfstab /etc/named.conf /etc/sudoers /etc/issue
  /etc/passwd /etc/snmp/snmpd.conf /etc/sysconfig/network /etc/resolv.conf
  /etc/ssh/sshd_config /etc/selinux/config /etc/yum.conf /etc/hosts
  /fusionone/tomcat/conf/server.xml /etc/motd /etc/issue.net
  /fusionone/apache/conf/httpd.conf /etc/bashrc /etc/profile /etc/rc.d/rc.local
  /fusionone/bin/f1 /etc/nsswitch.conf /etc/pam.d/system-auth
  /etc/sysconfig/authconfig /root/.bash_profile /root/.bash_logout /root/.bashrc
  /etc/sysconfig/iptables-config /etc/sysconfig/iptables
  /root/.ssh/authorized_keys2 /etc/VRTSvcs/conf/config/main.cf
  /fusionone/sync/classes_ce.inf /etc/sysconfig/vmware-release
  /etc/httpd/conf/httpd.conf /etc/vmware/license.cfg /etc/vmware/esx.conf
  /root/.ssh/authorized_keys
  /fusionone/smfe/server/default/data/pingfederate-admin-user.xml
  /fusionone/webapp/mb/WEB-INF/classes/pfagent.propertries
  /fusionone/webapps/admin/WEB-INF/classes/papi.properties
  /fusionone/webapps/fms/WEB-INF/classes/f1papi.conf@;

  push @configs, '/tmp/packages.txt';

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

  return @configs;
}

=head1 Authorship:

  (c) 2008, Horus, Inc. 

  Work by Phil Pollard
  $Revision: 1.5 $ $Date: 2008/08/23 21:17:02 $

=cut

1;
