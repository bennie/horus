#!/usr/bin/perl -I../lib

# $Id: index.cgi,v 1.11 2008/07/24 23:35:37 ppollard Exp $

use Horus::Network;
use Horus::Hosts;

use CGI;
use strict;

my $cgi = new CGI;
my $fh = new Horus::Hosts;
my $fn = new Horus::Network;

my $color_border = '#000000';


my %hosts = $fh->all();
my $total = scalar keys %hosts;

my @pathinfo = split '/', $cgi->path_info;
shift @pathinfo;

if ( $pathinfo[0] eq 'dashboard' ) {
  &dashboard();
} elsif ( $pathinfo[0] eq 'host' and $pathinfo[1] ) {
  &host($pathinfo[1]);
} elsif ( $pathinfo[0] eq 'report' and $pathinfo[1] eq 'network' ) {
  &network_report();
} else {
  print $cgi->redirect('/index.cgi/dashboard');
}

### Pages

sub dashboard {
  print $cgi->header, $cgi->start_html( -title=> 'Horus - Dashboard view');
  print $cgi->p('[',$cgi->a({-href=>'/index.cgi/report/network'},"Network Report"),']');
  print $cgi->p("$total hosts in the system.");

  my @rows = (
    $cgi->Tr(
      $cgi->td({-bgcolor=>'#666699'},'Host'),
      $cgi->td({-bgcolor=>'#666699'},'Customer'),
      $cgi->td({-bgcolor=>'#666699'},'OS'),
      $cgi->td({-bgcolor=>'#666699'},'Release'),
      $cgi->td({-bgcolor=>'#666699'},'Version'),
      $cgi->td({-bgcolor=>'#666699'},'Arch.'),
      $cgi->td({-bgcolor=>'#666699'},'Brand'),
      $cgi->td({-bgcolor=>'#666699'},'Clock'),
      $cgi->td({-bgcolor=>'#666699'},'Last Update'),
      $cgi->td({-bgcolor=>'#666699'}, $cgi->start_form({-action=>'/edit.cgi'}), $cgi->submit({-name=>'New'}), $cgi->end_form )
    )
  );

  for my $id ( sort { lc($hosts{$a}) cmp lc($hosts{$b}) } keys %hosts ) {
    my %rec = $fh->get($id);

    $rec{last_modified} =~ /(\d{4}-\d\d-\d\d)/;
    my $time = $1;
  
    push @rows, $cgi->Tr(
      $cgi->td({-bgcolor=>'#ffffff'}, $cgi->a({-href=>"/index.cgi/host/$hosts{$id}"},$hosts{$id}) ),
      $cgi->td({-bgcolor=>'#ffffff'}, "$rec{customer}" ),
      $cgi->td({-bgcolor=>'#ffffff'}, "$rec{os}" ),
      $cgi->td({-bgcolor=>'#ffffff'}, "$rec{osrelease}" ),
      $cgi->td({-bgcolor=>'#ffffff'}, "$rec{osversion}" ),
      $cgi->td({-bgcolor=>'#ffffff'}, "$rec{arch}" ),
      $cgi->td({-bgcolor=>'#ffffff'}, "$rec{machine_brand}" ),
      $cgi->td({-bgcolor=>'#ffffff',-align=>'center'}, "$rec{tz}" ),
      $cgi->td({-bgcolor=>'#ffffff',-align=>'center'}, $time ),
      $cgi->td({-bgcolor=>'#ffffff',-align=>'center'}, $cgi->start_form({-action=>'/edit.cgi'}), $cgi->hidden({-name=>'id',-value=>$id}), $cgi->submit({-name=>'Edit'}), $cgi->end_form ),
    );
  }

  print $cgi->center( &box(@rows) );
  print $cgi->end_html;
}

sub host {
  my $host = shift @_;
  print $cgi->header, $cgi->start_html( -title=> 'Horus - Dashboard view'),
        $cgi->font({-size=>'+2'},"Host: $host"), $cgi->hr({-noshade=>undef}),
        $cgi->font({-size=>1},$cgi->a({-href=>'/index.cgi/dashboard'},'Back to Dashboard'));

  my $possible = $fh->by_name($host);
  my %rec = $fh->get($possible->[0]);

  for my $key ( sort keys %rec ) {
    next if $key eq 'last_modified' or $key eq 'id';
    print $cgi->p($cgi->b($key),$rec{$key});
  }
  
  print $cgi->hr({-noshade=>undef}),
        $cgi->font({-size=>1},
          $cgi->p('Last Modified:',$rec{last_modified}),
          $cgi->p('ID:',$rec{id}),
        );
}

sub network_report {
  print $cgi->header, $cgi->start_html( -title=> 'Horus - Network Report'),
        $cgi->font({-size=>'+2'},"Network Report"), $cgi->hr({-noshade=>undef}),
        $cgi->font({-size=>1},$cgi->a({-href=>'/index.cgi/dashboard'},'Back to Dashboard'));

  my $all = $fn->all();

  my @rows = (
    $cgi->Tr(
      $cgi->td({-bgcolor=>'#666699'},'Host'),
      $cgi->td({-bgcolor=>'#666699'},'Interface'),
      $cgi->td({-bgcolor=>'#666699'},'Address'),
      $cgi->td({-bgcolor=>'#666699'},'Switch'),
      $cgi->td({-bgcolor=>'#666699'},'Port'),
      $cgi->td({-bgcolor=>'#666699'},'Current Speed'),
      $cgi->td({-bgcolor=>'#666699'},'Max Speed'),
      $cgi->td({-bgcolor=>'#666699'},'Link Detected'),
      $cgi->td({-bgcolor=>'#666699'},'Last Update'),
    )
  );

  for my $rec ( sort { lc($a->{host_name}) cmp lc($b->{host_name}) || lc($a->{host_interface}) cmp lc($b->{host_interface}) } @$all ) {

    $rec->{last_modified} =~ /(\d{4}-\d\d-\d\d)/;
    my $time = $1;

    push @rows, $cgi->Tr(
      $cgi->td({-bgcolor=>'#ffffff'}, $cgi->a({-href=>"/index.cgi/host/$rec->{host_name}"},$rec->{host_name}) ),
      $cgi->td({-bgcolor=>'#ffffff',-align=>'center'}, "$rec->{host_interface}" ),
      $cgi->td({-bgcolor=>'#ffffff'}, "$rec->{address}" ),
      $cgi->td({-bgcolor=>'#ffffff'}, "$rec->{switch_id}" ),
      $cgi->td({-bgcolor=>'#ffffff'}, "$rec->{port}" ),
      $cgi->td({-bgcolor=>'#ffffff'}, "$rec->{current_speed}" ),
      $cgi->td({-bgcolor=>'#ffffff'}, "$rec->{max_speed}" ),
      $cgi->td({-bgcolor=>'#ffffff',-align=>'center'}, "$rec->{link_detected}" ),
      $cgi->td({-bgcolor=>'#ffffff',-align=>'center'}, "$time" ),
    );
  }

  print $cgi->center( &box(@rows) );
  print $cgi->end_html;
}

### Subroutines

sub box {
  my @rows = @_;
  return '<table border="0" bgcolor="' . $color_border . '" cellpadding="0" '
       . "cellspacing=\"0\">\n<tr><td>\n<table border=\"0\" "
       . 'bgcolor="' . $color_border . "\" cellpadding=\"5\" cellspacing=\"1\">\n"
       . join('',@rows)
       . "</table>\n</td></tr>\n</table>\n<br />\n";
}
