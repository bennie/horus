#!/usr/bin/perl -I../lib

use CGI;
use Horus::Hosts;
use strict;

### Prep

my $ver = (split ' ', '$Revision: 1.2 $')[1];

my $color_header  = '#666699';

my $cgi = new CGI;
my $h   = new Horus::Hosts;

my $hosts = $h->all();

print $cgi->start_table({-border=>1});

print $cgi->Tr(
        $cgi->td({-bgcolor=>$color_header},'Host'),
        $cgi->td({-bgcolor=>$color_header},'Last OS Tune'),
        $cgi->td({-bgcolor=>$color_header},'Last Yum Command'),
        $cgi->td({-bgcolor=>$color_header},'Last Manual Backup')
      );

for my $hostid ( sort { lc($hosts->{$a}) cmp lc($hosts->{$b}) } keys %$hosts ) {
  print $cgi->start_Tr(), $cgi->td( $hosts->{$hostid} );

  for my $config ( map { '/var/f1/last_'.$_ } qw/ostune yum backup/ ) {
    my $raw = $h->config_get($hostid,$config); chomp $raw;
    $raw = undef if $raw =~ /^[\s\n]+$/;
    print $cgi->td({-align=>'center'}, $raw ? $raw : '&nbsp;' );
  }

  print $cgi->end_Tr;
}

print $cgi->end_table;
