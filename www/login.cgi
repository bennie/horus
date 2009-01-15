#!/usr/bin/perl -I../lib

# $Id: login.cgi,v 1.1 2009/01/15 00:03:38 ppollard Exp $

use Horus::Auth;
use strict;

my $ha = new Horus::Auth;
my $cgi = $ha->{cgi};

print $cgi->header, $cgi->start_html, "Success!", $cgi->end_html;