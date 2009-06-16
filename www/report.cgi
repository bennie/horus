#!/usr/bin/perl -I../lib

# $Id: report.cgi,v 1.2 2009/06/16 21:27:33 ppollard Exp $

use Horus::Auth;
use Horus::Reports;

use HTML::Template;

use strict;

my $ha = new Horus::Auth;
my $hr = new Horus::Reports;

my $cgi  = $ha->{cgi};
my $user = $ha->{username};

my $tmpl_file = '/home/horus/support/main.tmpl';
my $tmpl = HTML::Template->new( filename => $tmpl_file );

my $guest = $user eq 'Guest' ? $cgi->a({-href=>'/login.cgi?path=/index.cgi'.$cgi->path_info},'Login') : "$user [ ".$cgi->a({-href=>'/login.cgi?logout=true'},'logout').' ]';

$tmpl->param( titlebar => 'Horus' );
$tmpl->param( title => 'Horus' );
$tmpl->param( guest => $guest );

my @pathinfo = split '/', $cgi->path_info;
shift @pathinfo;

if ( $pathinfo[0] ) {
  &report( $pathinfo[0] );
} else {
  &list();
}

### Pages

sub list {
  $tmpl->param( titlebar => 'Horus: Report List' );
  $tmpl->param( title => 'Report List' );
  $tmpl->param( guest => $guest );

  my $nav = $cgi->a({-href=>'/index.cgi/dashboard'},'Back to Dashboard');
  my $info = '';
  my $body = $cgi->start_ul();

  for my $report ( $hr->list() ) {
    $body .= $cgi->li($cgi->a({-href=>"/report.cgi/$report"},$report));
  }

  $body .= $cgi->end_ul();

  $tmpl->param( body => $body, info => $info, nav => $nav );
  print $cgi->header, $tmpl->output;
}

sub report {
  my $report = shift @_;
  $tmpl->param( titlebar => "Horus: $report Report" );
  $tmpl->param( title => "$report Report" );
  $tmpl->param( guest => $guest );

  my $nav = $cgi->a({-href=>'/index.cgi/dashboard'},'Back to Dashboard');
  my $info = '';
  my $body = $cgi->pre($hr->get($report));

  $tmpl->param( body => $body, info => $info, nav => $nav );
  print $cgi->header, $tmpl->output;
}
