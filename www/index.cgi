#!/usr/bin/perl -I../lib

# $Id: index.cgi,v 1.23 2008/12/12 00:58:55 ppollard Exp $

use Horus::Network;
use Horus::Hosts;

use CGI;
use Data::Dumper;
use HTML::Template;
use Rcs::Parser;

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

my $tmpl_file = '/home/horus/support/main.tmpl';
my $tmpl = HTML::Template->new( filename => $tmpl_file );

my $user = 'Guest';

$tmpl->param( titlebar => 'Horus' );
$tmpl->param( title => 'Horus' );
$tmpl->param( guest => "Welcome $user" );

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
        $cgi->table({-width=>'100%',-cellpadding=>0,-cellspacing=>0},
          $cgi->Tr({-valign=>'bottom'},
            $cgi->td($cgi->font({-size=>'+2'},"Horus - $host config $config")),
            $cgi->td({-align=>'right'},$cgi->font({-size=>'1'},"Welcome $user")),
          )
        ),
        $cgi->hr({-noshade=>undef}),
        $cgi->font({-size=>1},$cgi->a({-href=>'/index.cgi/host/'.$host},'Back to host view'));

  my $rcs = new Rcs::Parser;
  my $rcstext = $fh->config_get_rcs($possible->[0],$config);
 
  $rcs->load_scalar($rcstext);

  my $currentver = $rcs->version; # Most current version in the RCS file
  my @versions = $rcs->all_versions();

  my $ver = $cgi->param('version') || $currentver; # The version we are displaying

  print $cgi->font({-size=>1},$cgi->p('Stored Versions:', join(', ', map { $ver eq $_ ? $_ : $cgi->a({-href=>'/index.cgi/host/'.$host.'?config='.$config.'&version='.$_},$_) } @versions)));

  print $cgi->hr({-noshade=>undef});
  
  my $date = 'unknown';
  
  for my $subver ( @versions ) {
    next unless $rcs->{rcs}->{$subver}->{next} eq $ver;
    $date = $rcs->{rcs}->{$subver}->{date};
  }
  
  print $cgi->p("This version of the config ($ver) " .( $ver eq $currentver ? 'is the version currently in use.' : 'was last seen in production on ' . $date ) );

  print $cgi->p("This version was first seen in production on " . $rcs->{rcs}->{$ver}->{date} );
  
  print $cgi->hr({-noshade=>undef});
    
  my $display;

  if ( $ver ne $currentver ) {
    $display = $rcs->get($ver); 
  } else {
    $display = $fh->config_get($possible->[0],$config);
  }

  print $cgi->pre(&htmlclean($display));
  
  #print $cgi->hr({-noshade=>undef});
  #print $cgi->p($cgi->pre(&htmlclean(Dumper($rcs->{rcs}))));

  print $cgi->end_html;
}

sub dashboard {
  $tmpl->param( titlebar => 'Horus: Dashboard view' );
  $tmpl->param( guest => "Welcome $user" );

  my $body =  '[ '  
           . $cgi->a({-href=>'/index.cgi/report/network'},"Network Report")
           . ' | '
           . $cgi->a({-href=>'/index.cgi/report/os'},"OS Report")
           . ' ]';

  $body .= $cgi->p("$total hosts in the system.");

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

  $body .= $cgi->center( &box(@rows) );
  $tmpl->param( body => $body );
  print $cgi->header, $tmpl->output;
}

