#!/usr/bin/perl

use strict;
use warnings;
use List::Util qw(sum);
use Chemistry::OpenSMILES::Parser;
use Test::More;

my %cases = (
    'c1ccccc1C&1&1&1' => [ 7, 9 ], # polystyrene
    'C&1&1&1&1&1'     => [ 1, 4 ], # diamond
    'c&1&1&1&1'       => [ 1, 3 ], # graphite
);

plan tests => 3 * scalar keys %cases;

for my $case (sort keys %cases) {
    my $parser = Chemistry::OpenSMILES::Parser->new;
    my @graphs = $parser->parse( $case, { polymer => 1, raw => 1 } );

    is( scalar @graphs, 1 );

    is( scalar $graphs[0]->vertices, $cases{$case}->[0] );
    is( scalar $graphs[0]->edges,    $cases{$case}->[1] );
}
