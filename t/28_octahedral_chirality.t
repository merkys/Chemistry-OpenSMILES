#!/usr/bin/perl

use strict;
use warnings;

use Algorithm::Combinatorics qw( permutations );
use Chemistry::OpenSMILES::Writer;
use List::Util qw( uniq );
use Test::More;

plan tests => 1;

my @order_permutations = permutations( [ 0..5 ] );
my @chiralities = map { Chemistry::OpenSMILES::Writer::_octahedral_chirality( @$_, '@OH1' ) }
                      @order_permutations;

is scalar uniq( @chiralities ), 30;
