package OpenResty::Cache;

use strict;
use warnings;
use FindBin;

# This is a hack...

our $NoTrivial = 0;

sub new {
    my $class = ref $_[0] ? ref shift : shift;
    my $params = shift;
    my $type = $OpenResty::Config{'cache.type'} or
        die "No cache.type specified in the config files.\n";
    my $obj;
    my $self = bless {}, $class;
    if ($type eq 'filecache') {
        require Cache::FileCache;
        $obj = Cache::FileCache->new(
            { namespace => 'OpenResty', default_expires_in => 60 * 60 * 24 }
        );
    } elsif ($type eq 'memcached') {
        my $list = $OpenResty::Config{'cache.servers'} or
            die "No cache.servers specified in the config files.\n";
        require Cache::Memcached::Fast;
        my @addr = split /\s*,\s*|\s+/, $list;
        if (!@addr) {
            die "No memcached server found: $list.\n";
        }
        $obj = Cache::Memcached::Fast->new({
            servers => [@addr],
        });
        #$obj->set(dog => 32);
        #die "Dog value: ", $obj->get('dog');
        #die $obj;
    } else {
        die "Invalid cache.type value: $type\n";
    }
    my $backend_type = $OpenResty::Config{'backend.type'} || '';
    $NoTrivial = $OpenResty::Config{'backend.recording'} ||
        $backend_type eq 'PgMocked';

    if ($obj->can('purge')) {
        $obj->purge();
    }
    $self->{obj} = $obj;
    return $self;
}

# expire_in is in seconds...
sub set {
    my ($self, $key, $val, $expire_in, $trivial) = @_;
    return undef if $trivial && $NoTrivial;
    $self->{obj}->set($key, $val, $expire_in);
}

sub get {
    $_[0]->{obj}->get($_[1]);
}

sub remove {
    my $self = shift;
    my $obj = $self->{obj};
    if ($obj->can('remove')) {
        $obj->remove(@_);
    } else {
        $obj->delete(@_);
    }
}

## ------------------------

sub get_has_user {
    my ($self, $user) = @_;
    $self->get("hasuser:$user")
}

sub set_has_user {
    my ($self, $user) = @_;
    $self->set("hasuser:$user", 1, 3600, 'trivial');
}

sub remove_has_user {
    my ($self, $user) = @_;
    $self->remove("hasuser:$user");
}

sub get_last_res {
    my ($self, $id) = @_;
    $self->get("lastres:$id");
}

sub set_last_res {
    my ($self, $id, $val) = @_;
    $self->set("lastres:$id", $val, 5 * 60);
}

sub remove_last_res {
    my ($self, $id) = @_;
    $self->remove("lastres:".$id);
}

sub get_has_model {
    my ($self, $user, $model) = @_;
    $self->get("hasmodel:$user:$model")
}

sub set_has_model {
    my ($self, $user, $model) = @_;
    $self->set("hasmodel:$user:$model", 1, 3600, 'trivial');
}

sub remove_has_model {
    my ($self, $user, $model) = @_;
    $self->remove("hasmodel:$user:$model");
}

sub get_has_view {
    my ($self, $user, $view) = @_;
    #return undef;
    $self->get("hasview:$user:$view")
}

sub set_has_view {
    my ($self, $user, $view) = @_;
    $self->set("hasview:$user:$view", 1, 3600, 'trivial');
}

sub remove_has_view {
    my ($self, $user, $view) = @_;
    $self->remove("hasview:$user:$view");
}

sub get_has_role {
    my ($self, $user, $role) = @_;
    #return undef;
    $self->get("hasrole:$user:$role")
}

sub set_has_role {
    my ($self, $user, $role, $login_meth) = @_;
    $self->set("hasrole:$user:$role", $login_meth, 3600, 'trivial');
}

sub remove_has_role {
    my ($self, $user, $role) = @_;
    $self->remove("hasrole:$user:$role");
}

1;

