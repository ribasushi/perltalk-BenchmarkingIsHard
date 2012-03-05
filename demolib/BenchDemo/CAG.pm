package BenchDemo::CAG;

use base 'Class::Accessor::Grouped';

{
  local $Class::Accesor::Grouped::USE_XS = 0;
  __PACKAGE__->mk_group_accessors(simple => 'stuff');
}

1;
