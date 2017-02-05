use strict;
package YAML::Pegex::Receiver::Test;
use Pegex::Base;
extends 'YAML::Pegex::Receiver';

use Encode;

my $stream_start_index = 0;
my $stream_end_index = 0;
my $document_start_index = 0;
my $document_end_index = 0;

my $events = {
    STREAM_START => '+STR',
    STREAM_END => '-STR',
    DOCUMENT_START => '+DOC',
    DOCUMENT_END => '-DOC',
    MAPPING_START => '+MAP',
    MAPPING_END => '-MAP',
    SEQUENCE_START => '+SEQ',
    SEQUENCE_END => '-SEQ',
    SCALAR => '=VAL',
    ALIAS => '=ALI',
};

sub initial {
    my ($self) = (shift);
    $self->{events} = [];
    $self->SUPER::initial($@);
}

sub final {
    my ($self) = (shift);
    $self->SUPER::final($@);

    return $self->{events};

}

sub got_single_quoted_scalar {
    my ($self, $got) = @_;
    $got =~ s{((?:[ \t]*\r?\n[ \t]*)+)}{
        my $c = $1 =~ tr/\n//;
        $c == 1 ? ' ' : '\n' x ($c - 1);
    }ge;
    $got =~ s/''/'/g;
    $got =~ s/\\/\\\\/g;
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
    $got =~ s/\\x0d/\\r/g;
    $got =~ s/\\x0a/\\n/g;
    #pack('U', 0x263a);
    $got =~ s/\\u(....)/Encode::encode_utf8(chr(hex($1)))/eg;
    $self->send(SCALAR => "\"$got");
}

sub send {
    my ($self, $name, @args) = @_;
    $name = $events->{$name} or die "Unknown event: '$name'";
    if (defined $self->{tag}) {
        unshift @args, '<' . delete($self->{tag}) . '>';
    }
    if (defined $self->{anchor}) {
        unshift @args, '&' . delete $self->{anchor};
    }
    push @{$self->{events}}, join(' ', $name, @args);
    return;
}

1;
