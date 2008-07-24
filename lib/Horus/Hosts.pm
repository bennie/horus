=head1 Horus::Hosts (Hosts.pm)

=head2 Summary

This module provides methods to interact with stored host information.

=cut

package Horus::Hosts;

use Horus::DB;
use strict;

$Horus::Hosts::VERSION = '$Revision: 1.7 $';

sub new {
  my $self = {};
  bless $self;
  $self->{db} = new Horus::DB;
  return $self;
}

=head2 Methods

=head3 add($ref)

Returns the id of the host created. Accepts a has ref with any of the following 
values:

  name, os, osversion, arch, tz, snmp, snmp_community, net, ntphost, vm, 
  vmhost

=cut

sub add {
  my $self = shift @_;
  my $ref  = shift @_;
  my $ret  = $self->{db}->insert('hosts',$ref);
  return undef unless $ret > 0;
  my $id   = $self->{db}->single('select last_insert_id()');
  return $id;
}

=head3 all()

Returns a hash or hasref of all ids and their name from the hosts table.

=cut

sub all {
  my $self = shift @_;
  my $name = shift @_;
  my $sth = $self->{db}->handle('select id, name from hosts');
  my %out;
  while ( my $ref = $sth->fetchrow_arrayref ) {
    $out{$ref->[0]} = $ref->[1];
  }
  return wantarray ? %out : \%out;
}

=head3 by_name($name)

Returns an array or arrayref of possible host ID's that match this name.

=cut

sub by_name {
  my $self = shift @_;
  my $name = shift @_;
  return $self->{db}->column('select id from hosts where name like ?',$name);
}

=head3 get($id)

Returns an hash or hashref of the info for the requested machine..

=cut

sub get {
  my $self = shift @_;
  my $id   = shift @_;
  my $sth  = $self->{db}->handle('select * from hosts where id=?',$id);
  if ( my $ref = $sth->fetchrow_hashref ) {
    return wantarray ? %{$ref} : $ref;
  } else {
    return undef;
  }
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
 
  (c) 2007, Horus, Inc.

  Work by Phil Pollard
  $Revision: 1.7 $ $Date: 2008/07/24 22:35:06 $
    
=cut

1;
