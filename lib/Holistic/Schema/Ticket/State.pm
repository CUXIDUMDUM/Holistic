package Holistic::Schema::Ticket::State;

use Moose;

use Carp;
use String::Random;

extends 'Holistic::Base::DBIx::Class';

__PACKAGE__->table('ticket_states');
#$CLASS->resultset_class('Holistic::ResultSet::Ticket');

__PACKAGE__->add_columns(
    'pk1',
    { data_type => 'integer', size => '16', is_auto_increment => 1 },
    'ticket_pk1',
    { data_type => 'integer', size => '16', is_foreign_key => 1 },
    'identity_pk1',
    { data_type => 'integer', size => '16', is_foreign_key => 1 },
    'identity_pk2',
    { data_type => 'integer', size => '16', is_nullable => 1, is_foreign_key => 1 },
    'status_pk1',
    { data_type => 'integer', size => '16', is_foreign_key => 1 },
    'success',
    { data_type => 'integer', size => '1', default_value => 1 },
    'priority_pk1',
    { data_type => 'integer', size => '16', is_foreign_key => 1 },
    'dt_created',
    { data_type => 'datetime', is_nullable => 0, set_on_create => 1 }
);

__PACKAGE__->set_primary_key('pk1');

__PACKAGE__->belongs_to('ticket', 'Holistic::Schema::Ticket', 'ticket_pk1');
__PACKAGE__->belongs_to('status', 'Holistic::Schema::Ticket::Status', 'status_pk1');
__PACKAGE__->belongs_to( 'priority', 'Holistic::Schema::Ticket::Priority', 'priority_pk1');

__PACKAGE__->add_relationship(
    'identity',
    'Holistic::Schema::Person::Identity',
    { 'foreign.pk1' => 'self.identity_pk1' },
    {
        join_type => 'left',
        accessor  => 'single'
    }
);

__PACKAGE__->add_relationship(
    'destination_identity',
    'Holistic::Schema::Person::Identity',
    { 'foreign.pk1' => 'self.identity_pk2' },
    {
        join_type => 'left',
        accessor  => 'single'
    }
);

sub actor_object {
    my ( $self ) = @_;

    $self->result_source->schema
        ->resultset( $self->actor->result_source )
        ->find( $self->actor_pk1 );
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
