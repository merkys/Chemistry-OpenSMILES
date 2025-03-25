#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use Test::More;

my @cases = (
    [ 'C', '[CH4]', 'C' ],
    [ '[CH4]', '[CH4]', 'C' ],
    [ 'C([H])([H])([H])[H]', '[CH4]', 'C' ],
    [ '[C]([H])([H])([H])[H]', '[CH4]', 'C' ],

    [ 'C=C', '[CH2]=[CH2]', 'C=C' ],
    [ 'C=1=C=C=C=1', 'C=1=C=C=C=1', 'C=1=C=C=C=1' ],

    [ 'F[C@](Br)(Cl)[H]', 'F[C@](Br)(Cl)[H]', 'F[C@](Br)(Cl)[H]' ],
    [ 'F[C@H](Br)Cl', 'F[C@](Br)(Cl)[H]', 'F[C@](Br)(Cl)[H]' ], # This could be more compact

    [ 'Cl/C=C/Cl', 'Cl/[CH]=[CH]/Cl', 'Cl/C=C/Cl' ],
    [ 'Cl/C=C(/Cl)\[H]', 'Cl/[CH]=[CH]/Cl', 'Cl/C=C/Cl' ],
);

plan tests => 2 * scalar @cases;

for my $case (@cases) {
    my $parser = Chemistry::OpenSMILES::Parser->new;
    my @moieties = $parser->parse( $case->[0] );
    for (@moieties) {
        Chemistry::OpenSMILES::unsprout_hydrogens( $_ );
    }
    is write_SMILES( \@moieties ), $case->[1];
    is write_SMILES( \@moieties, { remove_implicit_hydrogens => 1 } ), $case->[2];
}
