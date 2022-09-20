#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Stereo qw(
    chirality_to_pseudograph
);
use Test::More;

plan tests => 2;

my $parser = Chemistry::OpenSMILES::Parser->new;
my $moiety;

( $moiety ) = $parser->parse( 'N[C@](Br)(O)C' );
chirality_to_pseudograph( $moiety );

is( $moiety->vertices, 23 );
is( $moiety->edges, 70 );
