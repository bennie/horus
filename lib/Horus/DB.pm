=head1 Horus::DB (DB.pm)

=cut

package Horus::DB;

use DBI;
use Horus::Utils qw/zt/;
use strict;

$Horus::DB::VERSION = '$Revision: 1.6 $';

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
  my $db_name   = 'horus';
  my $db_user   = 'horus';
  my $db_pass   = 'nochaos';

  my @db_connect = ("dbi:$db_driver:dbname=$db_name;host=mysql01.fusionone.com", $db_user, $db_pass);

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

=head2 column($sql)

Returns only one column of a DB query as an array

=cut

sub column {
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

  return wantarray ? @out : \@out;
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

=head2 handle($sql)

Returns query handle

=cut

sub handle {
  my $self = shift @_;
  my $sql  = shift @_;
  my @bind =       @_;

  my $sth = $self->{dbh}->prepare($sql);
  my $ret = $sth->execute(@bind);

  return wantarray ? ( $ret, $sth ) : $sth;
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

=head2 now($text)

Returns the current time from mysql.

=cut

sub now {
  my $self = shift @_;
  return $self->single('select now()');
}

=head2 quote($text)

Returns the given text as quotes safe for SQL.

=cut

sub quote {
  my $self = shift @_;
  return $self->{dbh}->quote(@_);
}

=head2 row($sql)

Returns only one row of a DB query as an array

=cut

sub row {
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

=head2 update($table,$idname,$idval,$hash_ref_of_values))

Update table values as indiciated by the hash ref.

Table and restricting id given.

=cut

sub update {
  my $self   = shift @_;
  my $table  = shift @_;
  my $idname = shift @_;
  my $idval  = shift @_;
  my $data   = shift @_;

  my @names = sort keys %$data;

  my $sql = "update $table set"
          . join(',', map { " $_=?" } @names)
          . " where $idname=?";

  my $ret = $self->execute($sql,( map {$data->{$_}} @names ),$idval);

  return wantarray ? ( $ret, $sql ) : $ret;
}

=head1 Authorship:

  (c) 2007, Horus, Inc. 

  Work by Phil Pollard
  $Revision: 1.6 $ $Date: 2009/11/04 22:53:45 $

  Some portions of this module are (c) 1999-2007, Phillip Pollard
  and were released under GPL v2.

=cut

1;
