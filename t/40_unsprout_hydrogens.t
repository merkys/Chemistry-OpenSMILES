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

    [ 'F[C@](Br)(Cl)[H]', 'F[C@H](Br)Cl', 'F[C@H](Br)Cl' ],
    [ 'F[C@](Br)([H])Cl', 'F[C@@H](Br)Cl', 'F[C@@H](Br)Cl' ],
    [ 'F[C@H](Br)Cl', 'F[C@H](Br)Cl', 'F[C@H](Br)Cl' ],

    [ 'Cl/C=C/Cl', 'Cl/[CH]=[CH]/Cl', 'Cl/C=C/Cl' ],
    [ 'Cl/C=C(/Cl)\[H]', 'Cl/[CH]=[CH]/Cl', 'Cl/C=C/Cl' ],

    [ '[H]C([H])([H])[H]', '[CH4]', 'C' ],
    [ '[H][C@](F)(Br)Cl', '[C@H](F)(Br)Cl', '[C@H](F)(Br)Cl' ],

    [ '[H][H]', '[H][H]', '[H][H]' ],
    [ '[O][H][O]', '[O][H][O]', '[O][H][O]' ],
    [ '[H]1CCCC1', '[H]1[CH2][CH2][CH2][CH2]1', '[H]1CCCC1' ],
);

plan tests => 4 * scalar @cases;

for my $case (@cases) {
    my $parser = Chemistry::OpenSMILES::Parser->new;
    my @moieties = $parser->parse( $case->[0] );

    is write_SMILES( \@moieties, { unsprout_hydrogens => 1 } ), $case->[1];
    is write_SMILES( \@moieties, { remove_implicit_hydrogens => 1,
                                   unsprout_hydrogens => 1 } ), $case->[2];

    for (@moieties) {
        Chemistry::OpenSMILES::_unsprout_hydrogens( $_ );
    }
    is write_SMILES( \@moieties ), $case->[1];
    is write_SMILES( \@moieties, { remove_implicit_hydrogens => 1 } ), $case->[2];
}
