=head1 Horus::Hosts (Hosts.pm)

=head2 Summary

This module provides methods to interact with stored host information.

=cut

package Horus::Reports;

use Horus::DB;
use strict;

$Horus::Reports::VERSION = '$Revision: 1.1 $';

sub new {
  my $self = {};
  bless $self;
  $self->{db} = new Horus::DB;
  return $self;
}

=head2 Methods

=head1 Authorship:
 
  (c) 2007-2008, Horus, Inc.

  Work by Phil Pollard
  $Revision: 1.1 $ $Date: 2009/06/16 18:32:46 $
    
=cut

1;
