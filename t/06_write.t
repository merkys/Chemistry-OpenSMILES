#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer;
use Test::More;

my @cases = (
    [ 'C=1=C=C=C=1', '(C=1(=C(=C(=C=1))))' ],
);

plan tests => scalar @cases;

for my $case (@cases) {
    my $parser = Chemistry::OpenSMILES::Parser->new;
    my @moieties = $parser->parse( $case->[0], { raw => 1 } );

    my $result = Chemistry::OpenSMILES::Writer::write( \@moieties );
    is( $result, $case->[1] );
}
