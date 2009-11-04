#!/usr/bin/perl -I../lib

use Horus::DB;
use Horus::Reports;
use strict;

my $hdb = new Horus::DB;
my $hr  = new Horus::Reports;

my $dbh = $hdb->get_dbh();

### Parse args

my $name;
my $date;
my $is_historic = 0;

for my $arg (@ARGV) {
  $is_historic = 1 if $arg =~ /^--historic/;
  $is_historic = 1 && $date = $1 if $arg =~ /^--date=(.+)$/;
  $name = $arg unless $arg =~ /^--/;
}

die "Need to be called with a report name." unless $name;

my $report = join("\n",<STDIN>);

### The time is now; unless it isn't

if ( $is_historic and not $date ) {
  $date = &single('select now()');
}

### Import it

if ( $is_historic ) {
  my $ret = $hr->update_historic($name,$date,$report);
  warn "Update returned '$ret'\n" unless $ret == 1;
} else {
  my $ret = $hr->update($name,$report);
  warn "Update returned '$ret'\n" unless $ret == 1;
}

### Subs

sub single {
  my $query = shift @_;
  my @param =       @_;
  my $sth = $dbh->prepare($query);
  my $ret = $sth->execute(@param);
  my $ref = $sth->fetchrow_arrayref();
  my $ans = $ref->[0];
            $sth->finish();
  return $ans;
}