sub host {
  my $host = shift @_;
  $tmpl->param( titlebar => 'Horus: Host view' );
  $tmpl->param( title => "Host: $host" );
  $tmpl->param( guest => "Welcome $user" );

  my $body = $cgi->font({-size=>1},$cgi->a({-href=>'/index.cgi/dashboard'},'Back to Dashboard'));

  my $possible = $fh->by_name($host);
  my %rec = $fh->get($possible->[0]);

  my %used = map {$_,1} qw/last_modified id created customer machine_brand machine_model arch os 
    osrelease osversion name uptime ntp ntphost snmp snmp_community/;

  # General details

  $body .= $cgi->start_center();

  $body .= $cgi->p($cgi->b('Uptime:'), $rec{uptime});

  $body .= $cgi->p(
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
    $body .= $cgi->p(box(
            $cgi->Tr($cgi->td({-bgcolor=>$color_header},'Interface'), $cgi->td({-bgcolor=>$color_header},'Hardware Address')),
            @rows
          ));
  }

  # Service details

  $body .= $cgi->p(
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

  $body .= $cgi->end_center();

  # Config files

  $body .= $cgi->hr({-noshade=>undef}) .  $cgi->b('Config Files:') . $cgi->start_ul();
  
  for my $config ( sort { lc($a) cmp lc($b) } $fh->config_list($rec{id}) ) {
    $body .= $cgi->li($cgi->a({-href=>'?config='.$config},$config));
  }
  
  $body .= $cgi->end_ul();
  
  # Other detail

  $body .= $cgi->hr({-noshade=>undef}) . $cgi->b('Other Detail:');
  
  $body .= $cgi->start_blockquote;
  for my $key ( sort keys %rec ) {
    next if $used{$key};
    $body .= $cgi->b($key.': ') . $rec{$key} . $cgi->br;
  }
  $body .= $cgi->end_blockquote;
  
  # Footer
  
  $body .= $cgi->hr({-noshade=>undef}) . 
        $cgi->font({-size=>1},
            'ID:', $rec{id}, $cgi->br,
            'Created:', $rec{created}, $cgi->br,
             'Last Modified:', $rec{last_modified}, $cgi->br,
        );
  $body .= $cgi->end_html;
  $tmpl->param( body => $body );
  print $cgi->header, $tmpl->output;
}

sub network_report {
  $tmpl->param( titlebar => 'Horus - Network Report' );
  $tmpl->param( title => 'Horus: Network Report' );
  $tmpl->param( guest => "Welcome $user" );

  my $body = $cgi->font({-size=>1},$cgi->a({-href=>'/index.cgi/dashboard'},'Back to Dashboard'));

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

  $body .= $cgi->center( &box(@rows) );
  $tmpl->param( body => $body );
  print $cgi->header, $tmpl->output;
}

sub os_report {
  $tmpl->param( titlebar => 'Horus - OS Report' );
  $tmpl->param( title => 'Horus: OS Report' );
  $tmpl->param( guest => "Welcome $user" );

  my $body = $cgi->font({-size=>1},$cgi->a({-href=>'/index.cgi/dashboard'},'Back to Dashboard'));

  my %os;
  my %counts;
  
  for my $id ( keys %hosts ) {
    my %rec = $fh->get($id);
    $os{$rec{'os'}}{$rec{'osrelease'}}{$rec{'osversion'}}++;
    $counts{$rec{'os'}}++;
    $counts{$rec{'os'}.$rec{'osrelease'}}++;
  }

  for my $os ( sort keys %os ) {
    $body .= $cgi->p($cgi->b($os),"($counts{$os} servers)"), $cgi->start_ul;
    for my $release ( sort keys %{$os{$os}} ) {
      $body .= $cgi->li(($release eq '' ? 'Unknown' : $release),'(' .$counts{$os.$release}. ' servers)');
      my @chunks;
      for my $version ( sort keys %{$os{$os}{$release}} ) {
        push @chunks, "$version ($os{$os}{$release}{$version})";
      }
      $body .= $cgi->blockquote(join ', ', @chunks);
    }
    $body .= $cgi->end_ul;
  }
  $body .= $cgi->end_html;
  $tmpl->param( body => $body );
  print $cgi->header, $tmpl->output;
}

sub password_report {
  $tmpl->param( titlebar => 'Horus - Password Report' );
  $tmpl->param( title => 'Horus: Password Report' );
  $tmpl->param( guest => "Welcome $user" );

  my $body = $cgi->font({-size=>1},$cgi->a({-href=>'/index.cgi/dashboard'},'Back to Dashboard'));

  my @pass = $cgi->Tr( map {$cgi->td({-bgcolor=>$color_header},$_)} qw/Host User Pass/);
  
  for my $id ( sort { lc($hosts{$a}) cmp lc($hosts{$b}) } keys %hosts ) {
    my %rec = $fh->get($id);
    push @pass, $cgi->Tr(
      $cgi->td({-bgcolor=>$color_subhead},$rec{name}),
      $cgi->td({-bgcolor=>$color_back},$rec{username}),
      $cgi->td({-bgcolor=>$color_back},$rec{password})
    );
  }

  $body .= $cgi->p({-align=>'center'},box(@pass));
  $tmpl->param( body => $body );
  print $cgi->header, $tmpl->output;
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

sub htmlclean {
  my $text = shift @_;
  $text =~ s/</&lt;/g;
  $text =~ s/>/&gt;/g;
  return $text;
}
