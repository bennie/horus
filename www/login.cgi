#!/usr/bin/perl -I../lib

# $Id: login.cgi,v 1.2 2009/01/15 01:47:45 ppollard Exp $

use Horus::Auth;
use strict;

my $ha = new Horus::Auth;
my $cgi = $ha->{cgi};

print $ha->{header}, $cgi->start_html;

if ( $cgi->param('user') && $cgi->param('pass') )  {
  &auth($cgi->param('user'),$cgi->param('pass'));
} else {
  &login;
}

print $cgi->p($ha->{sessionid});
print $cgi->p($ha->{username});
print $cgi->p($ha->{status});

print $cgi->end_html;

sub auth {
  my $user = shift @_;
  my $pass = shift @_;
  my $ret = $ha->check_pass($user,$pass);
  print $cgi->p($cgi->b($ret));
}

sub login {
  print $cgi->start_form,
        $cgi->p('User:',$cgi->textfield({name=>'user'})),
        $cgi->p('Pass:',$cgi->password_field({name=>'pass'})),
        $cgi->submit,
        $cgi->end_form;

}