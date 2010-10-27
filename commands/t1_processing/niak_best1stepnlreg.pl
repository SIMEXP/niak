#! /usr/bin/env perl
#
# non-linear fitting using parameters optimised by Steve Robbins,
# using a brain mask for the source and the target.
#
# Claude Lepage - claude@bic.mni.mcgill.ca
# Andrew Janke - rotor@cmr.uq.edu.au
# Center for Magnetic Resonance
# The University of Queensland
# http://www.cmr.uq.edu.au/~rotor
#
# Copyright Andrew Janke, The University of Queensland.
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose and without fee is hereby granted,
# provided that the above copyright notice appear in all copies.  The
# author and the University of Queensland make no representations about the
# suitability of this software for any purpose.  It is provided "as is"
# without express or implied warranty.

use strict;
use warnings "all";
use Getopt::Tabular;
use File::Basename;
use File::Temp qw/ tempdir /;

# default minctracc parameters
my @def_minctracc_args = (
#   '-debug',
   '-clobber',
   '-nonlinear', 'corrcoeff',
   '-weight', 1,
   '-stiffness', 0.75,
   '-similarity', 0.3,
   '-sub_lattice', 6,
   );

my @conf = (

  {'step'         => 32,
   'blur_fwhm'    => 16,
   'iterations'   => 20,
   },

  {'step'         => 16,
   'blur_fwhm'    => 8,
   'iterations'   => 20,
   },

  {'step'         => 12,
   'blur_fwhm'    => 6,
   'iterations'   => 20,
   },

  {'step'         => 8,
   'blur_fwhm'    => 4,
   'iterations'   => 20,
   },

  {'step'         => 6,
   'blur_fwhm'    => 3,
   'iterations'   => 20,
   },

  {'step'         => 4,
   'blur_fwhm'    => 2,
   'iterations'   => 10,
   },
  
   );

my($Help, $Usage, $me);
my(@opt_table, %opt, $source, $target, $outxfm, $outfile, @args, $tmpdir);

$me = &basename($0);
%opt = (
   'verbose'   => 0,
   'clobber'   => 0,
   'fake'      => 0,
   'normalize' => 0,
   'init_xfm'  => undef,
   'source_mask' => undef,
   'target_mask' => undef,
   );

$Help = <<HELP;
| $me does hierachial non-linear fitting between two files
|    you will have to edit the script itself to modify the
|    fitting levels themselves
| 
| Problems or comments should be sent to: rotor\@cmr.uq.edu.au
HELP

$Usage = "Usage: $me [options] source.mnc target.mnc output.xfm [output.mnc]\n".
         "       $me -help to list options\n\n";

@opt_table = (
   ["-verbose", "boolean", 0, \$opt{verbose},
      "be verbose" ],
   ["-clobber", "boolean", 0, \$opt{clobber},
      "clobber existing check files" ],
   ["-fake", "boolean", 0, \$opt{fake},
      "do a dry run, (echo cmds only)" ],
   ["-normalize", "boolean", 0, \$opt{normalize},
      "do intensity normalization on source to match intensity of target" ],
   ["-init_xfm", "string", 1, \$opt{init_xfm},
      "initial transformation (default identity)" ],
   ["-source_mask", "string", 1, \$opt{source_mask},
      "source mask to use during fitting" ],
   ["-target_mask", "string", 1, \$opt{target_mask},
      "target mask to use during fitting" ],
   );

