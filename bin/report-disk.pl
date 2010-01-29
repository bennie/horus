#!/usr/bin/perl -w -I/home/horus/lib

# $Id: report-disk.pl,v 1.1 2010/01/29 00:57:44 ppollard Exp $
# Based on "report-esx.pl" which is Copyright (c) 2007 VMware, Inc.

#use FindBin;
#push @INC, "$FindBin::Bin/../lib";

use Horus::Hosts;

use strict;
use warnings;

### Main

my $ver = (split ' ', '$Revision: 1.1 $')[1];

my $h = new Horus::Hosts;
my $hosts = $h->all();

my %datapile;

#my $report = "<h1>Host Detail</h1>\n<p><small>Lines in grey denote VMs that are currently powered off.</small></p>\n";
#my $capacity_report = "<h1>Capacity Usage</h1>\n"
#                    . "<table border=\"1\">\n"
#                    . "<tr><td bgcolor='#666699'>Host</td><td bgcolor='#666699' colspan='2'>RAM allocation</td><td bgcolor='#666699'>Total&nbsp;RAM</td><td bgcolor='#666699'>Total&nbsp;VMs</td><td bgcolor='#666699'>Active&nbsp;VMs</td><td bgcolor='#666699'>Notes</td><td bgcolor='#666699'>Approximate&nbsp;Room*</td></tr>\n";

for my $hostid ( sort { 
  $hosts->{$a} =~ /(.+?)(\d*)$/; my $a_word = $1; my $a_num = $2; $a_num = -1 unless $a_num;
  $hosts->{$b} =~ /(.+?)(\d*)$/; my $b_word = $1; my $b_num = $2; $b_num = -1 unless $b_num;
  $hosts->{$a} =~ /esxi/ <=> $hosts->{$b} =~ /esxi/ || lc($a_word) cmp lc($b_word) || $a_num <=> $b_num
} keys %$hosts ) {
  my $host = $h->get($hostid);
  next unless $host->{os} and $host->{osrelease} and $host->{machine_brand} and $host->{osrelease} eq 'OnTap' and $host->{machine_brand} eq 'NetApp';  

  next unless $host->{name} eq 'netapp03';

  my $raw_data = `/home/horus/bin/remote-command.pl $host->{name} 'aggr show_space -m; logout telnet'`;
  my @chunks = split /Aggregate '/, $raw_data;
  
  for my $chunk (@chunks) {
    my @lines = split "\n", $chunk;
    next unless scalar(@lines) > 5;
      
    my $aggr_name = shift @lines;
    $aggr_name = $1 if $aggr_name =~ /^(\w+)'/;
    
    print "$host->{name} : $aggr_name : ";

    shift @lines; # blank line
    shift @lines; # upper title row

    my ($total_space, $wafl_reserve, $snap_reserve, $usable_space, $bsr_nvlog ) = split ' ', shift @lines; 
 
    print "$total_space";
    print "\n";

    shift @lines; # blank line
    shift @lines; # "Space allocated to volumes in the aggregate"
    shift @lines; # blank line
    shift @lines; # volume title row
    
    while ( $lines[0] =~ /^(.*?)\s+(\d+)MB\s+(\d+)MB\s+(\S+)$/ ) {
      my $vol_name = $1;
      my $vol_allocated = $2;
      my $vol_used = $3;
      my $vol_guarntee = $4;
      print " - $vol_name - $vol_used / $vol_allocated\n";
      shift @lines;
    }    

    shift @lines; # blank line
    shift @lines; # bottom title row
  }
}

#$capacity_report .= "</table>\n<small>* Approximate number of 2 GB RAM hosts that could be created on this server.</small>\n";

#print $capacity_report;
#print $report;

