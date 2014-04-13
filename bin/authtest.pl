#!/usr/bin/env perl -I../lib

use Data::Dumper;
use Net::LDAP;
use Term::ReadLine;
use Term::ReadPassword;
use strict;

use LocalVars;

$Term::ReadPassword::USE_STARS = 1;
my $term = new Term::ReadLine ('pointless');

print "Using the following settings:\n";
print " * Host: $LocalVars::ldap_host\n";
print " * Port: $LocalVars::ldap_port\n";
print " * Bind: $LocalVars::ldap_bind\n";
print " * Pass: $LocalVars::ldap_pass\n";
print " * Base: $LocalVars::ldap_base\n";
print " * UID:  $LocalVars::ldap_uid\n\n";

my $ldap = Net::LDAP->new($LocalVars::ldap_host, ($LocalVars::ldap_port?(port=>$LocalVars::ldap_port):()) )
             or die "Can't connect to ldap server: $@\n";

### Test search bind

print "\n == Testing anonymous bind for searching.\n";

my $ret = $ldap->bind( $LocalVars::ldap_bind , password => "$LocalVars::ldap_pass" );
die $ret->{errorMessage} . "\n" . Dumper($ret) if $ret->{errorMessage};

unless ( $ret->error eq 'Success' ) {
  print "\n", $ret->error, "\n", Dumper($ret);
  exit 1;
}

print "\n SUCCESS: Able to bind with $LocalVars::ldap_bind\n";

### Test searching

print "\n == Testing search with this bind.\n";

my $search_user = $term->readline('username to seatch for: ');

my $search = $ldap->search(filter => "($LocalVars::ldap_uid=$search_user)", base => $LocalVars::ldap_base);

unless ( $search->error eq 'Success' ) {
  print "\n", $search->error, "\n", Dumper($search->entries);
  exit 1;
}

print "Returned object: \n", Dumper($search);

### Test a user login

print "\n == Testing a user login:\n";

my $user = $term->readline('user: ');
my $password = read_password('password: ');

my $mesg = $ldap->search(filter => "($LocalVars::ldap_uid=$user)", base => $LocalVars::ldap_base);

unless ( $mesg->error eq 'Success' ) {
  print "\n", $mesg->error, "\n", Dumper($mesg);
  exit 1;
}

my $ou = ($mesg->entries())[0]->get('distinguishedName')->[0];

my $ret = $ldap->bind( $ou, password => $password );

print $ret->error() . "\n";