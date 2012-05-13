use strict;
use warnings;

use ExtUtils::MakeMaker 6.31;

my %WriteMakefileArgs = (
  'AUTHOR' => 'Peter Rabbitson <ribasushi@cpan.org>',
  'BUILD_REQUIRES' => {
    'Moose' => '0',
    'Class::Accessor::Grouped' => '0',
    'Class::Accessor::Fast' => '0',
    'Term::Screen' => '0',
    'Dumbbench' => '0',
    'Module::Find' => '0',
  },
);

WriteMakefile(%WriteMakefileArgs);



