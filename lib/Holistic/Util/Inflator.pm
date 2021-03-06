package Holistic::Util::Inflator;
use Moose;
use JSON::XS qw(encode_json decode_json);

has 'connection' => (
    is => 'ro',
    isa => 'MongoDB::Database',
    required => 1
);

my %collections = (
    'Holistic::Ticket' => 'tickets'
);

sub find {
    my ($self, $class, $id) = @_;

    # Hardcoded database fttb
    my $db = $self->connection;
    my $coll_name = $collections{$class};
    die "Can't find collection for $class" unless defined($coll_name);
    my $doc = $db->get_collection($coll_name)->find_one({ _id => $id });

    return $self->inflate($doc);
}

sub inflate {
    my ($self, $doc) = @_;

    my $oid = $doc->{_id};
    $doc->{_id} = $oid->value;
    my $class = $doc->{__CLASS__};

    return $class->thaw(encode_json($doc), { format => 'JSON' });
}

sub save {
    my ($self, $obj) = @_;

    # Hardcoded database fttb
    my $db = $self->connection;
    my $coll_name = $collections{$obj->meta->name};
    die "Can't find colleciton for ".$obj->meta->name unless defined($coll_name);

    my $doc = $obj->freeze({ format => 'JSON' });
    return $db->get_collection($coll_name)->save(decode_json($doc));
}

1;