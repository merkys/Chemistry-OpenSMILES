#!/usr/bin/perl

use strict;
use warnings;
use OpenSMILES::Parser;
use Test::More tests => 1;

my @cases = qw(
    [U]     [Pb]   [He]   [*]
    [CH4]   [ClH]  [ClH1]
    [Cl-]   [OH1-] [OH-1] [Cu+2] [Cu++]
    [13CH4] [2H+]  [238U]
);

my $parser;
for (@cases) {
    $parser = OpenSMILES::Parser->new;
    $parser->parse( $_ );
}

ok( 1 );
