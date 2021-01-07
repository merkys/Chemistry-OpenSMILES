package Chemistry::OpenSMILES::Writer;

use strict;
use warnings;

use Graph::Traversal::DFS;

# ABSTRACT: OpenSMILES format writer
# VERSION

sub write
{
    my( $graph ) = @_;

    my $operations = {
        tree_edge     => \&_tree_edge,
        non_tree_edge => \&_non_tree_edge,

        pre  => \&_pre_vertex,
        post => \&_post_vertex,
    };

    my $traversal = Graph::Traversal::DFS->new( $graph, %$operations );
    print '(';
    $traversal->dfs;
}

sub _tree_edge
{
    my( $u, $v, $self ) = @_;

    print '(';

    my $graph = $self->graph;
    return unless $graph->has_edge_attribute( $u, $v, 'bond' );

    # CAVEAT: '/' and '\' bonds are problematic
    print $graph->get_edge_attribute( $u, $v, 'bond' );
}

sub _non_tree_edge
{
    my( $u, $v, $self ) = @_;

    # TODO: handle rings
}

sub _pre_vertex
{
    my( $vertex, $self ) = @_;

    print $vertex->{symbol};
}

sub _post_vertex
{
    my( $vertex, $self ) = @_;

    print ')';
}

1;
