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

    'C1CCCCC1'          => [  6,  6 ],
    'N1CC2CCCCC2CC1'    => [ 10, 11 ],
    'C=1CCCCC=1'        => [  6,  6 ],
    'C1CCCCC1C1CCCCC1'  => [ 12, 13 ],
    'C1CCCCC1C2CCCCC2'  => [ 12, 13 ],
    'C0CCCCC0'          => [  6,  6 ],
    'C%25CCCCC%25'      => [  6,  6 ],
    'C1CCCCC%01'        => [  6,  6 ],
    'C12(CCCCC1)CCCCC2' => [ 11, 12 ],

    '[Na+].[Cl-]'             => [  2,  0 ],
    'c1cc(O.NCCO)ccc1'        => [ 11, 10 ],
    'Oc1cc(.NCCO)ccc1'        => [ 11, 10 ],
    'C1.C1'                   => [  2,  1 ],
    'C1.C12.C2'               => [  3,  2 ],
    'c1c2c3c4cc1.Br2.Cl3.Cl4' => [  9,  9 ],
);

plan tests => 2 * scalar keys %cases;

for my $case (sort keys %cases) {
    my $parser = OpenSMILES::Parser->new;
    my $graph = $parser->parse( $case );
    is( $graph->vertices, $cases{$case}->[0] );
    is( $graph->edges,    $cases{$case}->[1] );
}
