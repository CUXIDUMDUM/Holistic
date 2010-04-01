package Holistic::Conversion::Trac;
use Moose;

with 'MooseX::Getopt';

has config => (
    is => 'rw',
    isa => 'Str',
    required => 1
);

has database => (
    is => 'rw',
    isa => 'Str',
    required => 1
);

has host => (
    is => 'rw',
    isa => 'Str',
    default => 'localhost'
);

has password => (
    is => 'rw',
    isa => 'Str'
);

has port => (
    is => 'rw',
    isa => 'Int',
    default => 3367
);

has product => (
    is => 'rw',
    isa => 'Str',
    default => 'component'
);

has queue => (
    is => 'rw',
    isa => 'Str',
    default => 'milestone'
);

has username => (
    is => 'rw',
    isa => 'Str',
    default => 'root'
);

1;