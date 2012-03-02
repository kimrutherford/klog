package LabServ::Image;

use warnings;
use strict;

use LabServ::Config;

use Image::Magick;

sub img
{
  my $class = shift;
  my $item = shift;
  my $image_at_top = shift;
  my $use_thumbnail = shift;

  my $image = $item->image();
  my $image_position = $item->image_position();
  if (defined $image && defined $image_position) {
    my $class = "";
    if (!$image_at_top) {
      $class = "graphic ${image_position}pic";
    }
    my $pic_loc;
    if ($use_thumbnail) {
      $pic_loc = 'thumbs';
    } else {
      $pic_loc = 'img';
    }

    my $pic_path = "$pic_loc/$image";


    my $image = Image::Magick->new;
    my $ret_code = $image->Read('../' . LabServ::Config->destination_dir() . '/' . $pic_path);
    warn "$ret_code" if "$ret_code";

    my $width = $image->Get('width');
    my $height = $image->Get('height');

    print "<img src='$pic_path' class='$class' width='$width' height='$height' />\n";
  }
}

1;
