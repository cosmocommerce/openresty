package OpenAPI;

#use Smart::Comments;
use strict;
use warnings;
use vars qw($Dumper);

sub POST_action_exec {
    my ($self, $bits) = @_;
    my $action = $bits->[1];
    my $params = {
        $bits->[2] => $bits->[3]
    };
    my $lang = $params->{lang};
    if (!defined $lang) {
        die "The 'lang' param is required in the Select action.\n";
    }
    if (lc($lang) ne 'minisql') {
        die "Only the miniSQL language is supported for Select.\n";
    }
    my $sql = $self->{_req_data};
    ### Action sql: $sql

    _STRING($sql) or
        die "miniSQL must be an non-empty literal string: ", $Dumper->($sql), "\n";
   #warn "SQL 1: $sql\n";
    my $select = MiniSQL::Select->new;
    my $res = $select->parse(
        $sql,
        {
            quote => \&Q, quote_ident => \&QI,
            limit => $self->{_limit}, offset => $self->{_offset}
        }
    );
    if (_HASH($res)) {
        my $sql = $res->{sql};
        $sql = $self->append_limit_offset($sql, $res);
        my @models = @{ $res->{models} };
        my @cols = @{ $res->{columns} };
        $self->validate_model_names(\@models);
        $self->validate_col_names(\@models, \@cols);
       #warn "SQL 2: $sql\n";
        $self->select("$sql", {use_hash => 1, read_only => 1});
    }
}

sub append_limit_offset {
    my ($self, $sql, $res) = @_;
    #my $order_by $cgi->url
    my $limit = $res->{limit};
    if (defined $limit) {
        $sql =~ s/;\s*$/ limit $limit/s or
            $sql .= " limit $limit";
    }
    my $offset = $res->{offset};
    if (defined $offset) {
        $sql =~ s/;\s*$/ offset $offset;/s or
            $sql .= " offset $offset";
    }
    return "$sql;\n";
}

sub validate_model_names {
    my ($self, $models) = @_;
    for my $model (@$models) {
        _IDENT($model) or die "Bad model name: \"$model\"\n";
        if (!$self->has_model($model)) {
            die "Model \"$model\" not found.\n";
        }
    }
}

sub validate_col_names {
    my ($self, $models, $cols) = @_;
    # XXX TODO...
}

1;

