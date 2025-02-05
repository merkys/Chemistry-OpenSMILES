#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES qw(is_single_bond);
use Chemistry::OpenSMILES::Aromaticity qw(kekulise);
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use Set::Object qw(set);
use Test::More;

eval 'use Graph::Nauty qw(orbits)';
plan skip_all => 'no Graph::Nauty' if $@;

plan tests => 1;

my $parser = Chemistry::OpenSMILES::Parser->new;
my( $moiety ) = $parser->parse( 'Cc1c(C)cccc1' );

my @orbits = map { set( @$_ ) } orbits( $moiety, \&write_SMILES );
my $color_sub = sub { for my $i (0..$#orbits) { return $i if $orbits[$i]->has( $_[0] ) } };
kekulise( $moiety, $color_sub );

ok is_single_bond( $moiety, grep { $_->{number} == 1 || $_->{number} == 2 } $moiety->vertices );
