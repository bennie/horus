#!/usr/bin/perl -I../lib

# $Id: report.cgi,v 1.1 2009/06/16 18:32:46 ppollard Exp $

use Horus::Auth;
use Horus::Reports;

use HTML::Template;

use strict;

my $ha = new Horus::Auth;

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

&list();

### Pages

sub list {
  my $host = shift @_;
  $tmpl->param( titlebar => 'Horus: Report List' );
  $tmpl->param( title => 'Report List' );
  $tmpl->param( guest => $guest );

  my $nav = $cgi->a({-href=>'/index.cgi/dashboard'},'Back to Dashboard');
  my $info = 'info';

  my $body = $cgi->start_center() . 'Woot!';
  $body .= $cgi->end_center();

  $tmpl->param( body => $body, info => $info, nav => $nav );
  print $cgi->header, $tmpl->output;
}

