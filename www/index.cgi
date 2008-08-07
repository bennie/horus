#!/usr/bin/perl -I../lib

# $Id: index.cgi,v 1.15 2008/08/07 20:32:31 ppollard Exp $

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
} elsif ( $pathinfo[0] eq 'host' and $pathinfo[1] and $cgi->param('config') ) {
  &config($pathinfo[1],$cgi->param('config'));
} elsif ( $pathinfo[0] eq 'host' and $pathinfo[1] ) {
  &host($pathinfo[1]);
} elsif ( $pathinfo[0] eq 'report' and $pathinfo[1] eq 'network' ) {
  &network_report();
} else {
  print $cgi->redirect('/index.cgi/dashboard');
}

### Pages

sub config {
  my $host = shift @_;
  my $config = shift @_;
  my $possible = $fh->by_name($host);

  print $cgi->header, $cgi->start_html({-title=> "Horus - $host config $config"}),
        $cgi->font({-size=>'+2'},"Horus - $host config $config"), $cgi->hr({-noshade=>undef}),
        $cgi->font({-size=>1},$cgi->a({-href=>'/index.cgi/host/'.$host},'Back to host view'));

  my $conftext = $fh->config_get($possible->[0],$config);

  $conftext =~ s/</&lt;/g;
  $conftext =~ s/>/&gt;/g;

  print $cgi->pre($conftext);
  
  print $cgi->end_html;
}

