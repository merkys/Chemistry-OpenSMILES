#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use Test::More;

my @cases = (
    [ 'C', '[CH4]' ],
    [ '[CH4]', '[CH4]' ],
    [ 'C([H])([H])([H])[H]', '[CH4]' ],
    [ '[C]([H])([H])([H])[H]', '[CH4]' ],

    [ 'C=C', '[CH2]=[CH2]' ],
    [ 'C=1=C=C=C=1', 'C=1=C=C=C=1' ],

    [ 'F[C@](Br)(Cl)[H]', 'F[C@](Br)(Cl)[H]' ],

    [ 'Cl/C=C/Cl', 'Cl/[CH]=[CH]/Cl' ],
    [ 'Cl/C=C(/Cl)\[H]', 'Cl/[CH]=C(/Cl)\[H]' ],
);

plan tests => scalar @cases;

for my $case (@cases) {
    my $parser = Chemistry::OpenSMILES::Parser->new;
    my @moieties = $parser->parse( $case->[0] );
    for (@moieties) {
        Chemistry::OpenSMILES::unsprout_hydrogens( $_ );
    }
    my $result = write_SMILES( \@moieties );
    is $result, $case->[1];
}
