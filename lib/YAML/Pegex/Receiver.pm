use strict;
package YAML::Pegex::Receiver;
use Pegex::Base;
extends 'Pegex::Tree';

sub setup {
    my ($self) = @_;
    $self->{stack} = [];
    $self->{kind} = [];
    $self->{level} = -1;
}

sub initial {
    my ($self) = @_;
    $self->setup;
    $self->send('STREAM_START');
    $self->send('DOCUMENT_START');
}

sub final {
    my ($self, $got) = @_;
    $self->send('DOCUMENT_END');
    $self->send('STREAM_END');
    return $self->data;
}

sub got_block_key {
    my ($self, $got) = @_;
    my $level = @{$self->parser->grammar->{indent}} - 1;
    $self->{level} = $level if $level > $self->{level};
    if (not $self->{kind}[$self->{level}]) {
        $self->{kind}[$self->{level}] = 'mapping';
        $self->send('MAPPING_START');
    }
    $self->send(SCALAR => ":$got");
    return;
}

sub got_block_sequence_entry {
    my ($self, $got) = @_;
    if (not $self->{kind}[$self->{level}]) {
        $self->{kind}[++$self->{level}] = 'sequence';
        $self->send('SEQUENCE_START');
    }
    $self->send(SCALAR => ":$got");
    return;
}

sub got_block_undent {
    my ($self, $got) = @_;
    if ($self->{kind}[$self->{level}]) {
        if ($self->{kind}[$self->{level}] eq 'mapping') {
            $self->send('MAPPING_END');
        }
        elsif ($self->{kind}[$self->{level}] eq 'sequence') {
            $self->send('SEQUENCE_END');
        }
    }
    $self->{level}--;
    pop @{$self->{kind}};
    return;
}

sub got_block_scalar {
    my ($self, $got) = @_;
    $self->send(SCALAR => ":$got");
    return;
}

sub got_flow_mapping_start {
    my ($self, $got) = @_;
    $self->send('MAPPING_START');
    $self->{kind}[++$self->{level}] = 'mapping';
    return;
}

sub got_flow_mapping_end {
    my ($self, $got) = @_;
    $self->send('MAPPING_END');
    $self->{level}--;
    pop @{$self->{kind}};
    return;
}

sub got_flow_sequence_start {
    my ($self, $got) = @_;
    $self->send('SEQUENCE_START');
    $self->{kind}[++$self->{level}] = 'sequence';
    return;
}

sub got_flow_sequence_end {
    my ($self, $got) = @_;
    $self->send('SEQUENCE_END');
    $self->{level}--;
    pop @{$self->{kind}};
    return;
}

sub got_flow_scalar {
    my ($self, $got) = @_;
    $self->send(SCALAR => ":$got");
    return;
}

1;
