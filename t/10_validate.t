#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES;
use Chemistry::OpenSMILES::Parser;
use Test::More;

my %cases = (
    '[C@]' => 'chiral center C(0) has 0 bonds while at least 3 is required',
    'C/C(\O)=C(/C)(\O)' => 'atom C(1) has 2 bonds of type \'\\\', cis/trans definitions must not conflict',
    'C(Cl)(F)(O)' => 'atom C(0) has 4 distinct neighbours, but does not have a chiral setting',
    'C11' => 'atom C(0) has bond to itself',
    'C/C' => 'cis/trans bond is defined between atoms C(0) and C(1), but neither of them is attached to a double bond',

    'C/C=C' => 'double between atoms C(1) and C(2) has only one cis/trans marker',

    # OpenSMILES specification v1.0
    'NC(Br)=[C@]=C(O)C' => undef,

    # COD entry 1501863, r297409
    'B(C(=CC(C)(C)C)c1c(F)c(F)c(F)c(F)c1F)(c1c(F)c(F)c(F)c(F)c1F)/c1c(F)c(F)c(F)c(F)c1F' => 'cis/trans bond is defined between atoms B(0) and c(29), but neither of them is attached to a double bond',
);

plan tests => scalar keys %cases;

for (sort keys %cases) {
    my $warning;
    local $SIG{__WARN__} = sub { $warning = $_[0] };

    my $parser   = Chemistry::OpenSMILES::Parser->new;
    my( $graph ) = $parser->parse( $_ );
    Chemistry::OpenSMILES::_validate( $graph );
    $warning =~ s/\n$// if defined $warning;
    is $warning, $cases{$_};
}
