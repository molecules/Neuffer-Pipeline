use 5.008;    # Require at least Perl version 5.8
use strict;   # Must declare all variables before using them
use warnings; # Emit helpful warnings
use autodie;  # Fatal exceptions for common unrecoverable errors (e.g. w/open)

# Testing-related modules
use Test::More;                  # provide testing functions (e.g. is, like)
use Test::LongString;            # Compare strings byte by byte
use Data::Section -setup;        # Set up labeled DATA sections
use File::Temp  qw( tempfile );  #
use File::Slurp qw( slurp    );  # Read a file into a string

# Distribution-specific modules
use lib 'lib';              # add 'lib' to @INC
$ENV{TESTING}=1;
{
    my $input_filename  = filename_for('input');
    my $output_filename = temp_filename();
    system("perl lib/Neuffer/Pipeline.pm --infile $input_filename --config $ENV{HOME}/.dokuwiki.mutantdb > $output_filename");
    my $result   = slurp $output_filename;
    my $expected = string_from('expected');
    is( $result, $expected, 'successfully extracted phenotype names and page names' );

    # Remove the subset directory
    system('rm -rf subset pages index_of_phenotypes.txt');
}


done_testing();

sub sref_from {
    my $section = shift;

    #Scalar reference to the section text
    return __PACKAGE__->section_data($section);
}

sub string_from {
    my $section = shift;

    #Get the scalar reference
    my $sref = sref_from($section);

    #Return a string containing the entire section
    return ${$sref};
}

sub fh_from {
    my $section = shift;
    my $sref    = sref_from($section);

    #Create filehandle to the referenced scalar
    open( my $fh, '<', $sref );
    return $fh;
}

sub assign_filename_for {
    my $filename = shift;
    my $section  = shift;

    # Don't overwrite existing file
    die "'$filename' already exists." if -e $filename;

    my $string   = string_from($section);
    open(my $fh, '>', $filename);
    print {$fh} $string;
    close $fh;
    return;
}

sub filename_for {
    my $section           = shift;
    my ( $fh, $filename ) = tempfile();
    my $string            = string_from($section);
    print {$fh} $string;
    close $fh;
    return $filename;
}

sub temp_filename {
    my ($fh, $filename) = tempfile();
    close $fh;
    return $filename;
}

sub delete_temp_file {
    my $filename  = shift;
    my $delete_ok = unlink $filename;
    ok($delete_ok, "deleted temp file '$filename'");
}

#------------------------------------------------------------------------
# IMPORTANT!
#
# Each line from each section automatically ends with a newline character
#------------------------------------------------------------------------

__DATA__
__[ input ]__
2286A			Indeterminate structure and flower timing and dwarfing phenotypes depending on response to daylength.	indeterminate dwarf:  A Semi-dwarf indeterminate idd1-N2286A mutant plant, on left, expressing slow growth associated with the GA responding anther ear type dwarfing aspect of this mutant.	Research Images\maize\WalMart CDs\5207-1613-1040\5207-1613-1040-61.jpg	1
2286A			Indeterminate structure and flower timing and dwarfing phenotypes depending on response to daylength.	indeterminate dwarf:  A tall green idd1-2286A M2 mutant plant growing in a normal long day Missouri field 100 days after planting showing many short nodes (andromonoecious  dwarf aspect) the bottom 18 of which are senescent and the top which are green and just beginning to develop floral parts. Indeterminate structure and flower timing and dwarfing phenotypes depending on response to daylength.  With long days plant is intermediate vegetative dwarf, that continues to grow until taller than matured normal sibs.  With short day the tassel node proliferates to produce multiple leaves rootlets and fertile tassel branches.	Research Images\maize\WalMart CDs\7099-3173-2501\7099-3173-2501-34.jpg	2
0399B	abt	test aberrant seedling	flat glossy irregular first leaf and rolled bent talon-like second leaf.	aberrant seedling:  Two tiny glossy abt*-N399B F2 mutant seedlings showing broad flat glossy irregular first leaf and rolled bent talon-like second leaf	Research Images\maize\WalMart CDs\5207-1613-1042\5207-1613-1042-1.jpg	
0712B	abt	test aberrant seedling	palegreen glossy distorted seedling with flat first leaf and rolled hooked second leaf.	aberrant seedling:  F2 seedling progeny segregating for abt*-N712B seedlings, showing pale green glossy flat primitive first leaf and tightly rolled second leaf	Research Images\maize\WalMart CDs\5207-1613-1042\5207-1613-1042-11.jpg	
0712B	abt	test aberrant seedling	palegreen glossy distorted seedling with flat first leaf and rolled hooked second leaf.	aberrant seedling:  Two abt*-N712B seedlings (on left) from origin M2 progeny, showing variations in phenotype, and normal sib. Middle seedling shows typical flat first leaf and rolled hooked second leaf.	Research Images\maize\WalMart CDs\5207-1613-1042\5207-1613-1042-10.jpg	
0595B	abt	test aberrant seedling	Small round flat first leaf and tightly rolled bent second leaf, and lighter green color	aberrant seedling:  abt*-N595B M2 seedling on left, showing small round flat first leaf and tightly rolled bent second leaf, and lighter green color	Research Images\maize\WalMart CDs\5207-1613-1042\5207-1613-1042-7.jpg	
G089	K10	test abnormal 10/Knob	Euchromatic appendage carrying a large heterochromatic knob; causes preferential transmission of chromosome and linked genes from heterozygote.	Knobbed appendage to chromosome 10:  Microphoto of pollen mother cell at pachytene showing chromosome 10 with the large K10 appendage (Rhoades 1952).	Research Images\maize\WalMart CDs\7101-3161-2580\7101-3161-2580-32.jpg	
G089	K10	test abnormal 10/Knob	Euchromatic appendage carrying a large heterochromatic knob; causes preferential transmission of chromosome and linked genes from heterozygote.	Knobbed appendage to chromosome 10; preferential female transmission:  backcross ears show preferential female transmission of the R1 alleles linked to the abnormal 10. Top ear from R1-K/r1-k, lower ear from R1-k/r1-K, females by r1-r1 male.	Research Images\maize\WalMart CDs\7101-3161-2580\7101-3161-2580-33.jpg	
0194	ad	test adherent	Seedling distortion caused by tightly rolled first 3 leaves adhering at leaf tip or along midrib.	adherent leaf:  An ad*-N194 mutant seedling from M2 origin progeny, showing seedling distortion caused by tightly rolled first 3 leaves adhering at leaf tip.	Research Images\maize\WalMart CDs\5207-1613-1042\5207-1613-1042-19.jpg	4
G005	ad1	test adherent	seedling leaves, tassel branches, and occasionally top leaves adhere causing distorted growth pattern	adherent leaf: An ad1 mutant seedling showing distortion caused by adherence of first two leaves.	Research Images\maize\WalMart CDs\7099-3173-2501\7099-3173-2501-40.jpg	11
__[ expected ]__
test aberrant seedling	test_aberrant_seedling
test abnormal 10 knob	test_abnormal_10_knob
test adherent	test_adherent
