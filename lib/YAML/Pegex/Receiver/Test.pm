use strict;
package YAML::Pegex::Receiver::Test;
use Pegex::Base;
extends 'YAML::Pegex::Receiver';

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
