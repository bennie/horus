#!/usr/bin/perl -I../lib

use Fusionone::Hosts;

use CGI;
use strict;

my $cgi = new CGI;
my $fh = new Fusionone::Hosts;

my %skip = map {$_,1;} qw/arch id last_modified ntphost osversion snmp_community tz/;

print $cgi->header, $cgi->start_html( -title=> 'Editing a Host');

if ( $cgi->param('Update') && $cgi->param('id') ) {
  my $ref = {};

  for my $param ( $cgi->param() ) {
    next if $param eq 'Update';
    next if $param eq 'id';
    next unless length $cgi->param($param);
    print $param,' : ',$cgi->param($param), $cgi->br;
    $ref->{$param} = $cgi->param($param);
  }

  my $ret = $fh->update($cgi->param('id'),$ref);

  print $cgi->p("Update returned $ret");

  print $cgi->a({-href=>'index.cgi'},'Back');

} elsif ( ( $cgi->param('Edit') and $cgi->param('id') ) || $cgi->param('New') ) {
  my $id = $cgi->param('id');

  unless ($id) {
    $id = $fh->add({ name => 'New Host' });
  }

  my %rec = $fh->get($id);
  #my @custs = $fh->list_customers;

  print $cgi->p($cgi->b("$id) $rec{name}")), 
        $cgi->hr({-noshade=>undef});

  print $cgi->start_form, $cgi->hidden({name=>'id',value=>$id});;

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
  print $cgi->start_form, $cgi->submit({-name=>'New'}),$cgi->end_form;
  for my $id ( sort { lc($hosts{$a}) cmp lc($hosts{$b})  } keys %hosts ) {
    print $cgi->start_form, "$hosts{$id}", $cgi->hidden({-name=>'id',-value=>$id}), $cgi->submit({-name=>'Edit'}), $cgi->end_form;
  }
}

print $cgi->end_html;

