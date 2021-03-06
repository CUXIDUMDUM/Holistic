package Holistic::Application;
use Moose;
use Bread::Board;

extends 'Bread::Board::Container';

use MongoDB::Connection;
use Log::Dispatch;
use Log::Dispatch::Screen;
use KiokuDB;
use KiokuDB::Backend::MongoDB;

has 'database_host' => (
    is => 'ro',
    isa => 'Str',
    default => 'localhost'
);

has 'database_name' => (
    is => 'ro',
    isa => 'Str',
    default => 'holistic'
);

has 'database_port' => (
    is => 'ro',
    isa => 'Int',
    default => 27017
);

has 'logging_outputs' => (
    is      => 'ro',
    isa     => 'HashRef[Log::Dispatch::Output]',
    default => sub { {
        'Screen' => Log::Dispatch::Screen->new(
            name => 'screen', min_level => 'debug'
        )
    } }
);

sub BUILD {
    my ($self) = @_;

    # Parameterized container for logging
    my $logging = container 'Logging' => [ 'Outputs' ] => as {
        service 'Logger' => (
            block => sub {
                my $s       = shift;
                my $c       = $s->parent;
                my $outputs = $c->get_sub_container('Outputs');
                my $log     = Log::Dispatch->new;
                foreach my $name ( $outputs->get_service_list ) {
                    $log->add(
                        $outputs->get_service( $name )->get
                    );
                }
                $log;
            }
        );
    };

    container $self => as {

        container 'Database' => as {

            service 'host' => $self->database_host;
            service 'port' => $self->database_port;
            service 'name' => $self->database_name;

            service 'connection' => (
                lifecycle => 'Singleton',
                block => sub {
                    my $s = shift;
                    #use Data::Dumper;
                    #$s->param('/Logging/Logger')->info(Dumper($s));
                    MongoDB::Connection->new(
                        #host => $s->param('host'),
                        #port => $s->param('port')
                    )->get_database($s->param('name'));
                },
                dependencies => wire_names(qw(host name port /Logging/Logger))
            );
        };

        my $configured_outputs = $self->logging_outputs;
        my $outputs = container 'Outputs' => as {
            foreach my $output ( keys %$configured_outputs ) {
                my $dispatcher = $configured_outputs->{$output};
                service $output => (
                    block => sub { $dispatcher; }
                );
            }
        };

        my $logger_container = $logging->create( Outputs => $outputs);
        $logger_container->name('Logging');

        $self->add_sub_container( $logger_container );

        container 'Kioku' => as {

            service 'tickets' => (
                class => 'KiokuDB::Backend::MongoDB',
                block => sub {
                    my $s = shift;
                    my $conn = $s->param('/Database/connection');
                    my $mongo = KiokuDB::Backend::MongoDB->new(
                        collection => $conn->get_collection('tickets')
                    );
                    return KiokuDB->new(backend => $mongo);
                },
                dependencies => wire_names(qw(/Database/connection))
            );
        };

        # service 'Inflator' => (
        #     lifecycle => 'Singleton',
        #     class => 'Holistic::Util::Inflator',
        #     dependencies => {
        #         connection => depends_on('Database/connection'),
        #     }
        # );
        # 
        # container 'Searcher' => as {
        #     service 'tickets' => (
        #         class => 'Holistic::Util::Searcher',
        #         block => sub {
        #             my $s = shift;
        #             Holistic::Util::Searcher->new(
        #                 connection => $s->param('/Database/connection'),
        #                 collection => 'tickets',
        #                 inflator => $s->param('/Inflator'),
        #             );
        #         },
        #         dependencies => wire_names(qw(/Inflator /Database/connection))
        #     );
        # };
    };
}

1;
