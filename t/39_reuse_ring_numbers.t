#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use Test::More;

my @cases = (
    # This is not a real structure, it is just easier to compare it
    [ 'O1OOOOC12OOOOO2', 'O1OOOOC11OOOOO1' ],
);

plan tests => 2 * scalar @cases;

for my $case (@cases) {
    my $parser = Chemistry::OpenSMILES::Parser->new;
    my @moieties = $parser->parse( $case->[0] );

    my $not_reused = write_SMILES( \@moieties, { immediately_reuse_ring_numbers => '' } );
    is $not_reused, $case->[0];

    my $reused = write_SMILES( \@moieties );
    is $reused, $case->[1];
}
