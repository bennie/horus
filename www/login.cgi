#!/usr/bin/perl -I../lib

# $Id: login.cgi,v 1.3 2009/01/15 03:26:43 ppollard Exp $

use Horus::Auth;
use HTML::Template;
use strict;

my $debug = 0;

my $ha = new Horus::Auth;
my $cgi = $ha->{cgi};

$ha->{debug} = $debug; # pass through debug levels

my $tmpl_file = '/home/horus/support/main.tmpl';
my $tmpl = HTML::Template->new( filename => $tmpl_file );

$tmpl->param( titlebar => 'Horus - Login' );
$tmpl->param( title => 'Horus - Login' );
$tmpl->param( guest => '&nbsp;' );

my $body;

if ( $cgi->param('user') && $cgi->param('pass') )  {
  $body .= &auth($cgi->param('user'),$cgi->param('pass'));
} else {
  $body .= &login;
}

$body .= $cgi->p($ha->{sessionid}) .  $cgi->p($ha->{username}) . $cgi->p($ha->{status}) if $debug;

$tmpl->param( body => $body );
print $ha->{header}, $tmpl->output;

# Pages

sub auth {
  my $user = shift @_;
  my $pass = shift @_;
  my ($ret,$details) = $ha->check_pass($user,$pass);
  
  if ( $ret > 0 ) { # Success!
    print $cgi->redirect('/index.cgi');
    #return "Success!"
    #     . ( $debug ? $cgi->i($details) : '' );
  }
  
  return $cgi->p('Error:',$cgi->i($details))
       . &login;
}

sub login {
  return $cgi->start_form
       . $cgi->p('User:',$cgi->textfield({name=>'user'}))
       . $cgi->p('Pass:',$cgi->password_field({name=>'pass'}))
       . $cgi->submit
       . $cgi->end_form;

}