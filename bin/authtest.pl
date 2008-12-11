#!/usr/bin/perl

use strict;

use Crypt::PasswdMD5;
use Crypt::SaltedHash;
use Net::LDAP;
use Term::ReadPassword;

my $password = read_password('password: ');

my($ldap) = Net::LDAP->new('ldap.myhost.com') or die "Can't bind to ldap: $!\n";
$ldap->bind("cn=manager,dc=mycompany,dc=com", password=>'mypassword');

my $mesg = $ldap->search(filter => '(objectClass=*)', base => "ou=People,dc=mycompany,dc=com");

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
    my $crypt = $1;
    my $enc = unix_md5_crypt($text,$crypt);
    return $enc eq $crypt ? 1:0;
  }
  return Crypt::SaltedHash->validate($pass, $text) ? 1:0;
}
