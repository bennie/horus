=head1 Fusionone::Ethernet (Ethernet.pm)

=head2 Summary

This module provides methods to interact with stored ethernet information.

=cut

package Fusionone::Ethernet;

use Fusionone::DB;
use strict;

$Fusionone::Ethernet::VERSION = '$Revision: 1.2 $';

sub new {
  my $self = {};
  bless $self;
  $self->{db} = new Fusionone::DB;
  return $self;
}

=head2 Methods

=head3 add($ref)

Returns the id of the ethernet created. Accepts a hash ref with any of
the following values:

  address, host_id, host_interface, switch_id, port, notes, last_modified

Required:

  address - unique hardware address of the machine.

=cut

sub add {
  my $self = shift @_;
  my $ref  = shift @_;
  my $ret  = $self->{db}->insert('ethernet',$ref);
  return undef unless $ret > 0;
  my $id   = $self->{db}->single('select last_insert_id()');
  return $id;
}


=head3 exists($address)

Returns true if the address is known in the DB.

=cut

sub exists {
  my $self = shift @_;
  my $addr = shift @_;
  return $self->{db}->single('select count(*) from ethernet where address=?',$addr);
}

=head3 update($address,$ref)

Returns the sql return code of the update dictated by the given id and hasref of 
values to update.

Values can be:

  host_id, switch_id, port, current_speed, max_speed, link_detected,
  notes, last_modified

=cut

sub update {
  my $self = shift @_;
  my $id   = shift @_;
  my $ref  = shift @_;
  return $self->{db}->update('ethernet','address',$id,$ref);
}

=head1 Authorship:

  (c) 2007, Fusionone, Inc.

  Work by Phil Pollard
  $Revision: 1.2 $ $Date: 2007/12/11 01:16:59 $

=cut

1;
