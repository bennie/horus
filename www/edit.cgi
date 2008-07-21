#!/usr/bin/perl -I../lib

use Fusionone::Hosts;

use CGI;
use strict;

my $cgi = new CGI;
my $fh = new Fusionone::Hosts;

my %skip = map {$_,1;} qw/arch id last_modified ntphost osversion snmp_community tz/;

print $cgi->header, $cgi->start_html( -title=> 'Hello, World!');

if ( $cgi->param('Edit') and $cgi->param('id') ) {

  my $id = $cgi->param('id');
  my %rec = $fh->get($id);

  print $cgi->p($cgi->b("$id) $rec{name}")), 
        $cgi->hr({-noshade=>undef});

  print $cgi->start_html;

  for my $key ( keys %rec ) {
    next if $skip{$key};
    print $cgi->p($key,':',$cgi->textfield({-name=>$key,-value=>$rec{$key}}));
  }

  print $cgi->hr({-noshade=>undef});

  for my $key ( sort keys %skip) {
    print $cgi->p($key,':',$rec{$key});
  }

  print $cgi->hr({-noshade=>undef}),
        $cgi->submit({-name=>'Update'}),
        $cgi->end_form;

} else {
  my %hosts = $fh->all();
  for my $id ( keys %hosts ) {
    print $cgi->p("$hosts{$id}",
            $cgi->start_form, $cgi->hidden({-name=>'id',-value=>$id}), $cgi->submit({-name=>'Edit'}), $cgi->end_form,
          );
  }
}

print $cgi->end_html;

