#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use Test::More;

my @cases = (
    [ 'C(=C/[C]O)\[C]O', 'C(=C(/[C](O([H])))([H]))(\[C](O([H])))([H])', '[H](O([C](/C([H])(=C([H])(/[C](O([H])))))))', 'O([C](\C(=C(\[C](O([H])))([H]))([H])))([H])' ],
);

plan tests => 3 * scalar @cases;

for my $case (@cases) {
    my $parser;
    my @moieties;
    my $result;

    $parser = Chemistry::OpenSMILES::Parser->new;
    @moieties = $parser->parse( $case->[0] );

    $result = write_SMILES( \@moieties );
    is $result, $case->[1];

    $result = write_SMILES( \@moieties, { order_sub => \&reverse_order } );
    is $result, $case->[2];

    $result = write_SMILES( \@moieties, { order_sub => \&particular_order } );
    is $result, $case->[3];
}

sub reverse_order
{
    my( $vertices ) = @_;
    my @sorted = sort { $vertices->{$b}{number} <=>
                        $vertices->{$a}{number} } keys %$vertices;
    return $vertices->{shift @sorted};
}

sub particular_order
{
    my( $vertices ) = @_;
    my %order = (
        0 => 3,
        1 => 2,
        2 => 1,
        3 => 0,
        4 => 4,
        5 => 5,
        6 => 6,
        7 => 7,
        8 => 8,
        9 => 9,
    );
    my @sorted = sort { $order{$vertices->{$a}{number}} <=>
                        $order{$vertices->{$b}{number}} } keys %$vertices;
    return $vertices->{shift @sorted};
}
