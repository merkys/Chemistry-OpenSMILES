package Chemistry::OpenSMILES::Writer;

use strict;
use warnings;

use Graph::Traversal::DFS;

# ABSTRACT: OpenSMILES format writer
# VERSION

sub write
{
    my( $graph ) = @_;

    my @symbols = ( '(' );
    my %vertex_symbols;
    my $nrings = 0;
    my %seen_rings;

    my $operations = {
        tree_edge     => sub { push @symbols, _tree_edge( @_ ) },
        non_tree_edge => sub { return if $seen_rings{join '|', sort @_[0..1]};
                               $nrings++;
                               ${$vertex_symbols{$_[0]}} .= $nrings;
                               ${$vertex_symbols{$_[1]}} .= $nrings;
                               $seen_rings{join '|', sort @_[0..1]} = 1; },

        pre  => sub { push @symbols, _pre_vertex( @_ );
                      $vertex_symbols{$_[0]} = \$symbols[-1] },
        post => sub { push @symbols, ')' },
    };

    my $traversal = Graph::Traversal::DFS->new( $graph, %$operations );
    $traversal->dfs;
    return join '', @symbols;
}

sub _tree_edge
{
    my( $u, $v, $self ) = @_;

    my $graph = $self->graph;
    return '(' unless $graph->has_edge_attribute( $u, $v, 'bond' );

    # CAVEAT: '/' and '\' bonds are problematic
    return '(' . $graph->get_edge_attribute( $u, $v, 'bond' );
}

sub _pre_vertex
{
    my( $vertex, $self ) = @_;

    return $vertex->{symbol};
}

1;
