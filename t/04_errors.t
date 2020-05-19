#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Test::More;

my %cases = (
    'C(CC' => 't/04_errors.t: syntax error: missing closing parenthesis.',
    'CC)C' => 't/04_errors.t: syntax error: unbalanced parentheses.',
    'CCC)' => 't/04_errors.t: syntax error: unbalanced parentheses.',
    'C#=O' => 't/04_errors.t: syntax error at position 3: \'O\'.',
);

plan tests => scalar keys %cases;

for (sort keys %cases) {
    my $error;
    eval {
        my $parser = Chemistry::OpenSMILES::Parser->new;
        my @graphs = $parser->parse( $_ );
    };
    $error = $@ if $@;
    $error =~ s/\n$// if $error;
    is( $error, $cases{$_} );
}