sub dashboard {
  print $cgi->header, $cgi->start_html({-title=> 'Horus - Dashboard view'}),
        $cgi->font({-size=>'+2'},"Horus"), $cgi->hr({-noshade=>undef});
  print '[',$cgi->a({-href=>'/index.cgi/report/network'},"Network Report"),']';
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
      $cgi->td({-bgcolor=>'#666699'},'Model'),
      $cgi->td({-bgcolor=>'#666699'},'Clock'),
      $cgi->td({-bgcolor=>'#666699'},'Last Update'),
      $cgi->td({-bgcolor=>'#666699'}, $cgi->start_form({-action=>'/edit.cgi'}), $cgi->submit({-name=>'New'}), $cgi->end_form )
    )
  );

  for my $id ( sort { lc($hosts{$a}) cmp lc($hosts{$b}) } keys %hosts ) {
    my %rec = $fh->get($id);

    $rec{last_modified} =~ /(\d{4}-\d\d-\d\d)/;
    my $time = $1;
  
    map { $rec{$_}=~s/\s/\&nbsp;/g } qw/osrelease osversion machine_model customer/;
  
    push @rows, $cgi->Tr(
      $cgi->td({-bgcolor=>'#ffffff'}, $cgi->a({-href=>"/index.cgi/host/$hosts{$id}"},$hosts{$id}) ),
      $cgi->td({-bgcolor=>'#ffffff'}, "$rec{customer}" ),
      $cgi->td({-bgcolor=>'#ffffff'}, "$rec{os}" ),
      $cgi->td({-bgcolor=>'#ffffff'}, "$rec{osrelease}" ),
      $cgi->td({-bgcolor=>'#ffffff'}, "$rec{osversion}" ),
      $cgi->td({-bgcolor=>'#ffffff'}, "$rec{arch}" ),
      $cgi->td({-bgcolor=>'#ffffff'}, "$rec{machine_brand}" ),
      $cgi->td({-bgcolor=>'#ffffff'}, "$rec{machine_model}" ),
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
  print $cgi->header, $cgi->start_html( -title=> 'Horus - Host view'),
        $cgi->font({-size=>'+2'},"Host: $host"), $cgi->hr({-noshade=>undef}),
        $cgi->font({-size=>1},$cgi->a({-href=>'/index.cgi/dashboard'},'Back to Dashboard'));

  my $possible = $fh->by_name($host);
  my %rec = $fh->get($possible->[0]);

  my %used = map {$_,1} qw/last_modified id created customer machine_brand machine_model arch os 
    osrelease osversion name uptime ntp ntphost snmp snmp_community/;

  # General details

  print $cgi->start_center();

  print $cgi->p($cgi->b('Uptime:'), $rec{uptime});

  print $cgi->p(
    box(
      $cgi->Tr( 
        $cgi->td({-bgcolor=>'#666699'},'Customer'), $cgi->td({-bgcolor=>'#FFFFFF'},$rec{customer}),
        $cgi->td({-bgcolor=>'#666699'},'Hostname'), $cgi->td({-bgcolor=>'#FFFFFF'},$rec{name})
      ),
      $cgi->Tr(
        $cgi->td({-bgcolor=>'#666699'},'Machine Brand'), $cgi->td({-bgcolor=>'#FFFFFF'},$rec{machine_brand}),
        $cgi->td({-bgcolor=>'#666699'},'OS'), $cgi->td({-bgcolor=>'#FFFFFF'},$rec{os})
      ),
      $cgi->Tr(
        $cgi->td({-bgcolor=>'#666699'},'Machine Model'), $cgi->td({-bgcolor=>'#FFFFFF'},$rec{machine_model}),
        $cgi->td({-bgcolor=>'#666699'},'OS Release'), $cgi->td({-bgcolor=>'#FFFFFF'},$rec{osrelease})
      ),
      $cgi->Tr(
        $cgi->td({-bgcolor=>'#666699'},'Machine Arch'), $cgi->td({-bgcolor=>'#FFFFFF'},$rec{arch}),
        $cgi->td({-bgcolor=>'#666699'},'OS Version'), $cgi->td({-bgcolor=>'#FFFFFF'},$rec{osversion})
      )
    )
  );

  # Network
  
  my @addrs = $fn->host_list($rec{id});
  my @rows;

  for my $addr (@addrs) {
    my %net = $fn->get($addr);
    push @rows, $cgi->Tr($cgi->td({-bgcolor=>'#FFFFFF',-align=>'center'},$net{host_interface}), $cgi->td({-bgcolor=>'#FFFFFF'},$net{address}));
  }

  if ( scalar(@rows) ) {
    print $cgi->p(box(
            $cgi->Tr($cgi->td({-bgcolor=>'#666699'},'Interface'), $cgi->td({-bgcolor=>'#666699'},'Hardware Address')),
            @rows
          ));
  }

  # Service details

  print $cgi->p(
    box(
      $cgi->Tr( 
        $cgi->td({-bgcolor=>'#666699'},'Service Name'), $cgi->td({-bgcolor=>'#666699'},'Service Status'), $cgi->td({-bgcolor=>'#666699'},'Service Detail'),
      ),
      $cgi->Tr(
        $cgi->td({-bgcolor=>'#CCCCCC'},'NTP'), $cgi->td({-bgcolor=>'#FFFFFF',-align=>'center'},$rec{ntp}), $cgi->td({-bgcolor=>'#FFFFFF'},$rec{ntphost}),
      ),
      $cgi->Tr(
        $cgi->td({-bgcolor=>'#CCCCCC'},'SNMP'), $cgi->td({-bgcolor=>'#FFFFFF',-align=>'center'},$rec{snmp}), $cgi->td({-bgcolor=>'#FFFFFF'},$rec{snmp_community}),
      ),
    )
  );

  print $cgi->end_center();

  # Config files

  print $cgi->hr({-noshade=>undef}), $cgi->b('Config Files:'), $cgi->start_ul();
  
  for my $config ( sort { lc($a) cmp lc($b) } $fh->config_list($rec{id}) ) {
    print $cgi->li($cgi->a({-href=>'?config='.$config},$config));
  }
  
  print $cgi->end_ul();
  
  # Other detail

  print $cgi->hr({-noshade=>undef}), $cgi->b('Other Detail:');
  
  print $cgi->start_blockquote;
  for my $key ( sort keys %rec ) {
    next if $used{$key};
    print $cgi->b($key.': '), $rec{$key}, $cgi->br;
  }
  print $cgi->end_blockquote;
  
  # Footer
  
  print $cgi->hr({-noshade=>undef}),
        $cgi->font({-size=>1},
            'ID:', $rec{id}, $cgi->br,
            'Created:', $rec{created}, $cgi->br,
             'Last Modified:', $rec{last_modified}, $cgi->br,
        );
  print $cgi->end_html;
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
