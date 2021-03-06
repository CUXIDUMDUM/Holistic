package Holistic::Schema::Group;

use Moose;

use Carp;
use String::Random;

extends 'Holistic::Base::DBIx::Class';

with 'Holistic::Role::Verify';

my $CLASS = __PACKAGE__;

$CLASS->table('groups');
#$CLASS->resultset_class('Holistic::ResultSet::Person');

$CLASS->add_columns(
    'pk1',
    { data_type => 'integer', size => '16', is_auto_increment => 1 },
    'permission_set_pk1',
    { data_type => 'integer', size => '16', is_foreign_key => 1,
        dynamic_default_on_create => sub {
            shift->schema->resultset('Permission::Set')->create({})->id
        }
    },
    'token',
    { data_type => 'varchar', size => '255', is_nullable => 0,
        dynamic_default_on_create => sub {
            my ( $self ) = @_; $self->schema->tokenize( $self->name ) 
        }
    },
    'name',
    { data_type => 'varchar', size => '255', is_nullable => 0,
        token_field => 'token' },
    'email',
    { data_type => 'varchar', size => '255', is_nullable => 1 },
    dt_created => {
        data_type   => 'DATETIME',
        is_nullable => 0,
        size        => undef,
        set_on_create => 1
    },
    dt_updated => {
        data_type   => 'DATETIME',
        is_nullable => 0,
        size        => undef,
        set_on_create => 1, set_on_update => 1
    }

);
$CLASS->set_primary_key('pk1');

__PACKAGE__->has_many('person_links', 'Holistic::Schema::Person::Group', 'group_pk1');

__PACKAGE__->many_to_many('persons' => 'person_links' => 'person' );

__PACKAGE__->has_many('queue_links', 'Holistic::Schema::Queue::Group', 'group_pk1');
__PACKAGE__->many_to_many('queues', => 'queue_links' => 'queue' );

__PACKAGE__->belongs_to('permission_set' => 'Holistic::Schema::Permission::Set', 'permission_set_pk1' );

sub permissions {
    shift->permission_set->permissions;
}

sub inflate_permissions {
    my ( $self ) = @_;

    my $rs = $self->permissions;
    return { map { $_->name => $_->id } $rs->all };
}

sub is_member {
    my ( $self, $person, $role ) = @_;
    my $rs = $self->membership( $person, $role );
    return ( $rs->count > 0 );
}

sub membership {
    my ( $self, $person, $role ) = @_;

    my $rs = $self->person_links({ }, { prefetch => [ 'role', 'person' ] });
    if ( $role ) {
        my $role_obj;
        use Scalar::Util 'blessed';
        if ( not blessed($role) ) {
            if ( $role =~ /^\d+$/ ) {
                $role_obj = $self->resultset('Role')->find( $role );
            } else {
                $role_obj = $self->resultset('Role')->search({ name => $role })->first;
            }
        } else {
            $role_obj = $role;
        }
        confess "Invalid role supplied: $role is unknown to the system"
            unless defined $role_obj;
        $rs = $rs->search({ 'role.pk1' => $role_obj->id });
    }
    $rs;
}

sub permission_hierarchy {
    return {
        'ascends' => {
            'queue_links' => { 'queue' => { 'product_links' => 'product' } } 
        }
    };
}

use Digest::MD5;
use URI::Escape qw(uri_escape);

sub gravatar_url {
    my ( $self, $size ) = @_;
    my $email = $self->email;
    my $default = uri_escape('http://static.coldhardcode.com/images/gravatar.jpg');
    $size = int($size || 40);
    $size = 40 if $size < 1;

    return
        'http://www.gravatar.com/avatar.php?' .
        '&gravatar_id=' . Digest::MD5::md5_hex(lc($email)) .
        #"&default=$default" .
        "&size=$size";
}

sub _build_verify_scope { 'group' }
sub _build__verify_profile {
    my ( $self ) = @_;
    my $rs = $self->schema->resultset('Person::Identity');
    return {
        'profile' => {
            'name' => {
                'required' => 1,
                'type' => 'Str',
                'max_length' => '255',
                'min_length' => 1
            },
        },
        'filters' => [ 'trim' ]
    };
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
