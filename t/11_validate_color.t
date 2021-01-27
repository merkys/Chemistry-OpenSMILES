#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES;
use Chemistry::OpenSMILES::Parser;
use Test::More;

my %cases = (
    'C[C@](C)(C)(C)' => 'tetrahedral chiral setting for C(1) is not needed as not all 4 neighbours are distinct',
    'C[C@](Cl)(F)(O)' => undef,
    'C(Cl)(F)(O)' => 'atom C(0) has 4 distinct neighbours, but does not have a chiral setting',
);

plan tests => scalar keys %cases;

for (sort keys %cases) {
    my $warning;
    local $SIG{__WARN__} = sub { $warning = $_[0] };

    my $parser   = Chemistry::OpenSMILES::Parser->new;
    my( $graph ) = $parser->parse( $_ );
    Chemistry::OpenSMILES::_validate( $graph,
                                      sub { return $_[0]->{symbol} } );
    $warning =~ s/\n$// if defined $warning;
    is( $warning, $cases{$_} );
}
