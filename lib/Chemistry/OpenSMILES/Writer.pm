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
    $traversal->dfs;
}

sub _tree_edge
{
    my( $u, $v, $graph ) = @_;

    # print $u->{symbol} . ' -> ' . $v->{symbol} . " (tree node)\n";
}

sub _non_tree_edge
{
    my( $u, $v, $graph ) = @_;

    # print $u->{symbol} . ' -> ' . $v->{symbol} . " (non tree node)\n";
}

sub _pre_vertex
{
    my( $vertex, $graph ) = @_;

    print '(' . $vertex->{symbol};
}

sub _post_vertex
{
    my( $vertex, $graph ) = @_;

    print ')';
}

1;
