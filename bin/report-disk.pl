#!/usr/bin/perl -w -I/home/horus/lib

# $Id: report-disk.pl,v 1.3 2010/01/29 20:46:30 ppollard Exp $
# Based on "report-esx.pl" which is Copyright (c) 2007 VMware, Inc.

#use FindBin;
#push @INC, "$FindBin::Bin/../lib";

use Data::Dumper qw/Dumper/;
use Horus::Hosts;

use strict;
use warnings;

### Main

my $ver = (split ' ', '$Revision: 1.3 $')[1];

my $h = new Horus::Hosts;
my $hosts = $h->all();

my $debug = 1;
my %datapile;

for my $hostid ( sort { 
  $hosts->{$a} =~ /(.+?)(\d*)$/; my $a_word = $1; my $a_num = $2; $a_num = -1 unless $a_num;
  $hosts->{$b} =~ /(.+?)(\d*)$/; my $b_word = $1; my $b_num = $2; $b_num = -1 unless $b_num;
  $hosts->{$a} =~ /esxi/ <=> $hosts->{$b} =~ /esxi/ || lc($a_word) cmp lc($b_word) || $a_num <=> $b_num
} keys %$hosts ) {
  my $host = $h->get($hostid);
  next unless $host->{osrelease} and $host->{osrelease} eq 'OnTap';  

  next if $host->{name} eq 'vz02-nas01';
  print STDERR "Connecting to $host->{name}\n" if $debug;

  my $raw_data = `/home/horus/bin/remote-command.pl $host->{name} 'aggr show_space -m; logout telnet'`;
  my @chunks = split /Aggregate '/, $raw_data;
  
  for my $chunk (@chunks) {
    my @lines = split "\n", $chunk;
    next unless scalar(@lines) > 5;
      
    my $aggr_name = shift @lines;
    $aggr_name = $1 if $aggr_name =~ /^(\w+)'/;
    
    my %aggr;

    shift @lines; # blank line
    shift @lines; # upper title row

    ($aggr{total_space}{total}, $aggr{wafl_reserve}{total}, $aggr{snap_reserve}{total}, $aggr{usable_space}, $aggr{bsr_nvlog} ) = map { $_ =~ s/MB$//; $_ } split ' ', shift @lines; 
 
    shift @lines; # blank line
    shift @lines; # "Space allocated to volumes in the aggregate"
    shift @lines; # blank line
    shift @lines; # volume title row
    
    while ( $lines[0] =~ /^(.*?)\s+(\d+)MB\s+(\d+)MB\s+(\S+)$/ ) {
      my $vol_name = $1;
      my $vol_allocated = $2;
      my $vol_used = $3;
      my $vol_guarntee = $4;

      $aggr{volumes}{$vol_name}{allocated} = $vol_allocated;
      $aggr{volumes}{$vol_name}{used} = $vol_used;
      $aggr{volumes}{$vol_name}{guarentee} = $vol_guarntee;

      shift @lines;
    }    

    shift @lines; # blank line
    shift @lines; # bottom title row

    while ( $lines[0] and $lines[0] =~ /^(.*?)\s+(\d+)MB\s+(\d+)MB\s+(\d+)MB\s*$/ ) {
      my $row = $1; my $allocated = $2; my $used = $3; my $avail = $4;
      $row = lc($row); $row =~ tr/ /_/;
      $aggr{$row}{allocated} = $2;
      $aggr{$row}{used} = $3;
      $aggr{$row}{available} = $4;
      shift @lines;
    }

    $datapile{$host->{name}}{$aggr_name} = \%aggr;
  }
}

### Report time!

print "<h1>Systems Summary</h1>\n"
    . "<table border=\"1\">\n"
    . "<tr><td bgcolor='#666699'>Host</td><td bgcolor='#666699' colspan='2'>Disk&nbsp;Consumption</td><td bgcolor='#666699'>Used</td><td bgcolor='#666699'>Total</td></tr>\n";

for my $host ( sort keys %datapile ) {
  my $used = 0;
  my $total = 0;

  for my $aggr ( keys %{$datapile{$host}} ) {
    $used  += $datapile{$host}{$aggr}{total_space}{used};
    $total += $datapile{$host}{$aggr}{usable_space};
  }

  my $readable_used = readable_mb($used);
  my $readable_total = readable_mb($total);

  my ($percent,$image) = &percent_and_image( $used, $total );

  printf "<tr><td>%s</td><td>%d%%</td><td>%s</td><td align='right'>%s</td><td>%s</td align='right'></tr>\n", $host, $percent, $image, $readable_used, $readable_total;
}

print "</table>\n"
    . "<small>NB: After 80% disk consumption, Netapp performance falls exponentially.</small>";

print "<h1>Host Details</h1>\n";

for my $host ( sort keys %datapile ) {
  print "<p><b>$host:</b></p><table border=\"1\">\n"
      . "<tr><td bgcolor='#666699'>Aggregate</td><td bgcolor='#666699'>Volume</td><td bgcolor='#666699'>Allocation</td><td bgcolor='#666699' colspan='2'>Consumption</td></tr>\n";
  for my $aggr ( sort keys %{$datapile{$host}} ) {
    for my $vol ( sort keys %{$datapile{$host}{$aggr}{volumes}} ) {
      my ($percent,$image) = &percent_and_image( $datapile{$host}{$aggr}{volumes}{$vol}{used}, $datapile{$host}{$aggr}{volumes}{$vol}{allocated} );
      my $readable_allocation = &readable_mb( $datapile{$host}{$aggr}{volumes}{$vol}{allocated} );
      printf "<tr><td>%s</td><td>%s</td><td>%s</td><td>%d%%</td><td>%s</td></tr>\n", $aggr, $vol, $readable_allocation, $percent, $image;
    }
  }
  print "</table>\n";
}

#print "<h1>Raw Data</h1>\n<pre>", Dumper(\%datapile), "</pre>\n";

### Subroutines

sub percent_and_image {
  my $num1 = shift @_;
  my $num2 = shift @_;

  my $raw_percent = 0;  
  $raw_percent = $num1 / $num2 if ( $num1 and $num2 and $num2 != 0 );
    
  my $percent = int( $raw_percent * 100 );
  my $image = '<img width=100 height=10 src="/images/meter/'. ($percent > 100 ? 100 : $percent) .'.jpg" />';

  return ( $percent, $image );
}

sub readable_mb {
  my $megabytes = shift @_;
  return 'Err MB' unless defined $megabytes;
  return "$megabytes MB" if $megabytes < 1025;
  my $gigabytes = sprintf '%.2f', ( $megabytes / 1024 );
  return "$gigabytes GB" if $gigabytes < 1025;
  my $terrabytes = sprintf '%.2f', ( $gigabytes / 1024 );
  return "$terrabytes TB";  
}