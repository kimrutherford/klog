#!/usr/bin/perl -w  # -*-Perl-*-
#----------------------------------------------------------------------
# generate.pl	-- Kim Rutherford

use strict;

use Cwd;
use File::Basename;
use File::Find;
use File::Path;
use File::Spec;
use File::Compare;
use Cwd;
use HTML::Mason;

my $start_dir;
BEGIN {
  $start_dir = getcwd();
  push (@INC, "$start_dir/lib");
}

use LabServ;
use LabServ::LinkMaker;
use LabServ::RefManager;

# These are directories.  The canonpath method removes any cruft
# like doubled slashes.
my ($source, $target) = map { File::Spec->canonpath($_) } @ARGV;

die "Need a source and target\n"
unless defined $source && defined $target;

# Make target absolute because File::Find changes the current working
# directory as it runs.
$target = File::Spec->rel2abs($target);

my $interp =
  HTML::Mason::Interp->new(comp_root => File::Spec->rel2abs(cwd),
                           default_escape_flags => 'h');

my $lab_serv = new LabServ(items_dir => "$start_dir/items");
my $link_maker = new LabServ::LinkMaker(lab_serv => $lab_serv);
my $ref_manager = new LabServ::RefManager(lab_serv => $lab_serv);

$interp->{lab_serv} = $lab_serv;
$interp->{link_maker} = $link_maker;
$interp->{ref_manager} = $ref_manager;

find( \&convert, $source );

sub convert {
  my $local_name = $_;

  # We don't want to try to convert our autohandler or .mas
  # components.  $_ contains the filename
  return unless /\.i?html$/;

  my @iter_args = ({});

  my $iter_name = "$local_name.iter";

  if (-e $iter_name) {
    open my $file, '<', $iter_name or die "can't open $iter_name\n";

    my $contents;
    {
      local $/ = undef;
      $contents = <$file>;
    }

    @iter_args = eval $contents;

    if ($@) {
      die "failed to eval() contents of $iter_name: $@\n";
    }

    close $file or die;
  }

  # We want to split the path to the file into its components and
  # join them back together with a forward slash in order to make
  # a component path for Mason
  #
  # $File::Find::name has the path to the file we are looking at,
  # relative to the starting directory
  my $comp_path = join '/', File::Spec->splitdir($File::Find::name);

  for my $iter_args (@iter_args) {
    my %iter_args = %$iter_args;

    my $buffer;
    # This will save the component's output in $buffer
    $interp->out_method(\$buffer);

    $interp->exec("/$comp_path", %iter_args, start_dir => $start_dir);
    # Strip off leading part of path that matches source directory
    my $out_name = $File::Find::name;
    $out_name =~ s/^$source//;
    if (exists $iter_args{file_name}) {
      $out_name = $iter_args{file_name};
    }

    # Generate absolute path to output file
    my $out_file = File::Spec->catfile( $target, $out_name );
    # In case the directory doesn't exist, we make it
    mkpath(dirname($out_file));

    local *RESULT;
    open RESULT, "> $out_file.tmp" or die "Cannot write to $out_file.tmp: $!";
    print RESULT $buffer or die "Cannot write to $out_file.tmp: $!";
    close RESULT or die "Cannot close $out_file.tmp: $!";

    if (!-e $out_file ||
        File::Compare::compare ($out_file, "$out_file.tmp") == 1) {
      # needs updating
      warn "out of date: $out_file\n";
      rename "$out_file.tmp", $out_file or die;
    } else {
      unlink "$out_file.tmp" or die;
    }
  }
}
