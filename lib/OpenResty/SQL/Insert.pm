package OpenResty::SQL::Insert;

use strict;
use warnings;
use base 'OpenResty::SQL::Statement';

use overload '""' => sub { $_[0]->generate };

sub new {
    my $class = ref $_[0] ? ref shift : shift;
    bless {
        table => $_[0],
        values => [],
        cols => [],
    }, $class;
}

sub insert {
    $_[0]->{table} = $_[1];
    $_[0]
}

sub cols {
    my $self = shift;
    push @{ $self->{cols} }, @_;
    $self;
}

sub values {
    my $self = shift;
    push @{ $self->{values} }, map { defined $_ ? $_ : 'NULL' } @_;
    $self;
}

sub generate {
    my $self = shift;
    my $sql;
    local $" = ', ';
    $sql .= "insert into $self->{table}";
    my $cols = $self->{cols};
    if ($cols and @$cols) {
        $sql .= " (@$cols)";
    }
    $sql .= " values (@{ $self->{values} })";
    return $sql . ";\n";
}

1;

