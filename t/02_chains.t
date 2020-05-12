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

    'C=C'   => 2,
    'C#N'   => 2,
    'CC#CC' => 4,
    'CCC=O' => 4,
    '[Rh-](Cl)(Cl)(Cl)(Cl)$[Rh-](Cl)(Cl)(Cl)Cl' => 10,
);

plan tests => scalar keys %cases;

for my $case (sort keys %cases) {
    my $parser = OpenSMILES::Parser->new;
    my $graph = $parser->parse( $case );
    is( $graph->vertices, $cases{$case} );
}
