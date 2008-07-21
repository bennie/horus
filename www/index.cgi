#!/usr/bin/perl -I../lib

use Fusionone::Hosts;

use CGI;
use strict;

my $cgi = new CGI;
my $fh = new Fusionone::Hosts;

print $cgi->header, $cgi->start_html( -title=> 'Hello, World!');

my %hosts = $fh->all();

for my $id ( keys %hosts ) {
  print $cgi->p("$id $hosts{$id}"),
}

print $cgi->end_html;
