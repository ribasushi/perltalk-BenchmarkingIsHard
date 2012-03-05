package BenchDemo::MooseMI;

use Moose;

has stuff => (is => 'rw');

__PACKAGE__->meta->make_immutable;

1;
