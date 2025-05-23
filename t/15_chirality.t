#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES qw(is_chiral mirror);
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use Test::More;

my @cases = (
    [ 'N[C@](Br)(O)C',    1, 1, 'N[C@@](Br)(O)C' ],
    [ 'N[C@@](Br)(O)C',   1, 1, 'N[C@](Br)(O)C'  ],
    [ 'N(C)(Br)(O)C',     0, 0, 'N(C)(Br)(O)C'   ],
    [ 'N(C)(Br)(O)C',     0, 0, 'N(C)(Br)(O)C'   ],
    # Square brackets are retained as in raw mode the writer does not attempt to calculate the valence:
    [ 'N[C@AL1](Br)(O)C', 1, 0, 'N[C](Br)(O)C'   ],
);

plan tests => 3 * scalar @cases;

my $parser = Chemistry::OpenSMILES::Parser->new;

for my $case (@cases) {
    my $moiety;
    my $result;

    ( $moiety ) = $parser->parse( $case->[0], { raw => 1 } );

    is is_chiral( $moiety ) + 0, $case->[1];
    is Chemistry::OpenSMILES::is_chiral_tetrahedral( $moiety ) + 0, $case->[2];

    mirror( $moiety );
    is write_SMILES( $moiety, { raw => 1 } ), $case->[3];
}
