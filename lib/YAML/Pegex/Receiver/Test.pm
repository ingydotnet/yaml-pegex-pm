use strict;
package YAML::Pegex::Receiver::Test;
use base 'YAML::Pegex::Receiver';

sub initial {
    my ($self) = (shift);
    $self->setup;
    $self->{events} = [];
}

sub final {
    my ($self, $got) = @_;
    if ($self->{kind}[0] eq 'mapping') {
        $self->send('MAPPING_END');
    }
    elsif ($self->{kind}[0] eq 'sequence') {
        $self->send('SEQUENCE_END');
    }
    join '', map { "$_\n" } @{$self->{events}};
}

sub send {
    my ($self, $name, $value, $flag) = @_;
    $flag ||= 0;
    my $event = $name;
    if ($name eq 'SCALAR') {
        $event .= ",$flag $value"
    }
    push @{$self->{events}}, $event;
}

1;
