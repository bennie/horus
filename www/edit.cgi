#!/usr/bin/perl -I../lib

use Horus::Auth;
use Horus::Hosts;

use HTML::Template;
use strict;

## Confs

my %skip = map {$_,1;} qw/arch created id last_modified ntp ntphost ram snmp snmp_community tz uptime vm/;
my %checkboxes = map {$_,1;} qw/decomissioned skip/;

my $tmpl_file = '/home/horus/support/main.tmpl';
my $tmpl = HTML::Template->new( filename => $tmpl_file );

my $ha = new Horus::Auth;
my $fh = new Horus::Hosts;

my $cgi  = $ha->{cgi};
my $user = $ha->{username};

# Default page values

my $guest = $user eq 'Guest' ? $cgi->a({-href=>'/login.cgi?path=/index.cgi'},'Login') : "$user [ ".$cgi->a({-href=>'/login.cgi?logout=true'},'logout').' ]';
my $nav = $cgi->a({-href=>'/index.cgi/dashboard'},'Back to Dashboard');
my $title = 'Horus: Editing a host';
my $titlebar = $title;
my $body; my $info;

# Start the page

print $cgi->header;

if ( $cgi->param('Update') && $cgi->param('id') ) {
  my $ref = {};

  my %params = map {$_,1;} $cgi->param(), keys %checkboxes; # Always check the value of the checkboxes

  for my $param ( sort keys %params ) {
    next if $param eq 'Update';
    next if $param eq 'id';

    my $value = $cgi->param($param);
    if ( $checkboxes{$param} ) { $value = $value ? 1:0; }

    next unless length $value;
    
    $ref->{$param} = $value;    
    $body .= $param . ' : ' .$value . $cgi->br;
  }

  my $ret = $fh->update($cgi->param('id'),$ref);

  $title = "Update returned $ret";

} elsif ( ( $cgi->param('Edit') and $cgi->param('id') ) || $cgi->param('New') ) { # Edit a host!
  my $id = $cgi->param('id');

  unless ($id) {
    $id = $fh->add({ name => 'New Host' });
  }

  my %rec = $fh->get($id);
  #my @custs = $fh->list_customers;

  $title = "Editing: $rec{name}";
  $titlebar = "Horus: Editing $rec{name}";

  $body .= $cgi->start_form . $cgi->hidden({name=>'id',value=>$id});

  my @first = qw/name username password category customer decomissioned skip remote remote_user remote_pass serial rack rack_position rack_patching switch_ports os type/;
  my %first = map { $_,1; } @first;
  my @keys = @first;
  for my $key ( sort { lc($a) cmp lc($b) } keys %rec ) { push @keys, $key unless $first{$key} }

  my @chunks;
  for my $key ( @keys ) {
    next if $skip{$key};
    push @chunks, ( $checkboxes{$key} 
            ? $cgi->p($cgi->checkbox({-name=>$key,-checked=>($rec{$key}?1:0)}))
            : $cgi->p($key,':',$cgi->textfield({-name=>$key,-value=>$rec{$key}})) 
          );
  }

  my @col1;
  for ( 1 .. int(scalar(@chunks)/2) ) {
    push @col1, shift @chunks;
  }
  
  $body .= $cgi->table({-cellpadding=>'10'},
            $cgi->Tr({-valign=>'top'},
              $cgi->td(@col1),
              $cgi->td(@chunks)
            )
          );

  $body .= $cgi->submit({-name=>'Update'});
  $body .= $cgi->hr({-noshade=>undef});

  for my $key ( sort keys %skip) {
    $body .= $cgi->b($key) . ': ' . $rec{$key} . $cgi->br;
  }

  $body .= $cgi->end_form;

} else {
  my %hosts = $fh->all();
  $body .= $cgi->start_form . $cgi->submit({-name=>'New'}) . $cgi->end_form;
  for my $id ( sort { lc($hosts{$a}) cmp lc($hosts{$b})  } keys %hosts ) {
    $body .= $cgi->start_form . "$hosts{$id}" . $cgi->hidden({-name=>'id',-value=>$id}) . $cgi->submit({-name=>'Edit'}), $cgi->end_form;
  }
}

$tmpl->param( body => $body, info => $info, nav => $nav, guest => $guest, title => $title, titlebar => $titlebar );
print $tmpl->output;