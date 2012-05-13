#!/usr/bin/env perl

use warnings;
use strict;

BEGIN { $|++ }

use Term::Screen;
use Benchmark qw/timethis cmpthese/;
use Benchmark::Dumb();
use B::Deparse;
use Carp 'cluck';
use File::Path 'rmtree';

use lib 'demolib';
use Module::Find 'findsubmod';
use Module::Runtime 'require_module';
require_module($_) for findsubmod 'BenchDemo';

my $TOO_LONG = 25;

my @o;
my $tasklist = [
  [ 'time 10000' => sub {
    @o = BenchDemo::Moose->new( stuff => 42 );
    timethis( 10000, sub {
        my $x = $o[0]->stuff;
    });
  }],

  [ 'time 10000 hires' => sub {
    Benchmark->import(':hireswallclock');
    @o = BenchDemo::Moose->new( stuff => 42 );
    timethis( 10000, sub {
        my $x = $o[0]->stuff;
    });
  }],

  [ 'time 2 sec' => sub {
    @o = BenchDemo::Moose->new( stuff => 42 );
    timethis( -2, sub {
        my $x = $o[0]->stuff;
    });
  }],

  [ 'cmp moose make_immutable' => sub {
    @o = (
      BenchDemo::Moose->new( stuff => 42 ),
      BenchDemo::MooseMI->new( stuff => 42 ),
    );
    cmpthese( -2, {
      Moose => sub {
        my $x = $o[0]->stuff;
      },
      MooseMI => sub {
        my $x = $o[1]->stuff;
      },
    });
  }],

  [ 'BD::cmp moose make_immutable' => sub {
    @o = (
      BenchDemo::Moose->new( stuff => 42 ),
      BenchDemo::MooseMI->new( stuff => 42 ),
    );
    Benchmark::Dumb::cmpthese( 0, {
      Moose => sub {
        my $x = $o[0]->stuff;
      },
      MooseMI => sub {
        my $x = $o[1]->stuff;
      },
    });
  }],

  [ 'BD::cmp moose make_immutable 0.005%' => sub {
    @o = (
      BenchDemo::Moose->new( stuff => 42 ),
      BenchDemo::MooseMI->new( stuff => 42 ),
    );
    Benchmark::Dumb::cmpthese( '0.00005', {
      Moose => sub {
        my $x = $o[0]->stuff;
      },
      MooseMI => sub {
        my $x = $o[1]->stuff;
      },
    });
  }],

  [ 'BD::cmp mooseMI vs CAF 0.005%' => sub {
    @o = (
      BenchDemo::MooseMI->new( stuff => 42 ),
      BenchDemo::CAF->new({ stuff => 42 }),
    );
    Benchmark::Dumb::cmpthese( '0.00005', {
      MooseMI => sub {
        my $x = $o[0]->stuff;
      },
      CAF => sub {
        my $x = $o[1]->stuff;
      },
    });
  }],

  [ 'BD::cmp mooseMI vs EVIL 0.005%' => sub {
    @o = (
      BenchDemo::MooseMI->new( stuff => 42 ),
    );
    Benchmark::Dumb::cmpthese( '0.00005', {
      MooseMI => sub {
        my $x = $o[0]->stuff;
      },
      EVIL => sub {
        my $x = $o[0]->{stuff};
      },
    });
  }],

  [ 'BD::cmp C::XSA vs EVIL 0.005%' => sub {
    @o = (
      BenchDemo::CXSA->new( stuff => 42 ),
    );
    Benchmark::Dumb::cmpthese( '0.00005', {
      CXSA => sub {
        my $x = $o[0]->stuff;
      },
      EVIL => sub {
        my $x = $o[0]->{stuff};
      },
    });
  }],

  [ 'BD::cmp C::XSA vs *actual* EVIL 0.05% / 100k' => sub {
    @o = (
      BenchDemo::MooseMI->new( stuff => 42 ),
    );
    Benchmark::Dumb::cmpthese( '0.0005', {
      CXSA => sub {
        my $x = $o[0]->stuff for (0..100_000);
      },
      EVIL => sub {
        my $x = $o[0]->{stuff} for (0..100_000);
      },
    });
  }],

  [ 'WHY the above result?!' => sub {
    eval {
      Benchmark::Dumb::cmpthese( '0.0005', {
        EVIL => sub {
          cluck( 'csxa' );
          die;
        },
      });
    }
  }],

  [ 'Attempt of overhead measure' => sub {
    my $x = 42;
    Benchmark::Dumb::timethis( '0.0001', sub { $x } );
  }],

  [ 'BD::cmp moose make_immutable 0.01% / 1k' => sub {
    @o = (
      BenchDemo::Moose->new( stuff => 42 ),
      BenchDemo::MooseMI->new( stuff => 42 ),
    );
    Benchmark::Dumb::cmpthese( '0.0001', {
      Moose => sub {
        my $x = $o[0]->stuff for (1 .. 1_000);
      },
      MooseMI => sub {
        my $x = $o[1]->stuff for (1 .. 1_000);
      },
    });
  }],

  [ 'BD::cmp mooseMI vs CAF 0.01% / 1k' => sub {
    @o = (
      BenchDemo::MooseMI->new( stuff => 42 ),
      BenchDemo::CAF->new({ stuff => 42 }),
    );
    Benchmark::Dumb::cmpthese( '0.0001', {
      MooseMI => sub {
        my $x = $o[0]->stuff for (1 .. 1_000);
      },
      CAF => sub {
        my $x = $o[1]->stuff for (1 .. 1_000);
      },
    });
  }],

  [ 'BD::cmp mooseMI vs CAG 0.01% / 1k' => sub {
    @o = (
      BenchDemo::MooseMI->new( stuff => 42 ),
      bless( { stuff => 42 }, 'BenchDemo::CAG'),
    );
    Benchmark::Dumb::cmpthese( '0.0001', {
      MooseMI => sub {
        my $x = $o[0]->stuff for (1 .. 1_000);
      },
      CAG => sub {
        my $x = $o[1]->stuff for (1 .. 1_000);
      },
    });
  }],

  [ 'Profile MooseMI / CAG' => sub {

    rmtree("bench_nytprof");
    unlink("bench.prof");

    local $ENV{NYTPROF} = 'start=no:clock=2';
    system($^X, '-d:NYTProf', 'benchprof.pl');

    system(qw/nytprofhtml -l demolib -o bench_nytprof -f bench.prof/);
    system(qw{x-www-browser ./bench_nytprof/index.html});

  }],
];

