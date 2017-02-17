use strict;
package YAML::Pegex::Receiver;
use Pegex::Base;
extends 'Pegex::Tree';

has data => {};
has props => [];

sub reset_tags {
    my ($self) = @_;
    $self->{tags} = {
        '' => 'tag:yaml.org,2002:',
    };
}

sub setup {
    my ($self) = @_;
}

sub initial {
    my ($self) = @_;
    $self->{kind} = [''];
    $self->{level} = 0;
    $self->{props} = [];
    $self->reset_tags;
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

sub got_directive_tag {
    my ($self, $got) = @_;
    my ($tag, $prefix) = @$got;
    $self->{tags}->{$tag} = $prefix;
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
    $self->reset_tags;
}

sub got_document_end {
    my ($self) = @_;
    $self->send('DOCUMENT_END');
}

sub got_yaml_alias {
    my ($self, $got) = @_;
    $self->send(ALIAS => "*$got");
}

sub got_yaml_props {
    my ($self, $got) = @_;
    my $anchor = $got->[0] || $got->[3];
    my $tag = $self->resolve_tag($got->[1] || $got->[2]);
    my $ws = $got->[4];
    push @{$self->{props}}, [$anchor, $tag, $ws];
    return;
}

sub get_props {
    my ($self, $key) = @_;
    return () unless @{$self->{props}};
    return () if $key and $self->{props}[-1][2] =~ /\n/;
    my $props = pop @{$self->{props}};
    my @props = ();
    push @props, "&$props->[0]" if defined $props->[0];
    push @props, "<$props->[1]>" if defined $props->[1];
    return @props;
}

sub resolve_tag {
    my ($self, $tag) = @_;
    defined $tag or return;

    if ($tag =~ m/^!(.*)!(.+)/) {
        my $key = $1;
        my $value = $2;
        $value =~ s/%21/!/g;
        if (defined( my $prefix = $self->{tags}->{$key})) {
            $tag = $prefix . $value;
        }
    }

    return $tag;
}

sub unescape_double {
    my ($self, $string) = @_;
    $string =~ s{((?:[ \t]*\r?\n[ \t]*)+)}{
        my $c = $1 =~ tr/\n//;
        $c == 1 ? ' ' : '\n' x ($c - 1);
    }ge;
    $string =~ s/\\"/"/g;
    $string =~ s/\t/\\t/g;
    $string;
}

sub got_block_scalar {
    my ($self, $got) = @_;
    $self->send(SCALAR => $self->get_props, $got);
}

sub got_flow_scalar {
    my ($self, $got) = @_;
    $self->send(SCALAR => $self->get_props, $got);
}

sub got_block_plain_scalar {
    my ($self, $got) = @_;
    ":$got";
}

sub got_flow_plain_scalar {
    my ($self, $got) = @_;
    $got =~ s/\ +$//;
    ":$got";
}

sub got_single_quoted_scalar {
    my ($self, $got) = @_;
    $got =~ s{((?:[ \t]*\r?\n[ \t]*)+)}{
        my $c = $1 =~ tr/\n//;
        $c == 1 ? ' ' : '\n' x ($c - 1);
    }ge;
    $got =~ s/''/'/g;
    "'$got";
}

sub got_double_quoted_scalar {
    my ($self, $got) = @_;
    $got = $self->unescape_double($got);
    "\"$got";
}

sub got_literal_scalar {
    my ($self, $got) = @_;
    $got =~ s/\\/\\\\/g;
    $got =~ s/\t/\\t/g;
    $got =~ s/\n/\\n/g;
    "|$got";
}

sub got_folded_scalar {
    my ($self, $got) = @_;
    $got =~ s/\\/\\\\/g;
    $got =~ s/\t/\\t/g;
    $got =~ s/\n/\\n/g;
    ">$got";
}

sub got_block_key_scalar {
    my ($self, $got) = @_;
    $self->{block_key} = $got;
    return;
}

sub got_block_key {
    my ($self) = @_;
    my $level = @{$self->parser->grammar->{indent}} - 1;
    $self->{level} = $level if $level > $self->{level};
    my $event = [SCALAR => $self->get_props(1), $self->{block_key}];
    if (not $self->{kind}[$self->{level}]) {
        $self->{kind}[$self->{level}] = 'mapping';
        $self->send('MAPPING_START', $self->get_props);
    }
    $self->send(@$event);
}

sub got_json_key {
    my ($self, $got) = @_;
    $got = $self->unescape_double($got);
    $self->send(SCALAR => $self->get_props, "\"$got");
}

sub got_block_sequence_indent {
    my ($self) = (shift);
    $self->{kind}[++$self->{level}] = 'sequence';
    $self->send('SEQUENCE_START', $self->get_props);
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

sub got_block_sequence_undent {
    my ($self) = @_;
    $self->{level}--;
    pop @{$self->{kind}};
    $self->send('SEQUENCE_END');
}

sub got_flow_mapping_start {
    my ($self) = @_;
    $self->{kind}[++$self->{level}] = 'mapping';
    $self->send('MAPPING_START', $self->get_props);
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
    $self->send('SEQUENCE_START', $self->get_props);
}

sub got_flow_sequence_end {
    my ($self) = @_;
    $self->{level}--;
    pop @{$self->{kind}};
    $self->send('SEQUENCE_END');
}

1;
