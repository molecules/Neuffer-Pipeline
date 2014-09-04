#!/bin/env perl
package Neuffer::Pipeline;
# ABSTRACT: Eventually this should be able to go from MutantDB dump to posted pages on MaizeGDB without intervention 

#=============================================================================
# STANDARD MODULES AND PRAGMAS
use 5.010;    # Require at least Perl version 5.10
use strict;   # Must declare all variables before using them
use warnings; # Emit helpful warnings
use autodie;  # Fatal exceptions for common unrecoverable errors (e.g. open)
use Getopt::Long::Descriptive; # Parse @ARGV as command line flags and arguments
use Carp qw( croak );   # Throw errors from calling function

use Neuffer::RenderPhenoGroupWikiPage;


#=============================================================================
# CONSTANTS

# Boolean
my $TRUE =1;
my $FALSE=0;
my $TESTING = $ENV{TESTING}//$FALSE;

# String
my $SPACE        = q{ };
my $SINGLE_QUOTE = q{'};
my $SPACE_RE     = qr{ };
my $UNDERSCORE   = q{_};

my @REQUIRED_FLAGS = qw( config);

# DEFAULTS
my $DEFAULT_PAGE_DIR       = 'pages';
my $DEFAULT_SUBSET_DIR     = 'subset';
my $DEFAULT_INPUT_FILENAME = 'mutantdb_dump.txt';

# CONSTANTS
#=============================================================================

#=============================================================================
# COMMAND LINE

# Run as a command-line program if not used as a module
main(@ARGV) if !caller();

sub main {

    #-------------------------------------------------------------------------
    # COMMAND LINE INTERFACE                                                 #
    #                                                                        #
    my ( $opt, $usage ) = describe_options(
        '%c %o <some-arg>',
        [ 'infile|i=s',  "mutantDB \"dump file\" (defaults to $DEFAULT_INPUT_FILENAME)", ],
        [ 'config=s', "configuration filename", ],
        [],
        [ 'help', 'print usage message and exit' ],
    );

    my $exit_with_usage = sub {
        print "\nUSAGE:\n";
        print $usage->text();
        exit();
    };

    # If requested, give usage information regardless of other options
    $exit_with_usage->() if $opt->help;

    # Make some flags required
    my $missing_required = $FALSE;
    for my $flag (@REQUIRED_FLAGS) {
        if ( !defined $opt->$flag ) {
            print "Missing required option '$flag'\n";
            $missing_required = $TRUE;
        }
    }

    # Exit with usage statement if any required flags are missing
    $exit_with_usage->() if $missing_required;

    #                                                                        #
    # COMMAND LINE INTERFACE                                                 #
    #-------------------------------------------------------------------------

    #-------------------------------------------------------------------------
    #                                                                        #
    #                                                                        #

    my $input_filename = $opt->infile // $DEFAULT_INPUT_FILENAME;

    open( my $fh_in,  '<', $input_filename );

    process( {
                fh_in  => $fh_in,
                config => $opt->config,
             },
    );

    close $fh_in;

    return;

    #                                                                        #
    #                                                                        #
    #-------------------------------------------------------------------------
}

# COMMAND LINE
#=============================================================================

#=============================================================================
#

sub process {
    my ($arg_ref) = @_;

    # Create the subset directory
    my $subset_dir = $DEFAULT_SUBSET_DIR;
    mkdir $subset_dir;

    # Get filehandle for input file
    my $fh_in  = $arg_ref->{fh_in };

    # Create paralell hashes that contain page names and their corresponding filehandles
    my %fh_for;
    my %page_name_for;

    # Split the original input file into files specific to a separate web page
    while(my $line = readline $fh_in){
        
        # Remove newline character
        chomp $line;

        # Get value in third column
        my ($phenotype_name) = (split /\t/, $line)[2]; 

        # Skip blank lines
        next if $phenotype_name =~ /\A \s* \z/xms;

        # Replace nonword characters with spaces
        my $clean_phenotype_name = clean_name($phenotype_name);
        
        # Replace internal spaces with underscores
        my $page_name = name_with_underscores($clean_phenotype_name); 

        # Store page name to possibly be reused later
        $page_name_for{$clean_phenotype_name} = $page_name;

        if( ! exists $fh_for{$page_name}){
            open($fh_for{$page_name}, '>', subfolder_filename_for($subset_dir,$page_name) );
        }

        # Write out this line to the appropriate file  
        $fh_for{$page_name}->say($line);
    }

    # Create a directory for holding the page files
    my $page_dir = $DEFAULT_PAGE_DIR;
    mkdir $page_dir;

    # Create a wiki page for each phenotype name 
    my @page_names;
    for my $phenotype_name (sort {$a cmp $b} keys %page_name_for){
        my $page_name = $page_name_for{$phenotype_name};
        say "$phenotype_name\t$page_name";
        my $infile = subfolder_filename_for($subset_dir, $page_name);
        my $outfile = "$page_dir/$page_name.txt";
        system("run_perl_module 'Neuffer::RenderPhenoGroupWikiPage' --infile $infile --outfile $outfile");

        # Store page names
        push @page_names, $page_name;
    }

    close $fh_for{$_} for keys %fh_for;

    # Post resulting pages (unless this is a test). In reality we should
    #   create a mock database so that it could be fully tested.
    if(! $TESTING){
        my $config_filename = $arg_ref->{config};

        # Create string containing all of the page names
        my $post_wiki_list = $SINGLE_QUOTE
                           . join($SPACE,@page_names)
                           . $SINGLE_QUOTE;
        chdir $page_dir;
        system("run_perl_module Neuffer::PostWiki --put $post_wiki_list --config $config_filename");
        chdir '..';
        system("run_perl_module Neuffer::PostWiki --put 'info:index_of_phenotypes' --config $config_filename");
    }

    return \%page_name_for;
}

sub subfolder_filename_for {
    my ($dir, $page_name) = @_;
    return "$dir/$page_name.txt";
}

sub clean_name {
    my $name    = shift;

    # make all lowercase
    my $clean_name = lc $name;

    # Replace all nonword characters (or groups of characters) with space
    $clean_name =~ s/\W+/$SPACE/xmsg;

    # Remove trailing spaces
    $clean_name =~ s/$SPACE_RE+\z//xms;

    return $clean_name;
}

sub name_with_underscores {
    my $name = shift;

    $name =~s/$SPACE/$UNDERSCORE/g;
    return $name;
}
#
#=============================================================================

#-----------------------------------------------------------------------------

1;  #Modules must return a true value
=pod


=head1 SYNOPSIS

    perl Neuffer/Pipeline.pm --infile input_filename --config dokuwiki.config

=head1 DEPENDENCIES

    Getopt::Long::Descriptive
    Neuffer::RenderPhenoGroupWikiPage

=head1 INCOMPATIBILITIES

    Only tested on Linux systems.

=head1 BUGS AND LIMITATIONS

     There are no known bugs in this module.
     Please report problems to the author.
     Patches are welcome.
