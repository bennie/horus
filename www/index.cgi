#!/usr/bin/perl -I../lib

# $Id: index.cgi,v 1.18 2008/07/29 19:49:26 ppollard Exp $

use Horus::Network;
use Horus::Hosts;

use CGI;
use strict;

my $cgi = new CGI;
my $fh = new Horus::Hosts;
my $fn = new Horus::Network;

my $color_back    = '#FFFFFF';
my $color_border  = '#000000';
my $color_header  = '#666699';
my $color_subhead = '#CCCCCC';

my $good = '<img width="32" height="32" alt="[ + ]" src="http://horus.fusionone.com/images/good.png" />';
my $bad  = '<img width="32" height="32" alt="[ - ]" src="http://horus.fusionone.com/images/bad.png" />';

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
} elsif ( $pathinfo[0] eq 'report' and $pathinfo[1] eq 'os' ) {
  &os_report();
} elsif ( $pathinfo[0] eq 'report' and $pathinfo[1] eq 'password' ) {
  &password_report();
} else {
  print $cgi->redirect('/index.cgi/dashboard');
}

### Pages

sub config {
  my $host = shift @_;
  my $config = shift @_;
  my $possible = $fh->by_name($host);

  print $cgi->header, $cgi->start_html({-title=> "Horus: $host config $config"}),
        $cgi->font({-size=>'+2'},"Horus - $host config $config"), $cgi->hr({-noshade=>undef}),
        $cgi->font({-size=>1},$cgi->a({-href=>'/index.cgi/host/'.$host},'Back to host view'));

  my $conftext = $fh->config_get($possible->[0],$config);

  $conftext =~ s/</&lt;/g;
  $conftext =~ s/>/&gt;/g;

  print $cgi->pre($conftext);
  
  print $cgi->end_html;
}

sub dashboard {
  print $cgi->header, $cgi->start_html({-title=> 'Horus: Dashboard view'}),
        $cgi->font({-size=>'+2'},"Horus"), $cgi->hr({-noshade=>undef});
  print '[ ',$cgi->a({-href=>'/index.cgi/report/network'},"Network Report"),
        ' | ',$cgi->a({-href=>'/index.cgi/report/os'},"OS Report"),' ]';
  print $cgi->p("$total hosts in the system.");

  my @rows = (
    $cgi->Tr(
      $cgi->td({-bgcolor=>$color_header},'Host'),
      $cgi->td({-bgcolor=>$color_header},'Customer'),
      $cgi->td({-bgcolor=>$color_header},'Category'),
      $cgi->td({-bgcolor=>$color_header},'Type'),
      $cgi->td({-bgcolor=>$color_header},'OS'),
      $cgi->td({-bgcolor=>$color_header},'Release'),
      $cgi->td({-bgcolor=>$color_header},'Version'),
      $cgi->td({-bgcolor=>$color_header},'Arch.'),
      $cgi->td({-bgcolor=>$color_header},'Brand'),
      $cgi->td({-bgcolor=>$color_header},'Model'),
      $cgi->td({-bgcolor=>$color_header},'Clock'),
      $cgi->td({-bgcolor=>$color_header},'Last&nbsp;Update'),
      $cgi->td({-bgcolor=>$color_header}, $cgi->start_form({-action=>'/edit.cgi'}), $cgi->submit({-name=>'New'}), $cgi->end_form )
    )
  );

  for my $id ( sort { lc($hosts{$a}) cmp lc($hosts{$b}) } keys %hosts ) {
    my %rec = $fh->get($id);

    $rec{last_modified} =~ /(\d{4}-\d\d-\d\d)/;
    my $time = $1;

    map { $rec{$_}=~s/\s/\&nbsp;/g } qw/osrelease osversion machine_model customer/;

    my $bg = $rec{skip} == 1 ? $color_subhead : $color_back;  
  
    push @rows, $cgi->Tr(
      $cgi->td({-bgcolor=>$bg}, $cgi->a({-href=>"/index.cgi/host/$hosts{$id}"},$hosts{$id}) ),
      $cgi->td({-bgcolor=>$bg}, "$rec{customer}" ),
      $cgi->td({-bgcolor=>$bg}, "$rec{category}" ),
      $cgi->td({-bgcolor=>$bg}, "$rec{type}" ),
      $cgi->td({-bgcolor=>$bg}, "$rec{os}" ),
      $cgi->td({-bgcolor=>$bg}, "$rec{osrelease}" ),
      $cgi->td({-bgcolor=>$bg}, "$rec{osversion}" ),
      $cgi->td({-bgcolor=>$bg}, "$rec{arch}" ),
      $cgi->td({-bgcolor=>$bg}, "$rec{machine_brand}" ),
      $cgi->td({-bgcolor=>$bg}, "$rec{machine_model}" ),
      $cgi->td({-bgcolor=>$bg,-align=>'center'}, "$rec{tz}" ),
      $cgi->td({-bgcolor=>$bg,-align=>'center'}, $time ),
      $cgi->td({-bgcolor=>$bg,-align=>'center'}, $cgi->start_form({-action=>'/edit.cgi'}), $cgi->hidden({-name=>'id',-value=>$id}), $cgi->submit({-name=>'Edit'}), $cgi->end_form ),
    );
  }

  print $cgi->center( &box(@rows) );
  print $cgi->end_html;
}

