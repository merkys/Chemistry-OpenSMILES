#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Writer;
use Test::More;

# Taken from OpenSMILES v1.0 specification, Section 3.8.5
my @cases = (
    [ qw( 1 2 3 4 @SP1 ) ],
    [ qw( 4 3 2 1 @SP1 ) ],
    [ qw( 1 4 3 2 @SP1 ) ],
    [ qw( 2 3 4 1 @SP1 ) ],
    [ qw( 2 1 4 3 @SP1 ) ],
    [ qw( 3 4 1 2 @SP1 ) ],
    [ qw( 3 2 1 4 @SP1 ) ],
    [ qw( 4 1 2 3 @SP1 ) ],

    [ qw( 2 3 1 4 @SP2 ) ],
    [ qw( 4 1 3 2 @SP2 ) ],
    [ qw( 1 2 4 3 @SP2 ) ],
    [ qw( 3 4 2 1 @SP2 ) ],
    [ qw( 2 1 3 4 @SP2 ) ],
    [ qw( 4 3 1 2 @SP2 ) ],
    [ qw( 1 4 2 3 @SP2 ) ],
    [ qw( 3 2 4 1 @SP2 ) ],

    [ qw( 2 4 1 3 @SP3 ) ],
    [ qw( 3 1 4 2 @SP3 ) ],
    [ qw( 3 1 2 4 @SP3 ) ],
    [ qw( 4 2 1 3 @SP3 ) ],
    [ qw( 1 3 2 4 @SP3 ) ],
    [ qw( 4 2 3 1 @SP3 ) ],
    [ qw( 1 3 4 2 @SP3 ) ],
    [ qw( 2 4 3 1 @SP3 ) ],
);

plan tests => scalar @cases;

for my $case (@cases) {
    my @order = @$case;
    my $chirality = pop @order;

    is Chemistry::OpenSMILES::Writer::_square_planar_chirality( map { $_ - 1 } @order ),
       $chirality;
}
