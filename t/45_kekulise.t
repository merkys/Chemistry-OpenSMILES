#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Aromaticity qw( aromatise kekulise );
use Chemistry::OpenSMILES::Writer qw( write_SMILES );
use Test::More;

my %cases = (
    'c1ccccc1-c1ccccc1' => 'C1=CC=CC=C1C1=CC=CC=C1',
);

plan tests => scalar keys %cases;

for my $smiles (sort keys %cases) {
    my $parser = Chemistry::OpenSMILES::Parser->new;
    my( $moiety ) = $parser->parse( $smiles );

    kekulise( $moiety );
    my $result = write_SMILES( [ $moiety ] );
    is $result, $cases{$smiles}, $smiles;
}
