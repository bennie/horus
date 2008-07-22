#!/usr/bin/perl -I../lib

use Fusionone::Hosts;

use CGI;
use strict;

my $cgi = new CGI;
my $fh = new Fusionone::Hosts;

my $color_border = '#000000';

print $cgi->header, $cgi->start_html( -title=> 'Horus');

my %hosts = $fh->all();

my @rows = (
  $cgi->Tr(
    $cgi->td({-bgcolor=>'#666699'},'Host'),
    $cgi->td({-bgcolor=>'#666699'},'Customer'),
    $cgi->td({-bgcolor=>'#666699'},'OS')
  )
);

for my $id ( sort { lc($hosts{$a}) cmp lc($hosts{$b}) } keys %hosts ) {
  my %rec = $fh->get($id);
  push @rows, $cgi->Tr(
    #$cgi->td({-bgcolor=>'#ffffff'}, $cgi->start_form, $cgi->end_form ),
    $cgi->td({-bgcolor=>'#ffffff'}, "$hosts{$id}" ),
    $cgi->td({-bgcolor=>'#ffffff'}, "$rec{customer}" ),
    $cgi->td({-bgcolor=>'#ffffff'}, "$rec{os}" )
  );
}

print $cgi->center( &box(@rows) );

print $cgi->end_html;

sub box {
  my @rows = @_;
  return '<table border="0" bgcolor="' . $color_border . '" cellpadding="0" '
       . "cellspacing=\"0\">\n<tr><td>\n<table border=\"0\" "
       . 'bgcolor="' . $color_border . "\" cellpadding=\"5\" cellspacing=\"1\">\n"
       . join('',@rows)
       . "</table>\n</td></tr>\n</table>\n<br />\n";
}
