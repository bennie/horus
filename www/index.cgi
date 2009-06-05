#!/usr/bin/perl -I../lib

# $Id: index.cgi,v 1.37 2009/06/05 21:11:24 ppollard Exp $

use Horus::Auth;
use Horus::Hosts;
use Horus::Network;

use Data::Dumper;
use HTML::Template;
use Rcs::Parser;

use strict;

my $ha = new Horus::Auth;
my $fh = new Horus::Hosts;
my $fn = new Horus::Network;

my $cgi  = $ha->{cgi};
my $user = $ha->{username};

my %configs_requiring_auth = map {$_,1} qw|/etc/passwd /etc/shadow /etc/sudoers /root/.ssh/authorized_keys|;

my $color_back    = '#FFFFFF';
my $color_border  = '#000000';
my $color_header  = '#666699';
my $color_subhead = '#CCCCCC';

my $good = '<img width="32" height="32" alt="[ + ]" src="http://horus.fusionone.com/images/good.png" />';
my $bad  = '<img width="32" height="32" alt="[ - ]" src="http://horus.fusionone.com/images/bad.png" />';

my $tmpl_file = '/home/horus/support/main.tmpl';
my $tmpl = HTML::Template->new( filename => $tmpl_file );

my $guest = $user eq 'Guest' ? $cgi->a({-href=>'/login.cgi?path=/index.cgi'.$cgi->path_info},'Login') : "Welcome $user [ ".$cgi->a({-href=>'/login.cgi?logout=true'},'logout').' ]';

$tmpl->param( titlebar => 'Horus' );
$tmpl->param( title => 'Horus' );
$tmpl->param( guest => $guest );

my %hosts = $fh->all();
my $total = scalar keys %hosts;

