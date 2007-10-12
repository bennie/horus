=head1 Fusionone::Hosts (Hosts.pm)

=head2 Summary

This module provides methods to interact with stored host information.

=cut

package Fusionone::Hosts;

use Fusionone::DB;
use strict;

$Fusionone::Hosts::VERSION = '$Revision: 1.4 $';

sub new {
  my $self = {};
  bless $self;
  $self->{db} = new Fusionone::DB;
  return $self;
}

=head2 Methods

=head3 add($ref)

Returns the id of the host created. Accepts a has ref with any of the following 
values:

  name, os, osversion, arch, tz, snmp, snmp_community, net, ntphost

=cut

sub add {
  my $self = shift @_;
  my $ref  = shift @_;
  my $ret  = $self->{db}->insert('hosts',$ref);
  return undef unless $ret > 0;
  my $id   = $self->{db}->single('select last_insert_id()');
  return $id;
}

=head3 by_name($name)

Returns an array or arrayref of possible host ID's that match this name.

=cut

sub by_name {
  my $self = shift @_;
  my $name = shift @_;
  return $self->{db}->column('select id from hosts where name like ?',$name);
}

=head3 update($id,$ref)

Returns the sql return code of the update dictated by the given id and hasref of 
values to update.

Values can be:

  name, os, osversion, arch, tz, snmp, snmp_community, net, ntphost

=cut

sub update {
  my $self = shift @_;
  my $id   = shift @_;
  my $ref  = shift @_;
  return $self->{db}->update('hosts','id',$id,$ref);
}

=head1 Authorship:
 
  (c) 2007, Fusionone, Inc.

  Work by Phil Pollard
  $Revision: 1.4 $ $Date: 2007/10/12 01:09:47 $
    
=cut

1;
