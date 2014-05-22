use strict;
package YAML::Pegex::AST;
use base 'Pegex::Tree';
use XXX;

sub initial {
    my ($self) = @_;
    $self->{events} = [];
    $self->{stack} = [];
    $self->{kind} = [];
    $self->{level} = 0;
}

sub final {
    my ($self, $got) = @_;
    if ($self->{kind}[0] eq 'mapping') {
        $self->send('MAPPING_END');
    }
    join '', map { "$_\n" } @{$self->{events}};
}

sub got_scalar {
    my ($self, $got) = @_;
    if ($self->{kind}[$self->{level}]) {
        warn "2 $got";
        $self->send(SCALAR => $got, 1)
    }
    else {
        push @{$self->{stack}}, [scalar => $got, 1];
    }
    return;
}

sub got_mapping_separator {
    my ($self, $got) = @_;
    if (not $self->{kind}[$self->{level}]) {
        $self->{kind}[$self->{$self->{level}}] = 'mapping';
        $self->send('MAPPING_START');
        my $key = pop @{$self->{stack}};
        shift @$key;
        warn "2 $key->[1]";
        $self->send(SCALAR => @$key);
    }
    return;
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