my %decomm = $fh->all( decomissioned => 1 );
my $decomm_total = scalar keys %decomm;

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
            $cgi->td({-align=>'right'},$cgi->font({-size=>'1'},$guest)),
          )
        ),
        $cgi->hr({-noshade=>undef}),
        $cgi->font({-size=>1},$cgi->a({-href=>'/index.cgi/host/'.$host},'Back to host view'));

  if ( $configs_requiring_auth{$config} and not &authorized($user) ) {
    print $cgi->p('You are not authroized to view this config file.');
    return undef;
  }

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
  $tmpl->param( guest => $guest );

  my $body =  '[ '  
           . ( &authorized($user) ? $cgi->a({-href=>'/index.cgi/report/password'},"Passwords") . ' | ' : '' )
           . $cgi->a({-href=>'/index.cgi/report/network'},"Network Report") . ' | '
           . $cgi->a({-href=>'/index.cgi/report/os'},"OS Report")
           . ' ]';

  $body .= $cgi->p("$total hosts in the system.");
  $body .= $cgi->p("$decomm_total decomissioned hosts in the system.");

  my @rows = (
    $cgi->Tr(
      $cgi->td({-bgcolor=>$color_header},'Host'),
      $cgi->td({-bgcolor=>$color_header},'Customer'),
      $cgi->td({-bgcolor=>$color_header},'Category'),
      $cgi->td({-bgcolor=>$color_header},'Type'),
      $cgi->td({-bgcolor=>$color_header},'RAM'),
      $cgi->td({-bgcolor=>$color_header},'OS'),
      $cgi->td({-bgcolor=>$color_header},'Release'),
      $cgi->td({-bgcolor=>$color_header},'Version'),
      $cgi->td({-bgcolor=>$color_header},'Arch.'),
      $cgi->td({-bgcolor=>$color_header},'Brand'),
      $cgi->td({-bgcolor=>$color_header},'Model'),
      $cgi->td({-bgcolor=>$color_header},'Clock'),
      $cgi->td({-bgcolor=>$color_header},'Last&nbsp;Update'),
      ( &authorized_to_edit($user) ? $cgi->td({-bgcolor=>$color_header}, $cgi->start_form({-action=>'/edit.cgi'}), $cgi->submit({-name=>'New'}), $cgi->end_form ) : '' ),
    )
  );

  for my $id ( sort { lc($hosts{$a}) cmp lc($hosts{$b}) } keys %hosts ) {
    my %rec = $fh->get($id);

    $rec{last_modified} =~ /(\d{4}-\d\d-\d\d)/;
    my $time = $1;

    map { $rec{$_}=~s/\s/\&nbsp;/g } qw/osrelease osversion machine_model customer ram/;

    my $bg = $rec{skip} == 1 ? $color_subhead : $color_back;  
  
    push @rows, $cgi->Tr(
      $cgi->td({-bgcolor=>$bg}, $cgi->a({-href=>"/index.cgi/host/$hosts{$id}"},$hosts{$id}) ),
      $cgi->td({-bgcolor=>$bg}, "$rec{customer}" ),
      $cgi->td({-bgcolor=>$bg}, "$rec{category}" ),
      $cgi->td({-bgcolor=>$bg}, "$rec{type}" ),
      $cgi->td({-bgcolor=>$bg}, "$rec{ram}" ),
      $cgi->td({-bgcolor=>$bg}, "$rec{os}" ),
      $cgi->td({-bgcolor=>$bg}, "$rec{osrelease}" ),
      $cgi->td({-bgcolor=>$bg}, "$rec{osversion}" ),
      $cgi->td({-bgcolor=>$bg}, "$rec{arch}" ),
      $cgi->td({-bgcolor=>$bg}, "$rec{machine_brand}" ),
      $cgi->td({-bgcolor=>$bg}, "$rec{machine_model}" ),
      $cgi->td({-bgcolor=>$bg,-align=>'center'}, "$rec{tz}" ),
      $cgi->td({-bgcolor=>$bg,-align=>'center'}, $time ),
      ( &authorized_to_edit($user) ? $cgi->td({-bgcolor=>$bg,-align=>'center'}, $cgi->start_form({-action=>'/edit.cgi'}), $cgi->hidden({-name=>'id',-value=>$id}), $cgi->submit({-name=>'Edit'}), $cgi->end_form ) : '' ),
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
  $tmpl->param( guest => $guest );

  my $body = $cgi->font({-size=>1},$cgi->a({-href=>'/index.cgi/dashboard'},'Back to Dashboard'));

  my $possible = $fh->by_name($host);
  my %rec = $fh->get($possible->[0]);

  unless ( &authorized($user) ) {
    $rec{username} = '********';
    $rec{password} = '********';
  }

  my %used = map {$_,1} qw/last_modified id created customer machine_brand machine_model arch os 
    osrelease osversion name uptime ntp ntphost remote snmp snmp_community/;

  for my $key ( keys %used ) {
    $rec{$key} = '&nbsp;' unless $rec{$key};
  }

  if ( $rec{remote} =~ /^https?:\/\//i ) {
    $rec{remote} = $cgi->a({-href=>$rec{remote}},$rec{remote});
  }
  
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
      ),
      $cgi->Tr(
        $cgi->td({-bgcolor=>$color_header},'Machine RAM'), $cgi->td({-bgcolor=>$color_back},$rec{ram}),
        $cgi->td({-bgcolor=>$color_header},'Remote'), $cgi->td({-bgcolor=>$color_back},$rec{remote})
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
    $body .= $cgi->li($cgi->a({-href=>'?config='.$config},$config),( ($configs_requiring_auth{$config} and not &authorized($user)) ? $cgi->small('(authorization required)') : '' ));
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
  $tmpl->param( guest => $guest );

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
  $tmpl->param( guest => $guest );

  my $body = $cgi->font({-size=>1},$cgi->a({-href=>'/index.cgi/dashboard'},'Back to Dashboard'));

  my %os;
  my %counts;
  
  for my $id ( keys %hosts ) {
    my %rec = $fh->get($id);
    $os{$rec{'os'}}{$rec{'osrelease'}}{$rec{'osversion'}}++;
    $counts{os}{$rec{'os'}}++;
    $counts{release}{$rec{'os'}.$rec{'osrelease'}}++;
  }

  for my $os ( sort keys %os ) {
    $body .= $cgi->p($cgi->b($os eq ''?'Unknown':$os),"($counts{os}{$os} servers)"), $cgi->start_ul;
    for my $release ( sort keys %{$os{$os}} ) {
      $body .= $cgi->li(($release eq '' ? 'Unknown' : $release),'(' .$counts{release}{$os.$release}. ' servers)');
      my @chunks;
      for my $version ( sort keys %{$os{$os}{$release}} ) {
        next if $release eq '';
        push @chunks, ($version eq '' ? 'Unknown' : $version) . " ($os{$os}{$release}{$version})";
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
  $tmpl->param( guest => $guest );

  my $body = $cgi->font({-size=>1},$cgi->a({-href=>'/index.cgi/dashboard'},'Back to Dashboard'));

  my @pass = $cgi->Tr( map {$cgi->td({-bgcolor=>$color_header},$_)} qw/Host User Pass Host User Pass Host User Pass/);
  my @chunks;
  
  for my $id ( sort { lc($hosts{$a}) cmp lc($hosts{$b}) } keys %hosts ) {
    my %rec = $fh->get($id);
    
    unless ( &authorized($user) ) {
      $rec{username} = '********';
      $rec{password} = '********';
    }

    push @chunks,
      $cgi->td({-bgcolor=>$color_subhead},$rec{name}) .
      $cgi->td({-bgcolor=>$color_back},$rec{username}) .
      $cgi->td({-bgcolor=>$color_back},$rec{password});
  }

  while ( scalar(@chunks) % 3 ) {
    push @chunks,
      $cgi->td({-bgcolor=>$color_subhead},'&nbsp;') .
      $cgi->td({-bgcolor=>$color_back},'&nbsp;') .
      $cgi->td({-bgcolor=>$color_back},'&nbsp;');
  }

  my $rows = scalar(@chunks) / 3; # Number of double rows
  
  for my $i ( 1 .. $rows ) {
    $i--; # 0 based arrays
    push @pass, $cgi->Tr( $chunks[$i], $chunks[$i+$rows], $chunks[$i+$rows+$rows] );
  }

  $body .= $cgi->p({-align=>'center'},box(@pass));
  $tmpl->param( body => $body );
  print $cgi->header, $tmpl->output;
}


### Subroutines

sub authorized {
  my $user = shift @_;
  return 1 if $user eq 'alee';
  return 1 if $user eq 'bmurphy';
  return 1 if $user eq 'btanaka';
  return 1 if $user eq 'mlysenko';
  return 1 if $user eq 'ppollard';
  return 1 if $user eq 'pzaura';
  return 1 if $user eq 'rob';
  return 1 if $user eq 'tamundson';
  return 1 if $user eq 'sbhalla';
  return 0;
}

sub authorized_to_edit {
  my $user = shift @_;
  return 1 if $user eq 'bmurphy';
  return 1 if $user eq 'btanaka';
  return 1 if $user eq 'ppollard';
  return 0;
}

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
