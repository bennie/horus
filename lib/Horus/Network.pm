=head1 Horus::Network (Network.pm)

=head2 Summary

This module provides methods to interact with stored network information.

=cut

package Horus::Network;

use Horus::DB;
use strict;

sub new {
  my $self = {};
  bless $self;
  $self->{db} = new Horus::DB;
  return $self;
}

=head2 Methods

=head3 add($ref)

Returns the id of the network created. Accepts a hash ref with any of
the following values:

  address, host_id, host_interface, switch_id, port, notes, last_modified

Required:

  address - unique hardware address of the machine.

=cut

sub add {
  my $self = shift @_;
  my $ref  = shift @_;
  my $ret  = $self->{db}->insert('network',$ref);
  return undef unless $ret > 0;
  my $id   = $self->{db}->single('select last_insert_id()');
  return $id;
}

=head3 all()

 Returns an array or arrayref that is composed of hashrefs of data for 
 each network device of which there is info.

=cut

sub all {
  my $self = shift @_;
  return $self->{db}->all('select network.*, hosts.name as host_name from network, hosts where network.host_id = hosts.id');
}
 
=head3 exists($address)

Returns true if the address is known in the DB.

=cut

sub exists {
  my $self = shift @_;
  my $addr = shift @_;
  return $self->{db}->single('select count(*) from network where address=?',$addr);
}

=head3 get($addr) 

Returns a hash or hasref of all information lined to the given hardware address.
=cut

sub get {
  my $self = shift @_;
  my $addr = shift @_;
  my $sth  = $self->{db}->handle('select * from network where address=?',$addr);
  if ( my $ref = $sth->fetchrow_hashref ) {
    return wantarray ? %{$ref} : $ref;
  } else {
    return undef;
  }
}

=head3 host_list($hostid)

Returns an array or arrayref of addresses that are linked to the given host id.

=cut

sub host_list {
  my $self = shift @_;
  my $id = shift @_;
  return $self->{db}->column('select address from network where host_id=?',$id);
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
  return $self->{db}->update('network','address',$id,$ref);
}

=head1 Authorship:

  (c) 2007-YEARTAG, Horus, Inc.

  Work by Phil Pollard

=cut

1;
