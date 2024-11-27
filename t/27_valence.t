#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES qw( valence );
use Chemistry::OpenSMILES::Parser;
use Test::More;

my @cases = (
    [ 'C', '4,1,1,1,1' ],
    [ '[C]', '0' ],
    [ 'CCC', '4,4,4,1,1,1,1,1,1,1,1' ],
);

plan tests => scalar @cases;

for my $case (@cases) {
    my $result;

    my $parser = Chemistry::OpenSMILES::Parser->new;
    my( $moiety ) = $parser->parse( $case->[0] );

    is join( ',', reverse sort map { valence( $moiety, $_ ) } $moiety->vertices ),
       $case->[1];
}
