use strict;
package YAML::Pegex::Receiver::Test;
use Pegex::Base;
extends 'YAML::Pegex::Receiver';

sub initial {
    my ($self) = (shift);
    $self->setup;
    $self->{events} = [];
}

sub final {
    my ($self, $got) = @_;

    # XXX This `if` goes away when sequence indent/undent works.
    if ($self->{kind}[0] and $self->{kind}[0] eq 'sequence') {
        $self->send('SEQUENCE_END', 'block');
    }

    join '', map { "$_\n" } @{$self->{events}};
}

sub send {
    my ($self, $name, @args) = @_;
    my $event;
    if ($name eq 'SCALAR') {
        my $value = shift(@args);
        $event = join ' ', join(',', $name, @args), $value;
    }
    else {
        $event = join(',', $name, @args);
    }
    push @{$self->{events}}, $event;
}

1;
