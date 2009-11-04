#!/usr/bin/perl -I../lib

# $Id: report.cgi,v 1.4 2009/11/04 23:11:42 ppollard Exp $

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

if ( $pathinfo[0] and $pathinfo[0] eq 'historic' and $pathinfo[1] and $pathinfo [2] ) {
  &report_historic($pathinfo[1],$pathinfo[2]);
} elsif ( $pathinfo[0] and $pathinfo[0] eq 'historic' ) {
  &list_historic();
} elsif ( $pathinfo[0] ) {
  &report($pathinfo[0]);
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

sub list_historic {
  $tmpl->param( titlebar => 'Horus: Historic Reports List' );
  $tmpl->param( title => 'Historic Reports List' );
  $tmpl->param( guest => $guest );

  my $nav = $cgi->a({-href=>'/index.cgi/dashboard'},'Back to Dashboard');
  my $info = '';
  my $body = $cgi->start_ul();

  my %reports = $hr->list_historic();

  for my $report ( sort keys %reports ) {
    for my $date ( @{$reports{$report}} ) {
      $body .= $cgi->li($cgi->a({-href=>"/report.cgi/historic/$report/$date"},"$report - $date"));
    }
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
  my $body = $hr->get($report);

  $tmpl->param( body => $body, info => $info, nav => $nav );
  print $cgi->header, $tmpl->output;
}

sub report_historic {
  my $report = shift @_;
  my $date   = shift @_;
  $tmpl->param( titlebar => "Horus: Historic $report Report for $date" );
  $tmpl->param( title => "$report Report for $date" );
  $tmpl->param( guest => $guest );

  my $nav = $cgi->a({-href=>'/index.cgi/dashboard'},'Back to Dashboard');
  my $info = $cgi->a({-href=>'/report.cgi/historic'},'Historic Reports');
  my $body = $hr->get_historic($report,$date);

  $tmpl->param( body => $body, info => $info, nav => $nav );
  print $cgi->header, $tmpl->output;
}