sub host {
  my $host = shift @_;
  print $cgi->header, $cgi->start_html( -title=> 'Horus: Host view'),
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
        $cgi->td({-bgcolor=>$color_header},'Customer'), $cgi->td({-bgcolor=>$color_back},$rec{customer}),
        $cgi->td({-bgcolor=>$color_header},'Hostname'), $cgi->td({-bgcolor=>$color_back},$rec{name})
      ),
      $cgi->Tr(
        $cgi->td({-bgcolor=>$color_header},'Machine Brand'), $cgi->td({-bgcolor=>$color_back},$rec{machine_brand}),
        $cgi->td({-bgcolor=>$color_header},'OS'), $cgi->td({-bgcolor=>$color_back},$rec{os})
      ),
      $cgi->Tr(
        $cgi->td({-bgcolor=>$color_header},'Machine Model'), $cgi->td({-bgcolor=>$color_back},$rec{machine_model}),
        $cgi->td({-bgcolor=>$color_header},'OS Release'), $cgi->td({-bgcolor=>$color_back},$rec{osrelease})
      ),
      $cgi->Tr(
        $cgi->td({-bgcolor=>$color_header},'Machine Arch'), $cgi->td({-bgcolor=>$color_back},$rec{arch}),
        $cgi->td({-bgcolor=>$color_header},'OS Version'), $cgi->td({-bgcolor=>$color_back},$rec{osversion})
      )
    )
  );

  # Network
  
  my @addrs = $fn->host_list($rec{id});
  my @rows;

  for my $addr (@addrs) {
    my %net = $fn->get($addr);
    push @rows, $cgi->Tr($cgi->td({-bgcolor=>$color_back,-align=>'center'},$net{host_interface}), $cgi->td({-bgcolor=>$color_back},$net{address}));
  }

  if ( scalar(@rows) ) {
    print $cgi->p(box(
            $cgi->Tr($cgi->td({-bgcolor=>$color_header},'Interface'), $cgi->td({-bgcolor=>$color_header},'Hardware Address')),
            @rows
          ));
  }

  # Service details

  print $cgi->p(
    box(
      $cgi->Tr( 
        $cgi->td({-bgcolor=>$color_header},'Service Name'), $cgi->td({-bgcolor=>$color_header},'Status'), $cgi->td({-bgcolor=>$color_header},'Detail'),
      ),
      $cgi->Tr(
        $cgi->td({-bgcolor=>$color_subhead},'NTP'), $cgi->td({-bgcolor=>$color_back,-align=>'center'},( $rec{ntp} == 1 ?$good:$bad)), $cgi->td({-bgcolor=>$color_back},$rec{ntphost}),
      ),
      $cgi->Tr(
        $cgi->td({-bgcolor=>$color_subhead},'SNMP'), $cgi->td({-bgcolor=>$color_back,-align=>'center'},( $rec{snmp} == 1 ?$good:$bad)), $cgi->td({-bgcolor=>$color_back},$rec{snmp_community}),
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
        $cgi->font({-size=>'+2'},"Horus: Network Report"), $cgi->hr({-noshade=>undef}),
        $cgi->font({-size=>1},$cgi->a({-href=>'/index.cgi/dashboard'},'Back to Dashboard'));

  my $all = $fn->all();

  my @rows = (
    $cgi->Tr(
      $cgi->td({-bgcolor=>$color_header},'Host'),
      $cgi->td({-bgcolor=>$color_header},'Interface'),
      $cgi->td({-bgcolor=>$color_header},'Address'),
      $cgi->td({-bgcolor=>$color_header},'Switch'),
      $cgi->td({-bgcolor=>$color_header},'Port'),
      $cgi->td({-bgcolor=>$color_header},'Current Speed'),
      $cgi->td({-bgcolor=>$color_header},'Max Speed'),
      $cgi->td({-bgcolor=>$color_header},'Link Detected'),
      $cgi->td({-bgcolor=>$color_header},'Last Update'),
    )
  );

  for my $rec ( sort { lc($a->{host_name}) cmp lc($b->{host_name}) || lc($a->{host_interface}) cmp lc($b->{host_interface}) } @$all ) {

    $rec->{last_modified} =~ /(\d{4}-\d\d-\d\d)/;
    my $time = $1;

    push @rows, $cgi->Tr(
      $cgi->td({-bgcolor=>$color_back}, $cgi->a({-href=>"/index.cgi/host/$rec->{host_name}"},$rec->{host_name}) ),
      $cgi->td({-bgcolor=>$color_back,-align=>'center'}, "$rec->{host_interface}" ),
      $cgi->td({-bgcolor=>$color_back}, "$rec->{address}" ),
      $cgi->td({-bgcolor=>$color_back}, "$rec->{switch_id}" ),
      $cgi->td({-bgcolor=>$color_back}, "$rec->{port}" ),
      $cgi->td({-bgcolor=>$color_back}, "$rec->{current_speed}" ),
      $cgi->td({-bgcolor=>$color_back}, "$rec->{max_speed}" ),
      $cgi->td({-bgcolor=>$color_back,-align=>'center'}, ($rec->{link_detected}==1?$good:$bad) ),
      $cgi->td({-bgcolor=>$color_back,-align=>'center'}, "$time" ),
    );
  }

  print $cgi->center( &box(@rows) );
  print $cgi->end_html;
}

sub os_report {
  print $cgi->header, $cgi->start_html( -title=> 'Horus - OS Report'),
        $cgi->font({-size=>'+2'},"Horus: OS Report"), $cgi->hr({-noshade=>undef}),
        $cgi->font({-size=>1},$cgi->a({-href=>'/index.cgi/dashboard'},'Back to Dashboard'));

  my %os;
  my %counts;
  
  for my $id ( keys %hosts ) {
    my %rec = $fh->get($id);
    $os{$rec{'os'}}{$rec{'osrelease'}}{$rec{'osversion'}}++;
    $counts{$rec{'os'}}++;
    $counts{$rec{'os'}.$rec{'osrelease'}}++;
  }

  for my $os ( sort keys %os ) {
    print $cgi->p($cgi->b($os),"($counts{$os} servers)"), $cgi->start_ul;
    for my $release ( sort keys %{$os{$os}} ) {
      print $cgi->li(($release eq '' ? 'Unknown' : $release),'(' .$counts{$os.$release}. ' servers)');
      my @chunks;
      for my $version ( sort keys %{$os{$os}{$release}} ) {
        push @chunks, "$version ($os{$os}{$release}{$version})";
      }
      print $cgi->blockquote(join ', ', @chunks);
    }
    print $cgi->end_ul;
  }

  print $cgi->end_html;
}

sub password_report {
  print $cgi->header, $cgi->start_html( -title=> 'Horus - Password Report'),
        $cgi->font({-size=>'+2'},"Horus: Password Report"), $cgi->hr({-noshade=>undef}),
        $cgi->font({-size=>1},$cgi->a({-href=>'/index.cgi/dashboard'},'Back to Dashboard'));

  my @pass = $cgi->Tr( map {$cgi->td({-bgcolor=>$color_header},$_)} qw/Host User Pass/);
  
  for my $id ( sort { lc($hosts{$a}) cmp lc($hosts{$b}) } keys %hosts ) {
    my %rec = $fh->get($id);
    push @pass, $cgi->Tr(
      $cgi->td({-bgcolor=>$color_subhead},$rec{name}),
      $cgi->td({-bgcolor=>$color_back},$rec{username}),
      $cgi->td({-bgcolor=>$color_back},$rec{password})
    );
  }

  print $cgi->p({-align=>'center'},box(@pass));
  
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
