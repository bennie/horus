#!/usr/bin/perl -w -I/usr/lib/vmware-vcli/apps/ -I../lib

# $Id: report-esx.pl,v 1.4 2009/10/21 01:07:52 ppollard Exp $
# Based on "report-esx.pl" which is Copyright (c) 2007 VMware, Inc.

use Horus::Hosts;

use FindBin;
use lib "$FindBin::Bin/../";

use VMware::VIRuntime;
use AppUtil::VMUtil;

use strict;
use warnings;

$Util::script_version = "1.0";

sub create_hash;
sub get_vm_info;
sub print_log;

my %field_values = (
   'vmname'  => 'vmname',
   'numCpu'  =>  'numCpu',
   'memorysize' => 'memorysize' ,
   'virtualdisks' => 'virtualdisks',
   'template' => 'template',
   'vmPathName'=> 'vmPathName',
   'guestFullName'=> 'guestFullName',
   'guestId' => 'guestId',
   'hostName' => 'hostName',
   'ipAddress' => 'ipAddress',
   'toolsStatus' => 'toolsStatus',
   'overallCpuUsage' => 'overallCpuUsage',
   'hostMemoryUsage'=> 'hostMemoryUsage',
   'guestMemoryUsage'=> 'guestMemoryUsage',
   'overallStatus' => 'overallStatus',
);

my %toolsStatus = (
   'toolsNotInstalled' => 'VMware Tools has never been installed or has '
                           .'not run in the virtual machine.',
   'toolsNotRunning' => 'VMware Tools is not running.',
   'toolsOk' => 'VMware Tools is running and the version is current',
   'toolsOld' => 'VMware Tools is running, but the version is not current',
);

my %overallStatus = (
   'gray' => 'The status is unknown',
   'green' => 'The entity is OK',
   'red' => 'The entity definitely has a problem',
   'yellow' => 'The entity might have a problem',
);

my %opts = (
   'host' => {
      type      => "=s",
      variable  => "host",
      help      => "Name of the host" ,
      required => 0,
   },
);

Opts::add_options(%opts);
Opts::parse();
  
my @valid_properties;
my $filename;

### Main

my $ver = (split ' ', '$Revision: 1.4 $')[1];

my $h = new Horus::Hosts;
my $hosts = $h->all();

for my $hostid ( sort { 
  $hosts->{$a} =~ /(.+?)(\d*)$/; my $a_word = $1; my $a_num = $2; $a_num = -1 unless $a_num;
  $hosts->{$b} =~ /(.+?)(\d*)$/; my $b_word = $1; my $b_num = $2; $b_num = -1 unless $b_num;
  $hosts->{$a} =~ /esxi/ <=> $hosts->{$b} =~ /esxi/ || lc($a_word) cmp lc($b_word) || $a_num <=> $b_num
} keys %$hosts ) {
  my $host = $h->get($hostid);
  next unless $host->{os} and $host->{os} eq 'VMware';
  print "<p><b>$host->{name}:</b></p>\n";
  
  Opts::set_option('username',$host->{username});
  Opts::set_option('password',$host->{password});
  Opts::set_option('server',$host->{name});
  
  Opts::validate(\&validate);
  
  Util::connect();
  vm_info();
  Util::disconnect();

}


### Subroutines

