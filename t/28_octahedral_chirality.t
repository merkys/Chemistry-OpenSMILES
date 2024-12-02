#!/usr/bin/perl

use strict;
use warnings;

use Algorithm::Combinatorics qw( permutations );
use Chemistry::OpenSMILES::Writer;
use Test::More;

my @order_permutations = permutations( [ 0..5 ] );

plan tests => @order_permutations * 30;

for my $permutation (@order_permutations) {
    for (1..30) {
        my $chirality = Chemistry::OpenSMILES::Writer::_octahedral_chirality( @$permutation, '@OH' . $_ );
        my @reverse_permutation = reverse_permutation( @$permutation );
        is Chemistry::OpenSMILES::Writer::_octahedral_chirality( @reverse_permutation, $chirality ),
           '@OH' . $_;
    }
}

sub reverse_permutation
{
    my @order = @_;
    return sort { $order[$a] <=> $order[$b] } 0..$#order;
}
