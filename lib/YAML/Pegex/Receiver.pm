use strict;
package YAML::Pegex::Receiver;
use base 'Pegex::Tree';

sub initial {
    my ($self) = @_;
    $self->setup;
    $self->send('STREAM_START');
    $self->send('DOCUMENT_START');
}

sub setup {
    my ($self) = @_;
    $self->{stack} = [];
    $self->{kind} = [];
    $self->{level} = 0;
}

sub final {
    my ($self, $got) = @_;
    if ($self->{kind}[0] eq 'mapping') {
        $self->send('MAPPING_END');
    }
    $self->send('DOCUMENT_END');
    $self->send('STREAM_END');
    return $self->data;
}


sub got_scalar {
    my ($self, $got) = @_;
    if ($self->{kind}[$self->{level}]) {
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
        $self->send(SCALAR => @$key);
    }
    return;
}

1;
