=head1 Fusionone::DB (DB.pm)

=cut

package Fusionone::DB;

use DBI;
use Fusionone::Utils qw/zt/;
use strict;

$Fusionone::DB::VERSION = '$Revision: 1.1 $';

sub new {
  my     $self = {};
  bless  $self;
         $self->_initialize();
  return $self;
}

sub _initialize {
  my $self = shift @_;
  $self->{debug} = 0;

  # DB config  
  my $db_driver = 'mysql';
  my $db_name   = 'info';
  my $db_user   = 'info';
  my $db_pass   = 'info';

  my @db_connect = ("dbi:$db_driver:dbname=$db_name", $db_user, $db_pass);

  $self->{dbh} = DBI->connect(@db_connect)
                 or die "Connecting: $DBI::errstr" . join(',',@db_connect);
}

sub DESTROY {
  my $self = shift @_;
  $self->{dbh}->disconnect;
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

=head2 all($sql)

Creates an arrayref of hashrefs of each row returned. 

 [ $row1, $row2, etc ]

Use sparringly

=cut

sub all {
  my $self = shift @_;
  my $sql  = shift @_;
  my @bind =       @_;

  my $sth = $self->{dbh}->prepare($sql);
  my $ret = $sth->execute(@bind);

  return [] unless $ret;

  my @out;

  while ( my $row = $sth->fetchrow_hashref ) {
    push @out, $row;
  }

  return \@out;
}

=head2 execute($sql)

Good for inserts, etc.

=cut

sub execute {
  my $self = shift @_;
  my $sql  = shift @_;
  my @bind =       @_;

  my $sth = $self->{dbh}->prepare($sql);
  my $ret = $sth->execute(@bind);
            $sth->finish;

  return $ret;
}

=head2 get_dbh()

Returns the db handle

=cut 

sub get_dbh {
  return $_[0]->{dbh};
}

=head2 insert($table,$ref)

inserts the hashref of data into the given table

=cut

sub insert {
  my $self  = shift @_;
  my $table = shift @_; 
  my $data  = shift @_;

  my @name = sort keys %$data;

  my $sql = "insert into $table ("
          . join(',', @name)
          . ') values ('
          . join(',', ( map { '?' } @name ))
          . ')';

  my $ret = $self->execute($sql,( map {$data->{$_}} @name ));

  return wantarray ? ( $ret, $sql ) : $ret;
}

=head2 query_column($sql)

Returns only one column of a DB query as an array

=cut

sub query_column {
  my $self = shift @_;
  my $sql  = shift @_;
  my @bind =       @_;

  my $sth = $self->{dbh}->prepare($sql);
  my $ret = $sth->execute(@bind);

  my @out;

  while ( my @ret = $sth->fetchrow_array ) {
    push @out, $ret[0];
  }

  $sth->finish;

  return @out;
}

=head2 query_handle($sql)

Returns query handle

=cut

sub query_handle {
  my $self = shift @_;
  my $sql  = shift @_;
  my @bind =       @_;

  my $sth = $self->{dbh}->prepare($sql);
  my $ret = $sth->execute(@bind);

  return wantarray ? ( $ret, $sth ) : $sth;
}

=head2 query_row($sql)

Returns only one row of a DB query as an array

=cut

sub query_row {
  my $self = shift @_;
  my $sql  = shift @_;

  my $sth = $self->{dbh}->prepare($sql);
  my $ret = $sth->execute(@_);

  if ($ret != 1 && $ret ne '0E0') { 
    die "Bad return code of $ret on single row query with SQL: $sql\n"; 
  }

  my @ret = $sth->fetchrow_array;

  $sth->finish;

  return @ret;
}

=head2 quote($text)

=cut

sub quote {
  my $self = shift @_;
  return $self->{dbh}->quote(@_);
}

=head2 single($sql)

Returns the first value from the first row of a sql query. Designed for a
single answer query.

=cut

sub single {
  my $self = shift @_;
  my $sql  = shift @_;
  my @bind =       @_;
  my $sth  = $self->{dbh}->prepare($sql);
  my $ret  = $sth->execute(@bind);
  my $ref  = $sth->fetchrow_arrayref;
  $sth->finish;
  return $ref->[0];
}

=head2 time($epoch)

Takes time (num of seconds) and converts it to mysql DB format

=cut

sub time {
  my $self = shift @_;
  my @time = localtime(shift @_);

  my $year  = zt( $time[5] + 1900 );
  my $month = zt( $time[4] + 1    );
  my $day   = zt( $time[3]        );
  my $hour  = zt( $time[2]        );
  my $min   = zt( $time[1]        );
  my $sec   = zt( $time[0]        );

  return $year.$month.$day.$hour.$min.$sec;
}

=head1 Authorship:

  (c) 2007, Fusionone, Inc. 

  Work by Phil Pollard
  $Revision: 1.1 $ $Date: 2007/10/08 23:58:58 $

  Some portions of this module are (c) 1999-2007, Phillip Pollard
  and were released under GPL v2.

=cut

1;
