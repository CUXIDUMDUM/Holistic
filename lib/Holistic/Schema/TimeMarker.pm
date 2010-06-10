package Holistic::Schema::TimeMarker;

use Moose;

use Carp;
use String::Random;

extends 'Holistic::Base::DBIx::Class';

with 'Holistic::Role::Verify';

__PACKAGE__->table('timemarkers');

__PACKAGE__->add_columns(
    'pk1',
    { data_type => 'integer', size => '16', is_auto_increment => 1 },
    'foreign_pk1',
    { data_type => 'integer', size => '16', is_foreign_key => 1 },
    'rel_source',
    { data_type => 'varchar', size => '255', is_foreign_key => 1 },
    'name',
    { data_type => 'varchar', size => '255', is_nullable => 0 },
    'dt_marker',
    { data_type => 'datetime', is_nullable => 0, },
);

__PACKAGE__->set_primary_key('pk1');

__PACKAGE__->belongs_to(
    'queue', 'Holistic::Schema::Queue',
    {
        'foreign.pk1'        => 'self.foreign_pk1',
        'foreign.rel_source' => 'self.rel_source'
    }
);

__PACKAGE__->belongs_to(
    'ticket', 'Holistic::Schema::Ticket',
    {
        'foreign.pk1'           => 'self.foreign_pk1',
        'foreign.rel_source' => 'self.rel_source'
    }
);

sub _build_verify_scope { 'timemarker' }
sub _build__verify_profile {
    my ( $self ) = @_;
    return {
        'profile' => {
            # XX This should be a valid, parsed time
            'dt_marker' => {
                'required' => 1,
                'type' => 'Str',
            },
            'name' => {
                'required'   => 1,
                'type'       => 'Str',
                'min_length' => 1
            },
        },
        'filters' => [ 'trim' ]
    };
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
