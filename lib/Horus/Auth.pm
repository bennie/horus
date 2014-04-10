=head1 Horus::Auth (Auth.pm)

=cut

package Horus::Auth;

use CGI;
use CGI::Session;
use Net::LDAP;

use LocalVars;

use strict;

sub new {
  my     $self = {};
  bless  $self;

  $self->{debug} = 0;

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

  my $ldap = Net::LDAP->new($LocalVars::ldap_host) or return ( 0, "Can't bind to ldap: $!" );
  $ldap->bind( $LocalVars::ldap_user, password=> $LocalVars::ldap_pass );

  my $search = $ldap->search(
               base   => $LocalVars::ldap_base,
               filter => "(uid=$user)",
               scope  => 'sub',
               attrs  => ['dn']
             );

  return ( 0, 'LDAP Query response: ' . $search->code . ' ' .  $search->error )
    unless $search->code == 0;

  my $user_dn; my $valid; my $crypt_check; my $error;

  if ( defined $search->entry and defined $search->entry->dn ) {
    $user_dn = $search->entry->dn;

    my $pass_check = $ldap->bind( $user_dn, password => $pass );
    if ( $pass_check->error eq 'Success' ) {
      $valid = 1;
    } else {
      $valid = 0;
      $error = $pass_check->error;
    }
  }
  
  if ( $valid eq '1' ) {
    $self->{username} = $user;
    $self->{status} = 'authenticated';

    $self->{session}->param('username',$user);
    $self->{session}->param('status','authenticated');

    $self->{session}->flush();
    return ( 1, "$user_dn $pass - Verfied" );
  } else {
    return ( 0, "No such user" ) unless $user_dn;
    return ( 0, "Bad Password" . ($self->{debug}?" ($user $pass $user_dn $error)":'') );
  }
}

sub clear_session {
  my $self = shift @_;
  $self->{username} = 'Guest';
  $self->{status} = 'unauthenticated';

  $self->{session}->param('username','Guest');
  $self->{session}->param('status','unauthenticated');

  $self->{session}->flush();
}

1;