runloop();

sub runloop {
  my ($task, $cmd, $deparse);
  my $cmd_def = 'n';

  Term::Screen->new->clrscr;  # why the hell doesn't this work saved in a var >.<

  $SIG{ALRM} = sub { die "Run is taking toooooo long, possibly a runaway approximation? Try again :(\n" };

  while (1) {

    printf "Tasklist\n========\n";
    printf "  % 3d: %s\n", $_, $tasklist->[$_][0]
      for (0 .. $#$tasklist);
    print "\n";


    for (1) {
      printf "N(ext), P(rev), R(edo), Task#, Q(uit)\n%s: ",
        $cmd_def ? sprintf( '(%s/%d)', uc $cmd_def, $task||0) : '',
      ;

      chomp ($cmd = lc (<STDIN>) );
      $cmd = (length $cmd) ? $cmd : $cmd_def;

      redo if not defined $cmd;

      if ($cmd eq 'n') {
        my $t = defined $task ? $task + 1 : 0;
        undef $cmd_def if $t >= $#$tasklist;
        if ($t > $#$tasklist) {
          $task = $#$tasklist;
          redo;
        };
        $task = $t;
      }
      elsif ($cmd eq 'r') {
        unless (defined $task) {
          undef $cmd_def;
          redo;
        }
        $cmd_def = 'r';
      }
      elsif ($cmd eq 'q') {
        exit 0;
      }
      elsif ($cmd eq 'p') {
        my $t = ($task||0) - 1;
        undef $cmd_def if $t <= 0;
        if ($t < 0) {
          undef $cmd_def;
          $task = 0;
          redo;
        };
        $task = $t;
      }
      elsif ($cmd =~ /^[0-9]+$/) {
        undef $cmd_def;
        my $t = $cmd+0;
        redo if $t > $#$tasklist;
        $task = $t;
        $cmd_def = 'r';
      }
      else {
        redo;
      }
    }

    Term::Screen->new->clrscr;  # why the hell doesn't this work saved in a var >.<

    printf "Task %d '%s'...\n%s\n\n%s\n\n%s\n\n\n",
      $task,
      $tasklist->[$task][0],
      'v' x 76,
      ($deparse ||= B::Deparse->new)->coderef2text($tasklist->[$task][1]),
      '^' x 76,
    ;
    eval {
      alarm ($TOO_LONG);
      $tasklist->[$task][1]->();
      alarm(0);
      1;
    } or warn $@;
    printf "\n\n\n\n";
  }
}
