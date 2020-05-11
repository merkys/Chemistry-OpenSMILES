#!/usr/bin/perl

use strict;
use warnings;
use OpenSMILES::Parser;
use Test::More;

my %cases = (
    'CC'    => 2,
    'CCO'   => 3,
    'NCCCC' => 5,
    'CCCCN' => 5,
);

plan tests => scalar %cases;

my $parser;
for (sort keys %cases) {
    $parser = OpenSMILES::Parser->new;
    my $graph = $parser->parse( $_ );
    is( $graph->vertices, $cases{$_} );
}
