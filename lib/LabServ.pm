package LabServ;

use warnings;
use strict;
use Carp;

use vars qw($VERSION @ISA @EXPORT);
use Exporter;
use Cwd;

@ISA = qw( Exporter );
@EXPORT = qw( create_item );

use LabServ::Item;

sub new
{
  my $class = shift;
  my $self = {@_};
  bless $self, $class;

  if (!defined $self->{items_dir}) {
    die "LabServ->new() is missing an items_dir argument\n";
  }

  return $self;
}

sub time_sort
{
  my ($atime) = $a =~ /\.(.*)/;
  my ($btime) = $b =~ /\.(.*)/;

  return $atime <=> $btime;
}

sub create_item
{
  my $dir = shift;
  my $type = shift;
  my $date = shift;

  my $item = new LabServ::Item(type => $type, date => $date);
  my @item_file_names = get_item_file_names($dir);
  my $newest = $item_file_names[-1];
  my ($number, $timestamp) = $newest =~ /^(\d+)\.(\d+)/;
  my $new_file_name = sprintf "$dir/%4.4d.$date", ($number + 1);

  open my $new_file, ">", $new_file_name or die "can't open $new_file_name\n";
  print $new_file $item->to_string();
  close $new_file or die;

  return $new_file_name
}

sub get_item_file_names
{
  my $dir = shift;

  opendir my $dirh, $dir or die "can't read from directory: $dir - $!\n";
  my @item_files = sort time_sort grep { /^\d+\.\d+$/ } readdir($dirh);
  closedir $dirh or die;
  return @item_files;
}

sub has_right_tags
{
  my $item = shift;
  my $needed_tags = shift;
  my $not_needed_tags = shift;

  for my $needed_tag (@$needed_tags) {
    if (!grep {$_ eq $needed_tag} @{$item->tags()}) {
      return 0;
    }
  }

  for my $not_needed_tag (@$not_needed_tags) {
    if (grep {$_ eq $not_needed_tag} @{$item->tags()}) {
      return 0;
    }
  }

  return 1;
}

sub init_items
{
  my $self = shift;
  my $dir = shift;

  my @all_item_files = get_item_file_names($dir);

  my @items = ();

  for my $file (@all_item_files) {
    push @items, LabServ::Item->read("$dir/$file");
  }

  $self->{items} = \@items;
}

sub get_items
{
  my $self = shift;

  if (!defined $self->{items}) {
    $self->init_items($self->{items_dir});
  }

  return @{$self->{items}};
}

sub filter_items
{
  my $self = shift;
  my $type = shift;
  my @tags = @_;

  my @needed_tags = grep { !/^!/ } @tags;
  my @not_needed_tags = grep { /^!/ } @tags;

  map { s/^!// } @not_needed_tags;

  my @ret_items = ();

  for my $item ($self->get_items()) {
    if ((!defined $type or (ref $type eq 'ARRAY' and grep { $_ eq $item->type() } @$type or $item->type() eq $type)) &&
        has_right_tags($item, \@needed_tags, \@not_needed_tags)) {
      push @ret_items, $item;
    }
  }

  return @ret_items;
}

my %display_type = (
                    news => 'News',
                    blog => 'Blog',
                    ask => 'Ask Tony',
                    pic => 'Photo Gallery',
                    person => 'Party People',
                    history => 'History',
                   );

sub display_type {
  my $class = shift;
  my $type = shift;
  if (defined $display_type{$type}) {
    return $display_type{$type};
  } else {
    die "unknown type; $type\n";
  }
}

=head1 AUTHOR

Kim Rutherford <webmaster@labourservative.org.uk>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
