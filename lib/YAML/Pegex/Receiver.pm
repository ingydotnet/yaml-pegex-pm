use strict;
package YAML::Pegex::Receiver;
use Pegex::Base;
extends 'Pegex::Tree';

has data => {};

sub setup {
    my ($self) = @_;
}

sub initial {
    my ($self) = @_;
    $self->{stack} = [''];
    $self->{kind} = [''];
    $self->{level} = 0;
}

sub final {
    my ($self) = @_;
    return $self->data;
}

sub got_stream_start {
    my ($self) = @_;
    $self->send('STREAM_START');
}

sub got_stream_end {
    my ($self) = @_;
    $self->send('STREAM_END');
}

sub got_document_head {
    my ($self) = @_;
    $self->send('DOCUMENT_START', '---');
}

sub got_document_start {
    my ($self) = @_;
    $self->send('DOCUMENT_START');
}

sub got_document_foot {
    my ($self) = @_;
    $self->send('DOCUMENT_END', '...');
}

sub got_document_end {
    my ($self) = @_;
    $self->send('DOCUMENT_END');
}

sub got_yaml_alias {
    my ($self, $got) = @_;
    $self->send(ALIAS => "*$got");
}

sub got_yaml_anchor {
    my ($self, $got) = @_;
    $self->{anchor} = $got;
    return;
}

sub got_yaml_tag {
    my ($self, $tag) = @_;
    $tag = "tag:yaml.org,2002:$1" if $tag =~ /^!!(.*)/;
    $self->{tag} = $tag;
    return;
}

sub got_block_plain_scalar {
    my ($self, $got) = @_;
    $self->send(SCALAR => ":$got");
}

sub got_flow_plain_scalar {
    my ($self, $got) = @_;
    $got =~ s/\ +$//;
    $self->send(SCALAR => ":$got");
}

sub got_single_quoted_scalar {
    my ($self, $got) = @_;
    $got =~ s{((?:[ \t]*\r?\n[ \t]*)+)}{
        my $c = $1 =~ tr/\n//;
        $c == 1 ? ' ' : '\n' x ($c - 1);
    }ge;
    $got =~ s/''/'/g;
    $self->send(SCALAR => "'$got");
}

sub got_double_quoted_scalar {
    my ($self, $got) = @_;
    $got =~ s{((?:[ \t]*\r?\n[ \t]*)+)}{
        my $c = $1 =~ tr/\n//;
        $c == 1 ? ' ' : '\n' x ($c - 1);
    }ge;
    $got =~ s/\\"/"/g;
    $got =~ s/\t/\\t/g;
    $self->send(SCALAR => "\"$got");
}

sub got_literal_scalar {
    my ($self, $got) = @_;
    $got =~ s/\\/\\\\/g;
    $got =~ s/\t/\\t/g;
    $got =~ s/\n/\\n/g;
    $self->send(SCALAR => "|$got");
}

sub got_block_key_scalar {
    my ($self, $got) = @_;
    my @args = (":$got");
    if (defined $self->{tag}) {
        unshift @args, '<' . delete($self->{tag}) . '>';
    }
    if (defined $self->{anchor}) {
        unshift @args, '&' . delete $self->{anchor};
    }
    $self->{block_key_scalar} = \@args;
    return;
}

sub got_block_key {
    my ($self) = @_;
    my $level = @{$self->parser->grammar->{indent}} - 1;
    $self->{level} = $level if $level > $self->{level};
    if (not $self->{kind}[$self->{level}]) {
        $self->{kind}[$self->{level}] = 'mapping';
        $self->send('MAPPING_START');
    }
    $self->send(SCALAR => @{delete($self->{block_key_scalar})});
}

sub got_block_indent_sequence {
    my ($self) = (shift);
    $self->{kind}[++$self->{level}] = 'sequence';
    $self->send('SEQUENCE_START');
}

sub got_block_undent {
    my ($self) = @_;
    my $event = $self->{kind}[$self->{level}] eq 'mapping'
        ? 'MAPPING_END'
        : 'SEQUENCE_END';
    $self->{level}--;
    pop @{$self->{kind}};
    $self->send($event);
}

sub got_flow_mapping_start {
    my ($self) = @_;
    $self->{kind}[++$self->{level}] = 'mapping';
    $self->send('MAPPING_START');
}

sub got_flow_mapping_end {
    my ($self) = @_;
    $self->{level}--;
    pop @{$self->{kind}};
    $self->send('MAPPING_END');
}

sub got_flow_sequence_start {
    my ($self) = @_;
    $self->{kind}[++$self->{level}] = 'sequence';
    $self->send('SEQUENCE_START');
}

sub got_flow_sequence_end {
    my ($self) = @_;
    $self->{level}--;
    pop @{$self->{kind}};
    $self->send('SEQUENCE_END');
}

1;
