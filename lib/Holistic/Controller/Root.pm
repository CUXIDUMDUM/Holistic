package Holistic::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

Holistic::Controller::Root - Root Controller for Holistic

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
}

sub setup : Chained('.') PathPart('') CaptureArgs(0) { }

sub register : Chained('.') PathPart('') CaptureArgs(0) { }
sub auth     : Chained('.') PathPart('') CaptureArgs(0) { }
sub xhr      : Chained('.') PathPart('') CaptureArgs(0) { }

=head2 default

Standard 404 error page

=cut

sub createticket : Local {
    my ($self, $c) = @_;

    $c->stash->{template} = 'createticket.tt';
}

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

sub guide : Local {
    my ($self, $c) = @_;
$c->log->_dump( $c->model('Verifier')->profiles );
    $c->stash->{template} = 'guide.tt';
}

sub login : Local {
    my ($self, $c) = @_;

    $c->stash->{template} = 'login.tt';
}

sub roadmap : Local {
    my ($self, $c) = @_;

    $c->stash->{template} = 'roadmap.tt';
}

sub ticket : Local {
    my ($self, $c) = @_;

    $c->stash->{template} = 'ticket.tt';
}

sub todo : Local {
    my ($self, $c) = @_;

    $c->stash->{template} = 'todo.tt';
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Jay Shirley

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
