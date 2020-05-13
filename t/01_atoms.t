#!/usr/bin/perl

use strict;
use warnings;
use OpenSMILES::Parser;
use Test::More;

my @cases = qw(
    C       N      Cl
    [U]     [Pb]   [He]   [*]
    [CH4]   [ClH]  [ClH1]
    [Cl-]   [OH1-] [OH-1] [Cu+2] [Cu++]
    [13CH4] [2H+]  [238U]
);

plan tests => 2 * scalar @cases;

for (@cases) {
    my $parser = OpenSMILES::Parser->new;
    my $graph = $parser->parse( $_ );
    is( $graph->vertices, 1 );
    $_ = "[$_]" unless /^\[/;
    is( join( '', map { OpenSMILES::Parser::_sprint_atom( $_ ) }
                      $graph->vertices ),
        $_ );
}
