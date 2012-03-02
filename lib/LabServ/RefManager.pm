package LabServ::RefManager;

use warnings;
use strict;

sub new
{
  my $class = shift;
  my $self = {@_};
  my $lab_serv = $self->{lab_serv};

  my @people_items = $lab_serv->filter_items('person');
  my @other_items =
    $lab_serv->filter_items(['news', 'blog', 'ask', 'pic', 'history'],
                            '!:hidden');

  my %references = ();

  for my $other_item (@other_items) {
    for my $people_item (@people_items) {
      my $pattern = '\b' . $people_item->subject() . '\b';
      for my $para (@{$other_item->text()}) {
        if ($para =~ /$pattern/) {
          $references{$people_item->id()}{$other_item->id()} = $other_item;
        }
      }
      if ($other_item->subject() =~ /$pattern/) {
        $references{$people_item->id()}{$other_item->id()} = $other_item;
      }
      if (defined $other_item->author() && $other_item->author() =~ /$pattern/) {
        $references{$people_item->id()}{$other_item->id()} = $other_item;
      }
      if ($people_item->subject() eq 'Tony Blair' && $other_item->type() eq 'ask') {
        $references{$people_item->id()}{$other_item->id()} = $other_item;
      }
    }
  }

  $self->{references} = \%references;

  return bless $self, $class;
}

sub get_references
{
  my $self = shift;
  my $item = shift;

  my $ref_hash_ref = $self->{references}{$item->id()};

  if (defined $ref_hash_ref) {
    my @ret_list = values %$ref_hash_ref;
    @ret_list = sort { $a->id() cmp $b->id() } @ret_list;
    return @ret_list;
  } else {
    return ();
  }
}

1;
