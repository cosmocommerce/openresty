package OpenResty::Backend::Base;

use strict;
use warnings;

#use Smart::Comments;
use Params::Util qw(_ARRAY0 _ARRAY);
use List::MoreUtils qw(firstidx);
use OpenResty::SQL::Insert;

my %DefaultRules = (
    Admin => [
        [ DELETE => 'model' ],
        [ DELETE => 'model/~' ],
        [ DELETE => 'model/~/~' ],
        [ DELETE => 'model/~/~/~' ],
        [ DELETE => 'model/~/~/~/~' ],

        [ GET => 'model' ],
        [ GET => 'model/~' ],
        [ GET => 'model/~/~' ],
        [ GET => 'model/~/~/~' ],
        [ GET => 'model/~/~/~/~' ],

        [ PUT => 'model' ],
        [ PUT => 'model/~' ],
        [ PUT => 'model/~/~' ],
        [ PUT => 'model/~/~/~' ],
        [ PUT => 'model/~/~/~/~' ],

        [ POST => 'model' ],
        [ POST => 'model/~' ],
        [ POST => 'model/~/~' ],
        [ POST => 'model/~/~/~' ],
        [ POST => 'model/~/~/~/~' ],

        [ DELETE => 'view' ],
        [ DELETE => 'view/~' ],
        [ DELETE => 'view/~/~' ],
        [ DELETE => 'view/~/~/~' ],
        [ DELETE => 'view/~/~/~/~' ],

        [ GET => 'view' ],
        [ GET => 'view/~' ],
        [ GET => 'view/~/~' ],
        [ GET => 'view/~/~/~' ],
        [ GET => 'view/~/~/~/~' ],

        [ PUT => 'view' ],
        [ PUT => 'view/~' ],
        [ PUT => 'view/~/~' ],
        [ PUT => 'view/~/~/~' ],
        [ PUT => 'view/~/~/~/~' ],

        [ POST => 'view' ],
        [ POST => 'view/~' ],
        [ POST => 'view/~/~' ],
        [ POST => 'view/~/~/~' ],
        [ POST => 'view/~/~/~/~' ],

        [ DELETE => 'role' ],
        [ DELETE => 'role/~' ],
        [ DELETE => 'role/~/~' ],
        [ DELETE => 'role/~/~/~' ],
        [ DELETE => 'role/~/~/~/~' ],

        [ GET => 'role' ],
        [ GET => 'role/~' ],
        [ GET => 'role/~/~' ],
        [ GET => 'role/~/~/~' ],
        [ GET => 'role/~/~/~/~' ],

        [ PUT => 'role' ],
        [ PUT => 'role/~' ],
        [ PUT => 'role/~/~' ],
        [ PUT => 'role/~/~/~' ],
        [ PUT => 'role/~/~/~/~' ],

        [ POST => 'role' ],
        [ POST => 'role/~' ],
        [ POST => 'role/~/~' ],
        [ POST => 'role/~/~/~' ],
        [ POST => 'role/~/~/~/~' ],

        [ DELETE => 'action' ],
        [ DELETE => 'action/~' ],
        [ DELETE => 'action/~/~' ],
        [ DELETE => 'action/~/~/~' ],
        [ DELETE => 'action/~/~/~/~' ],

        [ GET => 'action' ],
        [ GET => 'action/~' ],
        [ GET => 'action/~/~' ],
        [ GET => 'action/~/~/~' ],
        [ GET => 'action/~/~/~/~' ],

        [ PUT => 'action' ],
        [ PUT => 'action/~' ],
        [ PUT => 'action/~/~' ],
        [ PUT => 'action/~/~/~' ],
        [ PUT => 'action/~/~/~/~' ],

        [ POST => 'action' ],
        [ POST => 'action/~' ],
        [ POST => 'action/~/~' ],
        [ POST => 'action/~/~/~' ],
        [ POST => 'action/~/~/~/~' ],

        [ POST => 'admin/~' ],
    ],
);

