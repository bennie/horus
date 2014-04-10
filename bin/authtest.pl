#!/usr/bin/perl -I../lib

use Crypt::PasswdMD5;
use Crypt::SaltedHash;
use Net::LDAP;
use Term::ReadLine;
use Term::ReadPassword;

use LocalVars;

use strict;

$Term::ReadPassword::USE_STARS = 1;
my $term = new Term::ReadLine ('pointless');

print "Using the following settings:\n";
print " * Host: $LocalVars::ldap_host\n";
print " * User: $LocalVars::ldap_user\n";
print " * Pass: $LocalVars::ldap_pass\n";
print " * Base: $LocalVars::ldap_base\n\n";

my $user = $term->readline('user: ');
my $password = read_password('password: ');

my $ldap = Net::LDAP->new($LocalVars::ldap_host) or die "Can't bind to ldap: $!\n";
$ldap->bind($LocalVars::ldap_user, password=>$localVars::ldap_pass);

my $mesg = $ldap->search(filter => "(uid=$user)", base => $LocalVars::ldap_base);

print $mesg->code, ' ',  $mesg->error, "\n";

for my $entry ($mesg->entries) {
  my $uid = ($entry->get('uid'))[0];
  my $pass = ($entry->get('userPassword'))[0];
  my $valid = &check_pass($pass, $password);
  print "$valid -> $uid $pass\n";
}

sub check_pass {
  my $pass = shift @_;
  my $text = shift @_;
  if ( $pass =~ /^\{crypt\}(.+)$/i ) {
    print "Local crypt check.\n";
    my $crypt = $1;
    my $enc = unix_md5_crypt($text,$crypt);
    return $enc eq $crypt ? 1:0;
  }
  return Crypt::SaltedHash->validate($pass, $text) ? 1:0;
}
