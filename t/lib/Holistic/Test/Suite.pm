package Holistic::Test::Suite;

use Moose;
use MooseX::Method::Signatures;

method run(
    ArrayRef :$with,
    ArrayRef :$plan   = [],
    ArrayRef :$tests  = [],
    HashRef  :$config = {}
) {

    my @roles = ( 'Holistic::Test::Base' );
    foreach my $role ( @$with ) {
        if ( $role =~ /^(\+|Holistic::Test::)/ ) {
            push @roles, $role;
        } else {
            push @roles, "Holistic::Test::$role";
        }
    }

    my $suite = Moose::Meta::Class->create_anon_class(
        roles        => [ @roles ],
        cache        => 1,
    )->new_object( $config );

    $suite->run( $tests );
    
}

1;
