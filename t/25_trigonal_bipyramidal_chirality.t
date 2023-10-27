#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw( write_SMILES );
use List::Util qw( first );
use Test::More;

my @cases = (
    [ 'S[As@TB1](F)(Cl)(Br)N',  [ qw( S As Br Cl F N ) ], 'S([As@TB2](Br)(Cl)(F)(N(([H][H]))))([H])' ],
    [ 'S[As@TB5](F)(N)(Cl)Br',  [ qw( F As S Cl N Br ) ], 'F([As@TB10](S([H]))(Cl)(N(([H][H])))(Br))' ],
    [ 'F[As@TB15](Cl)(S)(Br)N', [ qw( Br As Cl S F N ) ], 'Br([As@TB20](Cl)(S([H]))(F)(N(([H][H]))))' ],
);

plan tests => scalar @cases;

for my $case (@cases) {
    my $parser;
    my @moieties;
    my $result;

    my $order_sub = sub {
        my( $vertices ) = @_;
        for my $symbol (@{$case->[1]}) {
            my $vertex = first { $_->{symbol} eq $symbol } values %$vertices;
            return $vertex if $vertex;
        }
        return values %$vertices;
    };

    $parser = Chemistry::OpenSMILES::Parser->new;
    @moieties = $parser->parse( $case->[0] );

    $result = write_SMILES( \@moieties, $order_sub );
    is( $result, $case->[2] );
}
