package LabServ::Photos;

use warnings;
use strict;

use LabServ;
use LabServ::Config;

use Image::Magick;

sub make_thumb
{
  my $class = shift;
  my $source_file = shift;
  my $dest_file = shift;

  my $image = Image::Magick->new;
  my $ret_code = $image->Read($source_file);
  warn "$ret_code" if "$ret_code";

  $ret_code = $image->Thumbnail(geometry=>LabServ::Config->gallery_image_size());
  warn "$ret_code" if "$ret_code";

  $ret_code = $image->Write($dest_file);
  warn "$ret_code" if "$ret_code";
}

1;
