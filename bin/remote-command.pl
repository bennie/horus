#!/usr/bin/perl -I../lib

use Horus::Hosts;

use Getopt::Long;
use Net::SSH::Expect;
use Net::SSH::Perl;

require Math::BigInt::GMP; # For speed on Net::SSH::Perl;

use strict;

### Prep

my $ver = (split ' ', '$Revision: 1.1 $')[1];
my $use_expect = 0;
my $quiet = 1;

my $hostname = shift @ARGV;
my $command  = join ' ', @ARGV;


print "You want to run '$command' on $hostname\n" unless $quiet;

### Main

our $ssh;

my $hosts = new Horus::Hosts;

my @hostids = $hosts->by_name($hostname);
my $hostid  = @hostids[0];

die "Bad hostname" unless $hostid;

my $ret = &open_connection($hostid);
exit unless $ret;

print run($command) . "\n";

### Subroutines

# Open a connection
sub open_connection {
  my $hostid = shift @_;
  my $ref = $hosts->get($hostid);

  my $host = $ref->{name};
  my $user = $ref->{username};
  my $pass = $ref->{password};

  $user = 'root' unless length $user;

  debug("\nTrying $host " .( $user && $pass ? 'with' : 'without' ). " a password\n");

  if ( $use_expect ) {

    my $conf = {
      host => $host,
      user => $user,
      raw_pty => 1,
      timeout => 2
    };

    $conf->{password} = $pass if $pass;

    our $ssh = Net::SSH::Expect->new(%$conf);

    if ( $conf->{password} ) {
      my $logintext;
      eval { $logintext = $ssh->login(); };
      if ( $@ ) { warn $@; return 0; }

      if ( $logintext !~ /Welcome/ and $logintext !~ /Last login/ ) {
        warn "Login failed: \n\n$logintext\n\n";
        return 0;
      }

    } else {
      unless ( $ssh->run_ssh() ) {
        warn "SSH Process couldn't start: $!";
        return 0;
      }

      my $read;
      eval { $read = $ssh->read_all(2); };
      if ( $@ ) { warn $@; return 0; }

      unless ( $read =~ /[>\$\#]\s*\z/ ) {
        warn "Where is the remote prompt? $read";
        return 0;
      }

      $ssh->exec("stty raw -echo"); # Turn off echo
    }

  } else {

   my @conf = (protocol=>'2,1', debug=>0);
   push @conf, 'identity_files' => [] if length $user and length $pass;
  
    our $ssh = Net::SSH::Perl->new($host, @conf );
    eval { $ssh->login($user,$pass); };
    if ( $@ ) { warn $@; return 0; }

  }
  
  return 1;
}


# Run a command on the remote host
sub run {
  my $command = shift @_;
  our $ssh;

  if ( $use_expect ) {
    my @ret = split "\n", $ssh->exec($command);
    pop @ret;
    return join("\n",@ret);
  } else {
    my ($stdout,$stderr,$exit) = $ssh->cmd($command);
    chomp $stdout;
    return $stdout;
  }
}

sub debug {
  return if $quiet;
  print STDERR @_;
}
