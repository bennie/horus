=head1 Horus::Reports (Reports.pm)

=head2 Summary

This module provides methods to interact with stored host information.

=cut

package Horus::Reports;

use Horus::DB;
use strict;

$Horus::Reports::VERSION = '$Revision: 1.3 $';

sub new {
  my $self = {};
  bless $self;
  $self->{db} = new Horus::DB;
  return $self;
}

=head2 Methods

=head3 get()

Returns an the text of the reqested report.

=cut

sub get {
  my $self = shift @_;
  my $name = shift @_;
  return $self->{db}->single('select report from reports where name=?',$name);
}

=head3 list()

Returns an array or arrayref of the available reports.

=cut

sub list {
  my $self = shift @_;
  return $self->{db}->column('select name from reports order by report');
}

=head1 Authorship:
 
  (c) 2007-2008, Horus, Inc.

  Work by Phil Pollard
  $Revision: 1.3 $ $Date: 2009/06/23 23:47:01 $
    
=cut

1;
