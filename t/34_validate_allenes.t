#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES;
use Chemistry::OpenSMILES::Parser;
use Test::More;

my %cases = (
    'NC(Br)=[C@]=C(O)C' => undef,
    'CC(C)=[C@]=C(C)C'  => 'tetrahedral chiral allenal setting for C(3) is not needed as not all 4 neighbours are distinct',
);

plan tests => scalar keys %cases;

for (sort keys %cases) {
    my $warning;
    local $SIG{__WARN__} = sub { $warning = $_[0] };

    my $parser   = Chemistry::OpenSMILES::Parser->new;
    my( $graph ) = $parser->parse( $_ );
    Chemistry::OpenSMILES::_validate( $graph,
                                      sub { $_[0]->{symbol} } );
    $warning =~ s/\n$// if defined $warning;
    is $warning, $cases{$_};
}