# Check arguments
&Getopt::Tabular::SetHelp($Help, $Usage);
&GetOptions (\@opt_table, \@ARGV) || exit 1;
die $Usage if(! ($#ARGV == 2 || $#ARGV == 3));
$source = shift(@ARGV);
$target = shift(@ARGV);
$outxfm = shift(@ARGV);
$outfile = (defined($ARGV[0])) ? shift(@ARGV) : undef;

# check for files
die "$me: Couldn't find input file: $source\n\n" if (!-e $source);
die "$me: Couldn't find input file: $target\n\n" if (!-e $target);
if(-e $outxfm && !$opt{clobber}){
   die "$me: $outxfm exists, -clobber to overwrite\n\n";
   }
if(defined($outfile) && -e $outfile && !$opt{clobber}){
   die "$me: $outfile exists, -clobber to overwrite\n\n";
   }

my $mask_warning = 0;
if( !defined($opt{source_mask}) ) {
  $mask_warning = 1;
} else {
  if( !-e $opt{source_mask} ) {
    $mask_warning = 1;
  }
}
if( !defined($opt{target_mask}) ) {
  $mask_warning = 1;
} else {
  if( !-e $opt{target_mask} ) {
    $mask_warning = 1;
  }
}
if( $mask_warning == 1 ) {
  print "Warning: For optimal results, you should use masking.\n";
  print "$Usage";
}

# make tmpdir
$tmpdir = &tempdir( "$me-XXXXXXXX", TMPDIR => 1, CLEANUP => 1 );

# set up filename base
my($i, $s_base, $t_base, $tmp_xfm, $tmp_source, $tmp_target, $prev_xfm);
$s_base = &basename($source);
$s_base =~ s/\.mnc(.gz)?$//;
$s_base = "S${s_base}";
$t_base = &basename($target);
$t_base =~ s/\.mnc(.gz)?$//;
$t_base = "T${t_base}";

# Run inormalize if required. minctracc likes it better when the
# intensities of the source and target are similar, but honestly
# this step may be completely useless in CIVET. (Must make sure
# that source and target are sampled in the same way - only needed
# by inormalize but not for minctracc).

my $original_source = $source;
if( $opt{normalize} ) {
  my $inorm_source = "$tmpdir/${s_base}_inorm.mnc";
  my $inorm_target = "$tmpdir/${t_base}_inorm.mnc";
  &do_cmd( "mincresample", "-clobber", "-like", $source, $target, $inorm_target );
  &do_cmd( 'inormalize', '-clobber', '-model', $inorm_target, $source, $inorm_source );
  $source = $inorm_source;
}

# mask the images only once.
if( defined($opt{source_mask}) and defined($opt{target_mask}) ) {
  my $source_masked = "$tmpdir/${s_base}_masked.mnc";
  &do_cmd( 'minccalc', '-clobber',
           '-expression', 'if(A[1]>0.5){out=A[0];}else{out=A[1];}',
           $source, $opt{source_mask}, $source_masked );
  $source = $source_masked;

  my $target_masked = "$tmpdir/${t_base}_masked.mnc";
  &do_cmd( 'minccalc', '-clobber',
           '-expression', 'if(A[1]>0.5){out=A[0];}else{out=A[1];}',
           $target, $opt{target_mask}, $target_masked );
  $target = $target_masked;
}


# a fitting we shall go...
for ($i=0; $i<=$#conf; $i++){

   # remove blurred image at previous iteration, if no longer needed.
   if( $i > 0 ) {
     if( $conf[$i]{blur_fwhm} != $conf[$i-1]{blur_fwhm} ) {
       unlink( "$tmp_source\_blur.mnc" ) if( -e "$tmp_source\_blur.mnc" );
       unlink( "$tmp_target\_blur.mnc" ) if( -e "$tmp_target\_blur.mnc" );
     }
   }
   
   # set up intermediate files
   $tmp_xfm = "$tmpdir/$s_base\_$i.xfm";
   $tmp_source = "$tmpdir/$s_base\_$conf[$i]{blur_fwhm}";
   $tmp_target = "$tmpdir/$t_base\_$conf[$i]{blur_fwhm}";
   
   print STDOUT "-+-[$i]\n".
                " | step:           $conf[$i]{step}\n".
                " | blur_fwhm:      $conf[$i]{blur_fwhm}\n".
                " | iterations:     $conf[$i]{iterations}\n".
                " | source:         $tmp_source\n".
                " | target:         $tmp_target\n".
                " | xfm:            $tmp_xfm\n".
                "\n";
   
   # blur the source and target files if required.
   if(!-e "$tmp_source\_blur.mnc"){
      &do_cmd('mincblur', '-no_apodize', '-fwhm', $conf[$i]{blur_fwhm},
              $source, $tmp_source);
   }
   if(!-e "$tmp_target\_blur.mnc"){
      &do_cmd('mincblur', '-no_apodize', '-fwhm', $conf[$i]{blur_fwhm},
              $target, $tmp_target);
   }
   
   # set up registration
   @args = ('minctracc',  @def_minctracc_args,
            '-iterations', $conf[$i]{iterations},
            '-step', $conf[$i]{step}, $conf[$i]{step}, $conf[$i]{step},
            '-lattice_diam', $conf[$i]{step} * 3, 
                             $conf[$i]{step} * 3, 
                             $conf[$i]{step} * 3);
   
   # transformation
   if($i == 0) {
      push(@args, (defined $opt{init_xfm}) ? ('-transformation', $opt{init_xfm}) : '-identity')
   } else {
      push(@args, '-transformation', $prev_xfm);
   }

   # masks (even if the blurred image is masked, it's still preferable
   # to use the mask in minctracc)
   if( defined($opt{source_mask}) and defined($opt{target_mask}) ) {
     push(@args, '-source_mask', $opt{source_mask} );
     push(@args, '-model_mask', $opt{target_mask} );
   }
   
   # add files and run registration
   push(@args, "$tmp_source\_blur.mnc", "$tmp_target\_blur.mnc", 
        ($i == $#conf) ? $outxfm : $tmp_xfm);
   &do_cmd(@args);
  
   # remove previous xfm to keep tmpdir usage to a minimum.
   # (could also remove the previous blurred images).

   if($i > 0) {
     unlink( $prev_xfm );
     $prev_xfm =~ s/\.xfm/_grid_0.mnc/;
     unlink( $prev_xfm );
   }

   # define starting xfm for next iteration. 

   $prev_xfm = ($i == $#conf) ? $outxfm : $tmp_xfm;
}

# resample if required
if(defined($outfile)){
   print STDOUT "-+- creating $outfile using $outxfm\n".
   &do_cmd('mincresample', '-clobber', '-like', $target,
           '-transformation', $outxfm, $original_source, $outfile);
}


sub do_cmd { 
   print STDOUT "@_\n" if $opt{verbose};
   if(!$opt{fake}){
      system(@_) == 0 or die;
   }
}
       
