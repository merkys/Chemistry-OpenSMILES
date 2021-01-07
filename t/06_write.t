#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer;
use Test::More;

my @cases = (
    [ 'C', 'C' ],
    [ 'C=C', 'C(=C)' ],
    [ 'C=1=C=C=C=1', 'C=1(=C(=C(=C=1)))' ],
);

plan tests => 2 * scalar @cases;

for my $case (@cases) {
    my $parser;
    my @moieties;
    my $result;

    $parser = Chemistry::OpenSMILES::Parser->new;
    @moieties = $parser->parse( $case->[0], { raw => 1 } );
    $result = Chemistry::OpenSMILES::Writer::write( \@moieties );
    is( $result, $case->[1] );

    $parser = Chemistry::OpenSMILES::Parser->new;
    @moieties = $parser->parse( $result, { raw => 1 } );
    $result = Chemistry::OpenSMILES::Writer::write( \@moieties );
    is( $result, $case->[1] );
    
}
