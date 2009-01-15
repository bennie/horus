=head1 Horus::Auth (Auth.pm)

=cut

package Horus::Auth;

$Horus::Auth::VERSION='$Revision: 1.2 $';

use CGI;
use Crypt::PasswdMD5;
use Crypt::SaltedHash;
use Data::UUID;
use Digest::MD5 qw/md5_hex/;
use Horus::DB;
use Net::LDAP;

use strict;

sub new {
  my     $self = {};
  bless  $self;

  my $table_prefix = 'foo';
  my $cookie_prefix = 'horus';

  # Do it
  
  my $hdb = new Horus::DB;
  my $dbh = $hdb->{dbh};

  my %out = ( username => undef );

  $out{cgi} = new CGI;
 
  $out{cookie_sid}     = $out{cgi}->cookie($cookie_prefix.'_sid');
  $out{cookie_t}       = $out{cgi}->cookie($cookie_prefix.'_t');
  $out{cookie_data}    = $out{cgi}->cookie($cookie_prefix.'_data');
  $out{cookie_session} = $out{cgi}->cookie($cookie_prefix.'_session');

  # Values

  $out{keyid}  = md5_hex($1) if $out{cookie_data} =~ /11:"autologinid";s:32:"([\da-f]+)"/;
  $out{userid} = $2 if $out{cookie_data} =~ /6:"userid";(i|s:-?\d+):"?(\d+)"?;\}/;
  $out{sid}    = $1 if $out{cookie_sid} =~ /([\da-f]{32})/;  

  # always-login cookie

  if ( $out{userid} and $out{keyid} and not $out{username} ) {
    $out{sql} = 'select username from '.$table_prefix.'_users u, '.$table_prefix.'_sessions_keys s where u.user_active=1 and u.user_id = s.user_id and u.user_id=? and s.key_id=?';

    my $sth = $dbh->prepare($out{sql});
    my $ret = $sth->execute($out{userid},$out{keyid});

    if ( $ret == 1 ) {
      $out{username} = $sth->fetchrow_arrayref->[0];
    } else {
      $out{error} = "Bad DB return code of $ret";
    }

    $sth->finish;
  }

  # by session

  if ( $out{sid} and $out{userid} and $out{userid} != -1 and not $out{username} ) {
    $out{sql} = 'select username from '.$table_prefix.'_users u, '.$table_prefix.'_sessions s where u.user_id = s.session_user_id and session_logged_in=1 and session_id=? 
and session_user_id=?';

    my $sth = $dbh->prepare($out{sql});
    my $ret = $sth->execute($out{sid},$out{userid});

    if ( $ret == 1 ) {
      $out{username} = $sth->fetchrow_arrayref->[0];
    } else {
      $out{error} = "Bad DB return code of $ret";
    }

    $sth->finish;
  }

  $dbh->disconnect;

  # Final check

  if ( $out{userid} < 0 ) {
    $out{userid} = undef
    $out{username} = undef
  }

  return \%out;
}

sub check_pass {
  my $self = shift @_;
  my $user = shift @_;
  my $pass = shift @_;

  my $ldap = Net::LDAP->new('ldap.myhost.com') or return "Can't bind to ldap: $!";
  $ldap->bind("cn=manager,dc=mycompany,dc=com", password=>'mypassword');

  my $mesg = $ldap->search(filter => "(uid=$user)", base => "ou=People,dc=mycompany,dc=com");

  return 'LDAP Query response: ' . $mesg->code . ' ' .  $mesg->error unless $mesg->code == 0;

  for my $entry ($mesg->entries) {
    my $uid = ($entry->get('uid'))[0];
    my $password = ($entry->get('userPassword'))[0];
    my $valid = $self->_verify_password($password, $pass);
    return "$valid -> $uid $password\n";
  }
}

sub _verify_password {
  my $pass = shift @_;
  my $text = shift @_;
  if ( $pass =~ /^\{crypt\}(.+)$/i ) {
    my $crypt = $1;
    my $enc = unix_md5_crypt($text,$crypt);
    return $enc eq $crypt ? 1:0;
  }
  return Crypt::SaltedHash->validate($pass, $text) ? 1:0;
}


1;