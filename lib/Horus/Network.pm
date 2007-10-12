=head1 Fusionone::Ethernet (Ethernet.pm)

=head2 Summary

This module provides methods to interact with stored ethernet information.

=cut

package Fusionone::Ethernet;

use Fusionone::DB;
use strict;

$Fusionone::Ethernet::VERSION = '$Revision: 1.1 $';

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

  host_id, switch_id, port, notes, last_modified

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

=head3 update($address,$ref)

Returns the sql return code of the update dictated by the given id and hasref of 
values to update.

Values can be:

  host_id, switch_id, port, notes, last_modified

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
  $Revision: 1.1 $ $Date: 2007/10/12 01:09:47 $

=cut

1;
