#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use Test::More;

my @cases = (
    [ '[C]1[C]/C=N/[C][C][C][C][C]1', '[C]1[C]/C=N/[C][C][C][C][C]1' ],
    [ '[C:6]1[C:7]/C=N/[C:1][C:2][C:3][C:4][C:5]1', '[C:1]\1[C:2][C:3][C:4][C:5][C:6][C:7]/C=N/1' ],

    # This test case highlights the difference between Daylight SMILES and OpenSMILES.
    # In the former, if tetrahedral chiral atom with implicit H starts the SMILES, H atom is treated as the 'from' atom.
    # In OpenSMILES, it is always the second atom.
    [ '[C@H](Br)(Cl)[F:1]', '[F:1][C@H](Br)Cl',  { flavor => 'opensmiles' } ],
    [ '[C@H](Br)(Cl)[F:1]', '[F:1][C@@H](Br)Cl', { flavor => 'daylight' } ],
);

plan tests => scalar @cases;

my $parser = Chemistry::OpenSMILES::Parser->new;

for my $case (@cases) {
    my( $input, $output, $options ) = @$case;
    my @moieties = $parser->parse( $input, $options );

    my $result = write_SMILES( \@moieties, { order_sub => \&class_order,
                                             remove_implicit_hydrogens => 1,
                                             unsprout_hydrogens => 1 } );
    is $result, $output;
}

sub class_order
{
    my $vertices = shift;
    my @classed   = grep {  $vertices->{$_}{class} } keys %$vertices;
    my @classless = grep { !$vertices->{$_}{class} } keys %$vertices;
    my @sorted = ( (sort {  $vertices->{$a}{class}  <=> $vertices->{$b}{class}  } @classed),
                   (sort {  $vertices->{$a}{number} <=> $vertices->{$b}{number} } @classless) );
    return $vertices->{shift @sorted};
}
