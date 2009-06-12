#!/usr/bin/perl -I../lib

# $Id: report-esx.pl,v 1.1 2009/06/12 19:17:44 ppollard Exp $

use Horus::Hosts;
use strict;

### Prep

my $ver = (split ' ', '$Revision: 1.1 $')[1];

my $h = new Horus::Hosts;
my $hosts = $h->all();

for my $hostid ( sort { lc($hosts->{$a}) cmp lc($hosts->{$b}) } keys %$hosts ) {
  my $host = $h->get($hostid);
  next unless $host->{os} eq 'VMware';
  print "$host->{name}:\n";

  my @raw = `./remote-command.pl $host->{name} 'if [ -x /sbin/vmdumper ]; then vmdumper --listVM; elif [ -x /usr/bin/vmware-cmd ]; then /usr/bin/vmware-cmd -l; fi'`;
  my @finish;
  for my $raw (@raw) {
    next if $raw =~ /^$/;
    warn "Can't parse: $raw" unless $raw =~ /\/vmfs\/volumes\/[\w- ]+?\/([\w- ]+?)\/([\w- ]+?\.vmx)/;
    push @finish, "  $1 ($2)\n";
  }
  print sort @finish;
}
