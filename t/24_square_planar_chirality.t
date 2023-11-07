#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Stereo qw( chirality_to_pseudograph );
use Chemistry::OpenSMILES::Writer qw( write_SMILES );
use Test::More;

eval 'use Graph::Nauty qw( are_isomorphic )';
my $has_Graph_Nauty = !$@;

my @cases = (
    [ 'N[C@SP1](Br)(O)C', 'N([C@SP1](Br)(O)(C))', 'C([C@SP1](O)(Br)(N))' ],
    [ 'N[C@SP2](Br)(O)C', 'N([C@SP2](Br)(O)(C))', 'C([C@SP2](O)(Br)(N))' ],
    [ 'N[C@SP3](Br)(O)C', 'N([C@SP3](Br)(O)(C))', 'C([C@SP3](O)(Br)(N))' ],
);

plan tests => 2 * scalar @cases + $has_Graph_Nauty * 2 * scalar @cases;

for my $case (@cases) {
    my $parser;
    my @moieties;
    my $result;

    $parser = Chemistry::OpenSMILES::Parser->new;
    @moieties = $parser->parse( $case->[0], { raw => 1 } );

    $result = write_SMILES( \@moieties );
    is( $result, $case->[1] );

    $result = write_SMILES( \@moieties, \&reverse_order );
    is( $result, $case->[2] );

    next unless $has_Graph_Nauty;

    my @graphs = map { $parser->parse( $_ ) } @$case;
    for (@graphs) {
        chirality_to_pseudograph( $_ );
    }
    ok are_isomorphic( $graphs[0], $graphs[1] );
    ok are_isomorphic( $graphs[1], $graphs[2] );
}

sub reverse_order
{
    my( $vertices ) = @_;
    my @sorted = sort { $vertices->{$b}{number} <=>
                        $vertices->{$a}{number} } keys %$vertices;
    return $vertices->{shift @sorted};
}
