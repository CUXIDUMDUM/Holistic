package Holistic::Test::Person;

use Moose::Role;
use Test::More;
use MooseX::MethodAttributes::Role;
use Try::Tiny;

with 'Holistic::Test::Schema'; # We require schema

=head1 Permission Tests

=head2 CREATES

This test creates several groups, people, queues and tickets.

=head2 Permission Flow

Things that have permissions:

=over

=item Group->permissions

=item Queue->permissions

=item Ticket->permissions

=item Person->permissions

=back

Each permission can be negated.

=cut

sub shut_up_permissions : Plan(5) {
    my ( $self, $data ) = @_;

    # We create people and groups
    die "Need person/group tests to run"
        unless $self->meta->does_role('Holistic::Test::Person');
    die "Need queue tests to run"
        unless $self->meta->does_role('Holistic::Test::Queue');

    my $all_users   = create_group;
    my $admin_group = create_group;
    my $mgr_group   = create_group;
    my $devel_group = create_group;

    # Product specific

    # Anybody can create (even not logged in), this is by default:
    $product->permissions->allow('create', scope => [ 'Ticket' ]);

    # But lets remove write  permissions
    $product->permissions->prohibit('update');
    $product->permissions->prohibit('comment');

    $product->permissions->allow('update ticket', group => $all_users);

    ok( $product->check_permission( undef, 'create ticket' ), 'anon can create' );
    ok( $product->check_permission( undef, 'update ticket' ), 'anon cannot update' );

    # Check permissions, ->for returns a hash of permission names in that scope:
    # If there are descendent blocks at a lower level
    # (Product -> Queue -> Ticket) this check will *NOT* be accurate.  Always
    # Check at the lowest scope, not highest.
    # {
    #    'create ticket' => $permission_id,
    #    'update ticket' => $permission_id,
    # },
    is_deeply(
        $product->permissions->for( group => $admin_group ),
        $triage->permissions->for( group => $admin_group ),
        'no special rules on triage'
    );
    is_deeply(
        $product->permissions->for( user => $admin_group->persons->first ),
        $product->permissions->for( user => $devel_group->persons->first ),
        'same permissions regardless of users'
    );

    $triage->permissions->for( group => $devel_group );

    # Anybody but people in the devel group would be able to update this:
    $triage->permissions->prohibit('update ticket', group => $devel_group );
    # Still the same
    is_deeply(
        $product->permissions->for( user => $admin_group->persons->first ),
        $product->permissions->for( user => $devel_group->persons->first ),
        'same permissions regardless of users'
    );
    # Admin is the same on both levels
    is_deeply(
        $product->permissions->for( user => $admin_group->persons->first ),
        $triage->permissions->for( user => $admin_group->persons->first ),
        'same permissions descendents'
    );
    # Devel is not, but admin has this still:
    ok(
        exists $triage->permissions->for( group => $admin_group )->{'update ticket'},
        'descendents permissions on lower scope'
    );

    # Devel is not
    ok(
        not exists $triage->permissions->for( group => $devel_group )->{'update ticket'},
        'descendents permissions on lower scope'
    );


    $admin_group->permissions->for( queue => $triage );

    # Closed product, nobody can do anything.  Period.
    $product2->permissions->prohibit_all;
    ok( !$product2->check_permission( $user, 'create ticket' ), 'user cannot create' );
    ok( !$product2->check_permission( $admin_group, 'create ticket' ), 'admin cannot create' );


    # Owner group can create tickets
    $owner_group->permissions->allow('create ticket', product => $product2 );
    # Only managers can update tickets in triage (assign)
    $mgr_group->permissions->allow('update ticket', queue => $triage );

    # Nobody can create tickets in this queue, they must be assigned
    $queue->permissions->prohibit('create ticket');
    # admin_group can, because they're awesome.
    $admin_group->permissions->allow( permission => 'create ticket', queue => $queue );

    $group->permissions->make_read_only; # macro sets
    $group->permissions->prohibit('update ticket');
    $group->permissions->prohibit('create ticket', { queue => [ 'Triage' ]});
    $group->permissions->allow('assign ticket', { queue => [ 'Triage' ]});

    $person->permissions->allow('create ticket');
}

1;
