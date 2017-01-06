use strict;
package YAML::Pegex::Receiver::Test;
use Pegex::Base;
extends 'YAML::Pegex::Receiver';

my $events = {
    STREAM_START => '+STR',
    STREAM_END => '-STR',
    DOC_START => '+DOC',
    DOC_END => '-DOC',
    MAPPING_START => '+MAP',
    MAPPING_END => '-MAP',
    SEQUENCE_START => '+SEQ',
    SEQUENCE_END => '-SEQ',
    SCALAR => '=VAL',
};

sub initial {
    my ($self) = (shift);
    $self->setup;
    $self->{events} = [];
}

sub final {
    my ($self, $got) = @_;

    # XXX This `if` goes away when sequence indent/undent works.
    # if ($self->{kind}[0] and $self->{kind}[0] eq 'sequence') {
    #     $self->send('SEQUENCE_END');
    # }

    my $result = join '', map { "$_\n" } @{$self->{events}};
    $result = "+STR\n$result-STR\n" if $result eq '';
    return $result;
}

sub send {
    my ($self, $name, @args) = @_;
    my $event;
    $name = $events->{$name} or die "Unknown event: '$name'";
    if ($name eq 'SCALAR') {
        my $value = shift(@args);
        $event = join ' ', join(' ', $name, @args), $value;
    }
    else {
        $event = join(' ', $name, @args);
    }
    push @{$self->{events}}, $event;
    return;
}

1;
