package Holistic::Schema::Product;

use Moose;

use Carp;

extends 'Holistic::Base::DBIx::Class';

with 'Holistic::Role::Permissions',
     'Holistic::Role::Verify';

__PACKAGE__->table('products');

__PACKAGE__->add_columns(
    'pk1',
    { data_type => 'integer', size => '16', is_auto_increment => 1 },
    'name',
    { data_type => 'varchar', size => '255', is_nullable => 0, },
    'description',
    { data_type => 'text', is_nullable => 1},
    'dt_created',
    { data_type => 'datetime', set_on_create => 1 },
    'dt_updated',
    { data_type => 'datetime', set_on_create => 1, set_on_update => 1 },
);

__PACKAGE__->set_primary_key('pk1');

__PACKAGE__->has_many('queue_links', 'Holistic::Schema::Product::Queue', 'product_pk1');
__PACKAGE__->many_to_many('queues' => 'queue_links' => 'queue');

sub _build_verify_scope { 'product' }
sub _build__verify_profile {
    my ( $self ) = @_;
    return {
        'profile' => {
            'name' => {
                'required' => 1,
                'type' => 'Str',
                'max_length' => '255',
                'min_length' => 1
            },
            'description' => {
                'required'   => 1,
                'type'       => 'Str',
                'min_length' => 1
            },
        },
        'filters' => [ 'trim' ]
    };
}

sub permission_hierarchy {
    return {
        'condescends' => [
            'permission_set',
            {
                'queue_links' => {
                    'queue' => [
                        'permission_set',
                        { 'group_links' => { 'group' => 'permission_set' } } 
                    ]
                } 
            }
        ]
    };
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
