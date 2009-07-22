#!/usr/bin/perl -I../lib

# $Id: report-backups.pl,v 1.1 2009/07/22 23:42:55 ppollard Exp $

use strict;

### Prep

my $ver = (split ' ', '$Revision: 1.1 $')[1];
my %backups;

my @raw = `./remote-command.pl ops ls -l --time-style=long-iso /archive_logs/images-rsync/*/bootsector.*`;

for my $line (@raw) {
  next unless $line =~ /\d root root \d+ (\d{4}-\d\d-\d\d) (\d\d:\d\d) \/archive_logs\/images-rsync\/([^\/]+)\/bootsector/;
  $backups{$3} = $1;
}

@raw = `./remote-command.pl ops ls -ld --time-style=long-iso /archive_logs/images-rsync/*`;

for my $line (@raw) {
  next unless $line =~ /\d root root \d+ (\d{4}-\d\d-\d\d) (\d\d:\d\d) \/archive_logs\/images-rsync\/([^\/]+)$/;
  my $dir = $3; chomp $dir;
  $backups{$dir} = "$1 (no bootsector)" unless $backups{$dir};
}

print "By name:\n";

for my $server ( sort { lc($a) cmp lc($b) } keys %backups ) {
  print "  $server: $backups{$server}\n";
}

print "\nBy date:\n";

for my $server ( sort { $backups{$a} <=> $backups{$b} } keys %backups ) {
  print "  $backups{$server}: $server\n";
}