sub vm_info {
  my %filter_hash = create_hash( Opts::get_option('ipaddress'), Opts::get_option('powerstatus'), Opts::get_option('guestos') );
  my $vm_views = VMUtils::get_vms ('VirtualMachine',
                                      Opts::get_option ('vmname'),
                                      Opts::get_option ('datacenter'),
                                      Opts::get_option ('folder'),
                                      Opts::get_option ('pool'),
                                      Opts::get_option ('host'),
                                     %filter_hash);
  return undef unless $vm_views;

  print "<table border=\"1\">\n";
  print "<tr><td bgcolor='#666699'>Host</td><td bgcolor='#666699'>Virtual Disk Path</td><td bgcolor='#666699'>Memory</td><td bgcolor='#666699'>Host Mem Use</td><td bgcolor='#666699'>Guest Mem Use</td><td bgcolor='#666699'>VM Tools</td></tr>\n";

  for my $vm_view ( sort { lc($a->name) cmp lc($b->name) } @$vm_views ) {
    my $name   = $vm_view->config->name();

    my $vpath  = $vm_view->summary->config->vmPathName();
    $vpath =~ s/ /&nbsp;/g;

    my $memory      = $vm_view->summary->config->memorySizeMB();
    my $hostmemuse  = $vm_view->summary->quickStats->hostMemoryUsage();
    my $guestmemuse = $vm_view->summary->quickStats->guestMemoryUsage();

    $memory = '-' unless $memory;
    $hostmemuse = '-' unless $hostmemuse;
    $guestmemuse = '-' unless $guestmemuse;

    my $tools = $vm_view->summary->guest->toolsStatus->val();
    $tools =~ s/^tools//;
    $tools = '&nbsp;' if $tools eq 'NotRunning';

    #my $numcpu = $vm_view->summary->config->numCpu();

    print "<tr><td><a href=\"http://horus.fusionone.com/index.cgi/host/$name\">$name</a></td><td>$vpath</td><td align=\"right\">$memory\&nbsp;MB</td><td align=\"right\">$hostmemuse\&nbsp;MB</td><td align=\"right\">$guestmemuse\&nbsp;MB</td><td align=\"center\">$tools</td></tr>\n";
  }
  
  print "</table>\n\n";
}

sub get_vm_info {
   my $filename;
   my %filter_hash = create_hash(Opts::get_option('ipaddress'),
                              Opts::get_option('powerstatus'),
                              Opts::get_option('guestos'));

   my $vm_views = VMUtils::get_vms ('VirtualMachine',
                                      Opts::get_option ('vmname'),
                                      Opts::get_option ('datacenter'),
                                      Opts::get_option ('folder'),
                                      Opts::get_option ('pool'),
                                      Opts::get_option ('host'),
                                     %filter_hash);
   if ($vm_views) {
   foreach (@$vm_views) {
      my $vm_view = $_;
      Util::trace(0,"\nInformation of Virtual Machine ". $_->name." \n\n");
      foreach (@valid_properties) {
         if ($_ eq 'vmname') {
            if (defined($vm_view->config) && defined ($vm_view->config->name)) {
               print_log($vm_view->config->name,"Name","Name");
            }
            else {
               print_log("Not Known","Name","Name");
            }
         }
         elsif($_ eq 'numCpu') {
            if (defined ($vm_view->summary->config->numCpu)) {
               print_log($vm_view->summary->config->numCpu,
                                     "noCPU","No. of CPU(s)");
            }
            else {
               print_log("Not Known","noCPU","No. of CPU(s)");
            }
         }
         elsif($_ eq 'memorysize') {
            if (defined ($vm_view->summary->config->memorySizeMB)) {
               print_log($vm_view->summary->config->memorySizeMB,
                                            "memorySize","Memory Size");
            }
            else {
               print_log("Not Known","memorySize","Memory Size");
            }
         }
         elsif($_ eq 'virtualdisks') {
            if (defined ($vm_view->summary->config->numVirtualDisks)) {
               print_log($vm_view->summary->config->numVirtualDisks,
                                           "virtualDisks","Virtual Disks");
            }
            else {
               print_log("Not Known","virtualDisks","Virtual Disks");
            }
         }
         elsif($_ eq 'template') {
            if (defined ($vm_view->summary->config->template)) {
               print_log($vm_view->summary->config->template,"template","Template");
            }
            else {
               print_log("Not Known","template","Template");
            }
         }
         elsif($_ eq 'vmPathName') {
            if (defined ($vm_view->summary->config->vmPathName)) {
               print_log($vm_view->summary->config->vmPathName,
                                         "vmPathName","vmPathName");
            }
            else {
               print_log("Not Known","vmPathName","vmPathName");
            }
         }
         elsif($_ eq 'guestFullName') {
            if (defined ($vm_view->summary->guest->guestFullName)) {
               print_log($vm_view->summary->guest->guestFullName,"guestOS","Guest OS");
            }
            else {
               print_log("Not Known","guestOS","Guest OS");
            }
         }
         elsif($_ eq 'guestId') {
            if (defined ($vm_view->summary->guest->guestId)) {
               print_log($vm_view->summary->guest->guestId,"guestId","guestId");
            }
            else {
               print_log("Not Known","guestId","guestId");
            }
         }
         elsif($_ eq 'hostName') {
            if (defined ($vm_view->summary->guest->hostName)) {
               print_log($vm_view->summary->guest->hostName,"hostName","Host name");
            }
            else {
               print_log("Not Known","hostName","Host name");
            }
         }
         elsif($_ eq 'ipAddress') {
            if (defined ($vm_view->summary->guest->ipAddress)) {
               print_log($vm_view->summary->guest->ipAddress,"ipAddress","IP Address");
            }
            else {
               print_log("Not Known","ipAddress","IP Address");
            }
         }
         elsif($_ eq 'toolsStatus') {
            if (defined ($vm_view->summary->guest->toolsStatus)) {
               my $status = $vm_view->summary->guest->toolsStatus->val;
               print_log($toolsStatus{$status},"VMwareTools","VMware Tools");
            }
         }
         elsif($_ eq 'overallCpuUsage') {
            if (defined ($vm_view->summary->quickStats->overallCpuUsage)) {
               print_log($vm_view->summary->quickStats->overallCpuUsage.
                                           " MHz","cpuUsage","Cpu usage");
            }
            else {
               print_log("Not Known","cpuUsage","Cpu usage");
            }
         }
         elsif($_ eq 'hostMemoryUsage') {
            if (defined ($vm_view->summary->quickStats->hostMemoryUsage)) {
               print_log($vm_view->summary->quickStats->hostMemoryUsage.
                               " MB","hostMemoryUsage","Host memory usage");
            }
            else {
               print_log("Not Known","hostMemoryUsage","Host memory usage");
            }
         }
         elsif($_ eq 'guestMemoryUsage') {
            if (defined ($vm_view->summary->quickStats->guestMemoryUsage)) {
               print_log($vm_view->summary->quickStats->guestMemoryUsage.
                             " MB","guestMemoryUsage","Guest memory usage");
            }
            else {
               print_log("Not Known","guestMemoryUsage","Guest memory usage");
            }
         }
         elsif ($_ eq 'overallStatus') {
            my $overall_status = $vm_view->summary->overallStatus->val;
            print_log($overallStatus{$overall_status},"overallStatus","Overall Status");
         }
         else {
            Util::trace(0, "$_ Not Supported\n");
         }
       }
    }
  }
}

