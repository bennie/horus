=head1 Horus::Auth (Auth.pm)

=cut

package Horus::Auth;

$Horus::Auth::VERSION='$Revision: 1.3 $';

use CGI;
use CGI::Session;
use Crypt::PasswdMD5;
use Crypt::SaltedHash;
use Digest::MD5 qw/md5_hex/;
use Net::LDAP;

use strict;

sub new {
  my     $self = {};
  bless  $self;

  $self->{cgi} = new CGI;

  # Read in the session cookie.
  $self->{cookie_value} =  $self->{cgi}->cookie(-name=>'bastet');
 
  # Build the session
  $self->{session} = new CGI::Session("driver:db_file", $self->{cookie_value} ) or die "$!";
  $self->{session}->expire('+1h');

  $self->{sessionid} = $self->{session}->id();
  $self->{username} = $self->{session}->param('username') || 'Guest';
  $self->{status} = $self->{session}->param('status') || 'unauthenticated';

  # Set up the outbound cookie
  $self->{cookie} =  $self->{cgi}->cookie(-name=>'bastet',-value=>$self->{sessionid});
  $self->{header} = $self->{cgi}->header( -cookie=> $self->{cookie} );

  $self->{session}->flush();
  return $self;
}

sub DESTROY {
  my $self = shift @_;
  $self->{session}->flush();
}

sub check_pass {
  my $self = shift @_;
  my $user = shift @_;
  my $pass = shift @_;

  my $ldap = Net::LDAP->new('ldap.myhost.com') or return "Can't bind to ldap: $!";
  $ldap->bind("cn=manager,dc=mycompany,dc=com", password=>'mypassword');

  my $mesg = $ldap->search(filter => "(uid=$user)", base => "ou=People,dc=mycompany,dc=com");

  return 'LDAP Query response: ' . $mesg->code . ' ' .  $mesg->error unless $mesg->code == 0;

  my $uid; my $password; my $valid;
  
  for my $entry ($mesg->entries) {
    $uid = ($entry->get('uid'))[0];
    $password = ($entry->get('userPassword'))[0];
    $valid = $self->_verify_password($password, $pass);
    last if $valid eq '0';
  }

  if ( $valid eq '0' ) {
    $self->{username} = $user;
    $self->{status} = 'authenticated';

    $self->{session}->param('username',$user);
    $self->{session}->param('status','authenticated');
  }

  $self->{session}->flush();
  return "$valid -> $uid $password\n";
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