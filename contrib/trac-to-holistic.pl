#!/usr/bin/perl
use strict;

use Data::Dumper;
use DateTime;
use Holistic::Schema;
use YAML qw(LoadFile);

use Holistic::Conversion::Trac;

my $conv = Holistic::Conversion::Trac->new_with_options;

my $conf = LoadFile($conv->config);
# die Dumper($conf->{'Model::Schema'}->{connect_info});

my $schema = Holistic::Schema->connect(@{ $conf->{'Model::Schema'}->{connect_info} });

my $dbh = DBI->connect(
    'DBI:mysql:database='.$conv->database.';host='.$conv->host.';port='.$conv->port,
    $conv->username, $conv->password
);

my $ticket_rs = $schema->resultset('Ticket');

# XX Need some type map for our types
my %ticket_type_cache;
my $ticket_type_rs = $schema->resultset('Ticket::Type');

my %person_cache;
my $person_rs = $schema->resultset('Person');

my %identity_cache;
my $identity_rs = $schema->resultset('Person::Identity');

my %queue_cache;
my $queue_rs = $schema->resultset('Queue');

my %product_cache;
my $product_rs = $schema->resultset('Product');

my $tick_sth = $dbh->prepare('SELECT id, type, time, changetime, component, severity, priority, owner, reporter, cc, version, milestone, status, resolution, summary, description, keywords FROM ticket');
my $mile_sth = $dbh->prepare('SELECT name, due, completed, description FROM milestone WHERE name=?');
my $prod_sth = $dbh->prepare('SELECT name, owner, description FROM component WHERE name=?');

$tick_sth->execute;

my %row;
$tick_sth->bind_columns( \( @row{ @{$tick_sth->{NAME_lc} } } ));
while ($tick_sth->fetch) {
    make_ticket(\%row);
    # die;
}

sub make_ticket {
    my ($row) = @_;

    # Find a type
    my $type = $ticket_type_cache{$row->{type}};
    unless(defined($type)) {
        $type = $ticket_type_rs->create({
            name => $row->{type}
        });
        $ticket_type_cache{$row->{type}} = $type
    }

    my ($rep_person, $rep_ident) = find_person_and_identity($row->{reporter});
    my $product = find_product($row->{$conv->product});
    my $queue = find_queue($row->{$conv->queue}, $product);

    my $tick = $ticket_rs->create({
        pk1         => $row->{id},
        type_pk1    => $type->id,
        identity_pk1=> $rep_ident->id,
        name        => $row->{summary},
        description => $row->{description},
        dt_created=> DateTime->from_epoch(epoch => $row->{time}),
        dt_updated=> DateTime->from_epoch(epoch => $row->{changetime})
    });
    $tick->update({ parent_pk1 => $queue->id }) if defined($queue);
}

sub find_person_and_identity {
    my ($email) = @_;

    # Find a person
    my $person = $person_cache{$email};

    unless(defined($person)) {
        $person = $person_rs->create({
            token   => $email,
            name    => $email,
            public  => 1,
            email   => $email,
            timezone => 'America/Chicago', # XX
        });
        $person_cache{$email} = $person;
    }

    # Find an identity
    my $identity = $person->local_identity;

    unless(defined($identity)) {
        $identity = $person->add_to_identities({
            realm   => 'local',
            ident   => $email,
            secret  => '', # XX, need a password?
            active  => 1
        });
        $identity_cache{$email} = $identity;
    }

    return ( $person, $identity );
}

sub find_queue {
    my ($name, $product) = @_;

    my $queue = $queue_cache{$name};
    unless(defined($queue)) {

        $mile_sth->execute($name);
        my %row;
        $mile_sth->bind_columns( \( @row{ @{$mile_sth->{NAME_lc} } } ));

        # XX Need due date and completed!
        $queue = $queue_rs->create({
            name        => $name,
            description => $row{description}
        });
        if(defined($product)) {
            $product->add_to_queue_links({ queue_pk1 => $queue->id });
        }
        $queue_cache{$name} = $queue;
    }
    return $queue;
}

sub find_product {
    my ($name) = @_;

    my $product = $product_cache{$name};
    unless(defined($product)) {

        $prod_sth->execute($name);
        my %row;
        $prod_sth->bind_columns( \( @row{ @{$prod_sth->{NAME_lc} } } ));

        # XX Need due date and completed!
        $product = $product_rs->create({
            name        => $name,
            description => $row{description}
        });
        $product_cache{$name} = $product;
    }
    return $product;
}