sub print_log {
   my ($propvalue, $xmlprop, $prop) = @_;
   Util::trace(0, $prop.":\t\t ".$propvalue." \n");
}

sub create_hash {
   my ($ipaddress, $powerstatus, $guestos) = @_;
   my %filter_hash;
   if ($ipaddress) {
      $filter_hash{'guest.ipAddress'} = $ipaddress;
   }
   if ($powerstatus) {
      $filter_hash{'runtime.powerState'} = $powerstatus;
   }
## Bug 299213 fix start
   if ($guestos) {
      $filter_hash{'config.guestFullName'} = qr/\Q$guestos/i;
   }
   return %filter_hash;
## Bug 299213 fix end
}


# validate the host's fields to be displayed
# ===========================================
sub validate {
   my $valid = 1;
   my @properties_to_add;
   my $length =0;

   if (Opts::option_is_set('fields')) {
      my @filter_Array = split (',', Opts::get_option('fields'));
      foreach (@filter_Array) {
         if ($field_values{ $_ }) {
            $properties_to_add[$length] = $field_values{$_};
            $length++;
         }
         else {
            Util::trace(0, "\nInvalid property specified: " . $_ );
         }
      }
      @valid_properties =  @properties_to_add;
      if (!@valid_properties) {
         $valid = 0;
      }
   }
   else {
      @valid_properties = ("vmname",
                           "numCpu",
                           "memorysize",
                           "virtualdisks",
                           "template",
                           "vmPathName",
                           "guestFullName",
                           "guestId",
                           "hostName",
                           "ipAddress",
                           "toolsStatus",
                           "overallCpuUsage",
                           "hostMemoryUsage",
                           "guestMemoryUsage",
                           "overallStatus",
                            );
   }
  return $valid;   
}   
