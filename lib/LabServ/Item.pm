package LabServ::Item;

=head1 NAME

Store stuff about an item.

=cut

=head1 FUNCTIONS

=cut

use Class::Struct;
use Date::Format;

struct(type => '$', subject => '$', image_position => '$', image => '$',
       date => '$', text => '@', author => '$', post => '$', aka => '@',
       tags => '@', id => '$');

use warnings;
use strict;
use Date::Parse;

sub to_string
{
  my $self = shift;

  my $type = $self->type();
  my $date_str = gmtime($self->date());
  my $subject = $self->subject() || "";
  my $text_ref = $self->text();

  if (!defined $text_ref) {
    $text_ref = [];
  }

  my @text_paragraphs = @$text_ref;

  if (!defined $type) {
    die "type not defined in item\n";
  }

  my $header = <<EOF;
$type $date_str
subject: $subject
EOF

  my $img = $self->image();
  my $img_position = $self->image_position();

  $header .= "image: ";

  if (defined $self->image) {
    if (defined $img_position) {
      $header .= "$img_position $img";
    } else {
      $header .= "$img_position";
    }
  } else {
    if (defined $img_position) {
      $header .= "$img_position";
    }
  }

  $header .= "\n";

  if ($type eq 'blog') {
    if (defined $self->author) {
      $header .= "author: " . $self->author . "\n";
    } else {
      $header .= "author: \n";
    }
  } else {
    if (defined $self->author()) {
      die "item of type $type can't have an author\n";
    }
  }

  return "$header\n" . join '\n', @text_paragraphs;
}

sub dmy
{
  my $self = shift;
  return time2str("%o %b %Y\n", $self->date());
}

sub read
{
  my $class = shift;
  my $file_name = shift;

  open my $file, "<", $file_name or die "can't open $file_name\n";
  my $line = <$file>;
  my ($type, $date_string) = $line =~ /^(\w+)\s+(.*)$/;
  my $date = str2time($date_string);

  my ($id) = $file_name =~ m:.*/(.*):;

  my $item = new LabServ::Item(type => $type, date => $date, id => $id);

  my $subject;
  my $author;
  my $post;
  my @aka;
  my $image;
  my $image_position;
  my $tags = "";

  my $finished_header = 0;

  my $text = [""];

  while (defined ($line = <$file>)) {
    if ($finished_header) {
      if ($line =~ /^\w+:/) {
        warn "suspicious line outside of header - $line\n";
      }

      if ($line =~ /^$/) {
        if (length $text->[-1] > 0) {
          push @$text, "";
        }
      } else {
        $text->[-1] .= $line;
      }
    } else {
      if ($line =~ /^$/) {
        $finished_header = 1;
        next;
      }

      if ($line =~ /^image:/) {
        if ($line =~ /^image:\s*(\S+?)\s*(\S+?)\s*$/) {
          $image_position = $1;
          if ($image_position ne 'left' and $image_position ne 'right' and
              $image_position ne 'centre') {
            die "unknown image_position: $image_position\n";
          }
          $image = $2;
        } else {
          if ($line !~ /^image:\s*$/) {
            chomp $line;
            die "can't understand line \"$line\"\n";
          }
        }
        next;
      } else {
        if ($line =~ /^([^:]+):\s*(\S.*?)\s*$/) {
          if ($1 eq 'subject') {
            $subject = $2;
            next;
          } else {
            if ($1 eq 'author') {
              $author = $2;
              next;
            } else {
              if ($1 eq 'post') {
                $post = $2;
                next;
              } else {
                if ($1 eq 'tags') {
                  $tags = $2;
                  next;
                } else {
                  if ($1 eq 'aka') {
                    if ($type ne 'person') {
                      die "only people can have aka fields\n";
                    }
                    @aka = split /;/, $2;
                    next;
                  }
                }
              }
            }
          }
        }
      }

      die "don't understand this header line - $line\n";
    }
  }

  $item->subject($subject);
  $item->author($author);
  if (defined $image) {
    $item->image($image);
    $item->image_position($image_position);
  }
  $item->text($text);
  $item->post($post);
  $item->aka(\@aka);
  $item->tags([split /,\w*/, $tags]);

  return $item;
}

=head1 AUTHOR

Kim Rutherford <webmaster@labourservative.org.uk>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
