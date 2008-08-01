=head1 Horus::Conf (Conf.pm)

=cut

package Horus::Conf;

use strict;

$Horus::Conf::VERSION = '$Revision: 1.1 $';

sub new {
  my     $self = {};
  bless  $self;
         $self->_initialize();
  return $self;
}

sub _initialize {
  my $self = shift @_;
  $self->{debug} = 0;
}

sub DESTROY {
  my $self = shift @_;
}

###
### Private Methods
###

sub _debug {
  my $self = shift @_;
  my $text = shift @_;

  if ($self->{debug} > 0) {
    print "DEBUG: $text\n";
  }  
}

###
### Public Methods
###

=head1 Methods:

=cut

=head1 Authorship:

  (c) 2008, Horus, Inc. 

  Work by Phil Pollard
  $Revision: 1.1 $ $Date: 2008/08/01 20:13:44 $

=cut

1;
