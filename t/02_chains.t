#!/usr/bin/perl

use strict;
use warnings;
use OpenSMILES::Parser;
use Test::More;

my %cases = (
    'CC'    => [ 2, 1 ],
    'CCO'   => [ 3, 2 ],
    'NCCCC' => [ 5, 4 ],
    'CCCCN' => [ 5, 4 ],

    'C=C'   => [ 2, 1 ],
    'C#N'   => [ 2, 1 ],
    'CC#CC' => [ 4, 3 ],
    'CCC=O' => [ 4, 3 ],
    '[Rh-](Cl)(Cl)(Cl)(Cl)$[Rh-](Cl)(Cl)(Cl)Cl' => [ 10, 9 ],

    'C-C' => [ 2, 1 ],

    'CCC(CC)CO'           => [  7,  6 ],
    'CC(C)C(=O)C(C)C'     => [  8,  7 ],
    'OCC(CCC)C(C(C)C)CCC' => [ 13, 12 ],
    'OS(=O)(=S)O'         => [  5,  4 ],
    'C(C(C(C(C(C(C(C(C(C(C(C(C(C(C(C(C(C(C(C(C))))))))))))))))))))C' => [ 22, 21 ],

    'C1CCCCC1'       => [  6,  6 ],
    'N1CC2CCCCC2CC1' => [ 10, 11 ],
);

plan tests => 2 * scalar keys %cases;

for my $case (sort keys %cases) {
    my $parser = OpenSMILES::Parser->new;
    my $graph = $parser->parse( $case );
    is( $graph->vertices, $cases{$case}->[0] );
    is( $graph->edges,    $cases{$case}->[1] );
}
