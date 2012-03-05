#!/usr/bin/env perl

use warnings;
use strict;

use Module::Runtime 'require_module';
use Module::Find 'findsubmod';
use lib 'demolib';
require_module($_) for findsubmod 'BenchDemo';

my $moose_obj = BenchDemo::MooseMI->new( stuff => 42 );
my $cag_obj = bless { stuff => 42 }, 'BenchDemo::CAG';
DB::enable_profile('bench.prof');
my $x = $moose_obj->stuff for (1 .. 1_000);
my $y = $cag_obj->stuff for (1 .. 1_000);
DB::disable_profile();

1;
