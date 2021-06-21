#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use Graph::Undirected;
use Test::More;

plan tests => 1;

my $graph = Graph::Undirected->new;
$graph->add_vertex( { symbol => 'C', number => 1 } );
$graph->add_vertex( { symbol => 'O', number => 2 } );
is( write_SMILES( [ $graph ] ), 'C' );
