=head1 Horus::Conf (Conf.pm)

=cut

package Horus::Conf;

use strict;

$Horus::Conf::VERSION = '$Revision: 1.26 $';

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
  /cygdrive/c/boot.ini
  
  /etc/aliases
  /etc/bashrc
  /etc/environment
  /etc/exports
  /etc/fstab
  /etc/hosts
  /etc/inittab
  /etc/issue
  /etc/issue.net
  /etc/ldap.conf
  /etc/ldap.secret
  /etc/lftp.conf
  /etc/modprobe.conf
  /etc/motd
  /etc/my.cnf
  /etc/named.conf
  /etc/nsswitch.conf
  /etc/ntp.conf
  /etc/passwd
  /etc/profile
  /etc/resolv.conf
  /etc/shadow
  /etc/shells
  /etc/sudoers
  /etc/syslog.conf
  /etc/vsftpd.ftpusers
  /etc/vsftpd.user_list
  /etc/vfstab
  /etc/xinetd.conf
  /etc/yum.conf

  /etc/cron.d/clockfix
  /etc/cron.d/f1tmp
  /etc/cron.d/sysstat
  /etc/cron.daily/logrotate
  /etc/cron.daily/makewhatis.cron
  /etc/cron.daily/tmpwatch  
  /etc/cron.weekly/makewhatis.cron
  /etc/mail/access
  /etc/mail/domaintable
  /etc/mail/local-host-names
  /etc/mail/mailertable
  /etc/mail/sendmail.cf
  /etc/mail/sendmail.mc
  /etc/mail/submit.cf
  /etc/mail/submit.mc
  /etc/mail/trusted-users
  /etc/mail/virtusertable
  /etc/openldap/ldap.conf
  /etc/openldap/slapd.conf
  /etc/pam.d/system-auth
  /etc/postfix/access
  /etc/postfix/main.cf
  /etc/postfix/master.cf
  /etc/postfix/relay_recipients
  /etc/postfix/transport
  /etc/postfix/virtual
  /etc/rc.d/rc.local
  /etc/selinux/config
  /etc/snmp/snmpd.conf
  /etc/ssh/sshd_config
  /etc/sysconfig/authconfig
  /etc/sysconfig/iptables
  /etc/sysconfig/iptables-config
  /etc/sysconfig/network
  /etc/sysconfig/sysstat
  /etc/vsftpd/vsftpd.conf
  /etc/yum.repos.d/CentOS-Base.repo

  /root/.bash_logout
  /root/.bash_profile
  /root/.bashrc
  /root/.my.cnf
  /root/.ssh/authorized_keys2
  /root/.ssh/authorized_keys
  /root/.ssh/identity
  /root/.ssh/id_dsa
  /root/.ssh/id_rsa
  
  /etc/VRTSvcs/conf/config/main.cf

  /etc/httpd/conf/httpd.conf 

  /etc/sysconfig/vmware-release /etc/vmware/license.cfg /etc/vmware/esx.conf

  /etc/vmware/config

  /fusionone/apache/conf/httpd.conf
  /fusionone/bin/f1
  /fusionone/smfe/server/default/data/pingfederate-admin-user.xml
  /fusionone/tomcat/conf/server.xml

  /fusionone/webapps/mb/WEB-INF/classes/pfagent.propertries

  /fusionone/webapps/admin/WEB-INF/classes/admin.properties
  /fusionone/webapps/admin/WEB-INF/classes/papi.properties
  /fusionone/webapps/admin/WEB-INF/classes/f1papi.properties

  /fusionone/webapps/alcsrw/WEB-INF/classes/alcsrw.properties
  /fusionone/webapps/alcsrw/WEB-INF/classes/f1papi.properties
  /fusionone/webapps/alcsrw/WEB-INF/classes/papi.properties
  /fusionone/webapps/alcsrw/WEB-INF/classes/qc-lib.properties
  /fusionone/webapps/alcsrw/WEB-INF/classes/hibernate.properties

  /fusionone/webapps/f1nag/WEB-INF/classes/hibernate.properties
  /fusionone/webapps/f1nag/WEB-INF/classes/jdbc.properties
  /fusionone/webapps/f1nag/WEB-INF/classes/nag.properties

  /fusionone/webapps/fms/WEB-INF/classes/f1papi.conf
  /fusionone/webapps/fms/WEB-INF/classes/fms.conf
  /fusionone/webapps/fms/WEB-INF/classes/hibernate.properties
  /fusionone/webapps/fms/WEB-INF/classes/jdbc.properties  
 
  /fusionone/webapps/lc-broker/WEB-INF/classes/hibernate.properties
  /fusionone/webapps/lc-broker/WEB-INF/classes/lcbroker.properties
  /fusionone/webapps/lc-broker/WEB-INF/classes/f1papi.conf
  /fusionone/webapps/lc-broker/WEB-INF/classes/jdbc.properties
  /fusionone/webapps/lc-broker/WEB-INF/classes/papi.properties
 
  /fusionone/webapps/mb/WEB-INF/classes/f1papi.conf
  /fusionone/webapps/mb/WEB-INF/classes/hibernate.properties
  /fusionone/webapps/mb/WEB-INF/classes/jdbc.properties
  /fusionone/webapps/mb/WEB-INF/classes/papi.properties
  /fusionone/webapps/mb/WEB-INF/classes/pfagent.properties
  /fusionone/webapps/mb/WEB-INF/classes/mbackup.properties
  /fusionone/webapps/mb/WEB-INF/classes/sso.properties
 
  /fusionone/webapps/mbnag/WEB-INF/classes/f1papi.conf
  /fusionone/webapps/mbnag/WEB-INF/classes/logger.properties
  /fusionone/webapps/mbnag/WEB-INF/classes/mpwdb.properties
  /fusionone/webapps/mbnag/WEB-INF/classes/nag.properties

  /fusionone/webapps/mg/WEB-INF/classes/f1mg.properties
  /fusionone/webapps/mg/WEB-INF/classes/f1papi.conf
  /fusionone/webapps/mg/WEB-INF/classes/papi.properties

  /fusionone/webapps/mp/WEB-INF/classes/dcl.f1papi.conf
  /fusionone/webapps/mp/WEB-INF/classes/f1papi.conf
  /fusionone/webapps/mp/WEB-INF/classes/logger.properties
  /fusionone/webapps/mp/WEB-INF/classes/mpw.db.properties
  /fusionone/webapps/mp/WEB-INF/classes/mpw.properties
  /fusionone/webapps/mp/WEB-INF/classes/ora.config
  /fusionone/webapps/mp/WEB-INF/classes/papi.properties

  /fusionone/webapps/mpnag/WEB-INF/classes/configfiles.properties
  /fusionone/webapps/mpnag/WEB-INF/classes/f1papi.conf
  /fusionone/webapps/mpnag/WEB-INF/classes/logger.properties
  /fusionone/webapps/mpnag/WEB-INF/classes/mpwdb.properties
  /fusionone/webapps/mpnag/WEB-INF/classes/nag.properties 
 
  /fusionone/webapps/qc-gw/WEB-INF/classes/f1papi.conf
  /fusionone/webapps/qc-gw/WEB-INF/classes/hibernate.properties
  /fusionone/webapps/qc-gw/WEB-INF/classes/jdbc.properties
  /fusionone/webapps/qc-gw/WEB-INF/classes/qcgw.properties
  /fusionone/webapps/qc-gw/WEB-INF/classes/qc-lib.properties
  /fusionone/webapps/qc-gw/WEB-INF/classes/papi.properties
 
  /fusionone/sync/classes_variables_ce.inf
  /fusionone/sync/classes_ce.inf
  
  /opt/cvs/CVSROOT/config
  /opt/cvs/CVSROOT/passwd
  /opt/svn/conf/passwd
  /opt/svn/conf/svnserve.conf

  /var/f1/last_backup
  /var/f1/last_ostune
  /var/f1/last_yum

  /var/spool/cron/oracle
  /var/spool/cron/root
@;

  # Name trouble
  
  for my $config (@configs) {
    push @configs, '/fusionone/webapp/' . $1 if $config =~ /\/fusionone\/webapps\/(.+)$/;
    push @configs, '/fusionone/ss/' . $1, '/fusionone/apps/ss/' . $1 if $config =~ /\/fusionone\/sync\/(.+)$/;
  }

  push @configs, '/tmp/packages.txt';
  
  #  /etc/vmware/locations

  for my $type ( qw/ifcfg route/ ) {
    for my $eth ( qw/eth bond/ ) {
      for my $n ( 0 .. 9 ) {
        push @configs, "/etc/sysconfig/network-scripts/$type-$eth$n";
      }
    }
  }

  push @configs, "/etc/sysconfig/network-scripts/ifcfg-eth0:0"; # Need a better search

  for my $n ( 0 .. 9 ) {
    for my $eth ( qw/hme qfe/ ) {
      push @configs, '/etc/hostname.' . $eth . $n;
    }
  }

  return sort @configs;
}

=head1 Authorship:

  (c) 2008-2209, Horus, Inc. 

  Work by Phil Pollard
  $Revision: 1.26 $ $Date: 2009/07/29 01:07:55 $

=cut

1;
