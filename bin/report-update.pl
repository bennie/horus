#!/usr/bin/perl -I../lib

use Horus::DB;
use strict;

my $hdb = new Horus::DB;
my $dbh = $hdb->get_dbh();

my $name   = shift @ARGV or die "Need to be called with a report name.";
my $report = join("\n",<STDIN>);

my $sth = $dbh->prepare("update reports set report=? where name=?");
my $ret = $sth->execute($report,$name);

warn "Insert returned '$ret'\n" unless $ret == 1;
