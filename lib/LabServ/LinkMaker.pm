package LabServ::LinkMaker;

use warnings;
use strict;

use LabServ;
use LabServ::Config;

sub new
{
  my $class = shift;
  my $self = {@_};
  my $lab_serv = $self->{lab_serv};

  if (!defined $lab_serv) {
    die "LinkMaker->new() missing a lab_serv argument\n";
  }

  my @people_items = $lab_serv->filter_items('person');

  my %people_items = map {
    my $item = $_;
    ($item->subject(), $item,
     map { $_, $item } @{$item->aka()},
     map { $_, $item } $item->post());
  } @people_items;

  $self->{people_items} = \%people_items;
  push my @people_names, sort { 
    length $b <=> length $a;
  } keys %{$self->{people_items}};
  $self->{pattern} = join '|', @people_names;
  return bless $self, $class;
}

sub make_anchor
{
  my $self = shift;
  my $name = shift;
  my $item = $self->{people_items}{$name};
  my $id = $item->id();
  my $type = $item->type();
  return "<a href='${type}_${id}' class='help'>$name</a>";
}

sub make_links
{
  my $self = shift;
  my $text_ref = shift;
  my $pattern = $self->{pattern};

  $$text_ref =~ s/\s*\n\s*/ /g;
  $$text_ref =~ s:($pattern):$self->make_anchor($1):eg;
}

1;