our @VersionDelta = (
    [
        '0.01' => <<'_EOC_',
create table _version (
    version varchar(10)
);
insert into _version (version) values ('0.01');
alter table _access_rules rename to _access;
alter table _roles rename to _tmp;
create table _roles (
    id serial primary key,
    name text unique not null,
    password text,
    login text not null,
    description text not null
);
insert into _roles
    (name, password, login, description)
    (select name, password, login, description from _tmp);
drop table _tmp;
alter table _columns add column indexed text;
-- XXX TODO: alter table _columns rename column "default" to default_value;
create table _action (
    id serial primary key,
    name text unique not null,
    description text,
    definition text unique not null,
    confirmed_by text
);
_EOC_
    ],
    #[
    #'0.02' => <<'_EOC_',
#_EOC_
    #],
);

sub get_upgrading_base_for_user {
    my ($self, $user) = @_;
    my $data;
    if (defined $user) {
        $self->set_user($user);
    } else {
        die "No user specified.\n";
    }
    $user = $self->{user} or die "No user specified";
    $data = $self->select("select count(*) from pg_tables where tablename = '_version' and schemaname = '$user'");
    if (_ARRAY($data) && defined $data->[0][0] && $data->[0][0] == 0) {
        return 0;
    }
    $data = $self->select("select version from $user._version limit 1");
    my $version;
    if (_ARRAY0($data) && _ARRAY0($data->[0])) {
        $version = $data->[0][0];
        my $from = firstidx { $_ > $version } @VersionDelta;
        return $from;
    }
    return -1;
}

sub upgrade_metamodel_for_user {
    my ($self, $user, $from) = @_;
    if (defined $user) {
        $self->set_user($user);
    } else {
        die "No user specified.\n";
    }
    if (!defined $from) {
        $from = $self->getUpgradeBase;
        if (!defined $from) { return; }
    }
    my $cur_ver;
    if ($from == 0) {
        $cur_ver = 'nil';
    } else {
        $cur_ver = $VersionDelta[$from-1]->[0];
    }
    my $res;
    for my $i ($from..$#VersionDelta) {
        my $entry = $VersionDelta[$i];
        my ($new_ver, $sql) = @$entry;
        warn "Upgrading account $user from $cur_ver to $new_ver...\n";
        $res = $self->do("$sql; update _version set version='$new_ver';");
        last if $res < 0;
        $cur_ver = $new_ver;
    }
    return $res >= 0;
}

sub state {
    $_[0]->{dbh}->state;
}

sub disconnect {
    $_[0]->{dbh}->disconnect;
    $_[0]->{dbh} = undef;
}

sub add_default_roles {
    my ($self, $user, $admin_password) = @_;
    if (!defined $admin_password) {
        warn "No password specified.\n";
    }
    my $sql = <<"_EOC_";
insert into $user._roles (name, description, login, password)
values ('Admin', 'Administrator', 'password', '$admin_password');

insert into $user._roles (name, description, login)
values ('Public', 'Anonymous', 'anonymous');
_EOC_
    while (my ($role, $rules) = each %DefaultRules) {
        for my $rule (@$rules) {
            my $insert = OpenResty::SQL::Insert->new("$user._access_rules")
                ->cols(qw< role method url >)
                ->values("'$role'", "'$rule->[0]'", "'/=/$rule->[1]'");
            $sql .= $insert;
        }
    }
    $self->do($sql);
}

sub add_user {
    my ($self, $user, $admin_password) = @_;
    my $retval = $self->do(<<"_EOC_");
    create table $user._models (
        id serial primary key,
        name text unique not null,
        table_name text unique not null,
        description text
    );

    create table $user._columns (
        id serial primary key,
        name text  not null,
        type text not null,
        table_name text not null,
        "default" text,
        label text,
        unique(table_name, name)
    );

    create table $user._roles (
        name text primary key,
        parentRole integer default 0, -- a column reference to $user._roles itself. 0 means no parent
        password text,
        login text not null,
        description text not null
    );

    create table $user._access_rules (
        id serial primary key,
        role text not null,
        method varchar(10) not null,
        url text not null
    );

    create table $user._views (
        id serial primary key,
        name text unique not null,
        definition text unique not null,
        createdate timestamp with time zone default current_timestamp,
        updatedate timestamp with time zone default current_timestamp,
        description text
    );
_EOC_
    #$retval += 0;
    ### $admin_password
    $self->add_default_roles($user, $admin_password);
    $self->upgrade_metamodel_for_user($user, 0);
    #return $retval;
}

1;

