#!/usr/bin/env perl

# SPDX-License-Identifier: MIT

use 5.030000;
use strict;
use warnings;
use Carp;

use Compress::Zlib ;
use MIME::Base64;
use JSON::PP;

my $VERSION = '1.0';
my $SCRIPT = ($0 =~ /.*\/([^\/]+)$/)[0];

sub decode_bp {
    my $pretty_print = shift;
    # Make sure there's going to be something to do
    unless (@ARGV) {
        say "Error: No file(s) given";
        say "Type '",($0 =~ /\/([^\/]+)$/)[0]," help' for options.\n";
        return;
    }
    my ($dest_file, $dest_name, $src_file, $src_name);
    # Determine the names to use for in and out files
    # First argument (after command options) is the input filename
    $src_name = $ARGV[0];
    $src_file = '';
    # Accept any filename. If it isn't found try a few options:
    # Filenames which end with a period signal that the name w/o the period
    # are to be used without adding any extensions. If a file _is_ found that
    # _does_ end with a period, it will be valid, otherwise the period is stripped
    # and that is the name to use, regardless of success.
    # Otherwise, because it's common for text editors, and file downloads, to add
    # the txt extension, that will be tried as a fallback (upper and lower case to
    # cover Windows and Linux).
    if (-r $src_name) {
        $src_file = $src_name;
    } elsif ( -r $src_name . ".txt" ) {
        $src_file = $src_name . '.txt'
    } elsif ( -r $src_name . ".TXT" ) {
        $src_file = $src_name . '.TXT'
    } elsif ( ($src_name =~ /^(.*)\.$/) and -r $1 ) {
        $src_file = $1;
    } else {
        say "Error: No source data found\n";
        return;
    }
    # The next argument, if present, is the filename to save. Again, a final period
    # forces the use of the given name without an extension added (and without that
    # final period being included in the name. Otherwise, unless the name already has
    # the .json extension, it is added to the given name. Oddly enough, by using two
    # periods at the end, it is possible to force the creation of a file 'name.' anyway.
    # Again, the existence of a 'name.JSON' file is not always the same as a 'name.json'
    # file. Testing for both in the name input will prevent the creation of a 'name.json'
    # when the user enters 'name.JSON', or worse 'name.JSON.json'. It does not, however,
    # prevent the program from creating 'name.json' in a Linux directory with 'name.JSON'
    # alread present.
    if (defined $ARGV[1] ) {
        $dest_name = $ARGV[1];
        if ($dest_name !~ /\./) {
            $dest_file = $dest_name . '.json';
        } elsif ($dest_name =~ /(.*)\.$/) {
            $dest_file = $1;
        } elsif ($dest_name =~ /\.json$/i) {
            $dest_file = $dest_name;
        } else {
            $dest_file = $dest_name . '.json';
        }
    } else {
    # If there is no output filename given, it's created from the input filename.
    # Simply by stipping the final period, or .txt from the input name and appending
    # '.json'. In this case, even if the input ends with a period, the extension will
    # still be added. Otherwise it would be an attempt to replace the file, which is
    # not going to be allowed. This is intended for use inside a script and prompting
    # the user for permission would interrupt the flow of the script.
        $dest_file = ($src_file =~ /^(.*?)\.?(txt)?$/i)[0] . '.json';
    }
    if ( -e $dest_file) {
        say "Error: $dest_file already exists, not overwriting.\n";
        return;
    }
    
    # Attempt to open the files. Should not be any problem as readability was tested
    # when checking the source name and existing files checked for when making the 
    # output name. However, the system state could change between the testing and the
    # opening, or the directory could be read-only, which was not tested for. If either
    # file cannot be opened, it's a fatal error.
    die "Cannot open $src_file for reading"
        unless open INFILE, "<$src_file";
    die "Cannot open $dest_file for output"
        unless open OUTFILE, ">$dest_file";
    # Force binary data on both files. (UTF-8 for the JSON sometimes messes with systems
    # and the inbetween state of the unencoded blueprint string _is_ binary.
    binmode INFILE;
    binmode OUTFILE;
    my ($input, $json_data, $output, $raw_data, $status, $zlib);

    # Open a stream to zlib inflation, fatal error if not possible
    $zlib = inflateInit()
        or die "Cannot create a inflation stream\n" ;
    $raw_data = '' ;
    # Stip the "version byte" from the blueprint string
    read(INFILE, $raw_data, 1);
    # Slurp in the rest of the string and close the file
    chomp ($raw_data = <INFILE>);
    # Reverse the Wube process of making the string
    # Decode the base64, giving the compressed string
    $input = decode_base64($raw_data);
    # Inflate the string, giving minimized JSON string
    ($json_data, $status) = $zlib->inflate(\$input) ;
    die "inflation failed\n"
        unless $status == Z_STREAM_END ;
    unless ($pretty_print == 1) {
        # Keep the JSON as a single string for machine processing
        $output = $json_data
    } else  {
        # Convert it to something readable by humans
        $output = JSON::PP->new->utf8->pretty->encode (decode_json $json_data);
    }
    print OUTFILE $output;
    close OUTFILE;
}

sub encode_bp {
    # Make sure there's going to be something to do
    unless (@ARGV) {
        say "Error: No file(s) given";
        say "Type '",($0 =~ /\/([^\/]+)$/)[0]," help' for options.\n";
        return;
    }
    my ($dest_file, $dest_name, $src_file, $src_name);
    # Determine the names to use for in and out files
    # First argument (after command options) is the input filename
    $src_name = $ARGV[0];
    $src_file = '';
    # Accept any filename. If it isn't found try a few options:
    # Filenames which end with a period signal that the name w/o the period
    # are to be used without adding any extensions. If a file _is_ found that
    # _does_ end with a period, it will be valid, otherwise the period is stripped
    # and that is the name to use, regardless of success. The decoding creates a
    # .json file, and because it's common for text editors, and file downloads, to add
    # the json extension, that will be tried as a fallback (upper and lower case to
    # cover Windows and Linux).
    if (-r $src_name) {
        $src_file = $src_name;
    } elsif ( -r $src_name . ".json" ) {
        $src_file = $src_name . '.json'
    } elsif ( -r $src_name . ".JSON" ) {
        $src_file = $src_name . '.JSON'
    } elsif ( ($src_name =~ /^(.*)\.$/) and -r $1 ) {
        $src_file = $1;
    } else {
        say "Error: No source data found\n";
        return;
    }
    # The next argument, if present, is the filename to save. Again, a final period
    # forces the use of the given name without an extension added (and without that
    # final period being included in the name. Otherwise, unless the name already has
    # the .txt extension, it is added to the given name. Oddly enough, by using two
    # periods at the end, it is possible to force the creation of a file 'name.' anyway.
    # Again, the existence of a 'name.TXT' file is not always the same as a 'name.txt'
    # file. Testing for both in the name input will prevent the creation of a 'name.txt'
    # when the user enters 'name.TXT', or worse 'name.TXT.txt'. It does not, however,
    # prevent the program from creating 'name.txt' in a Linux directory with 'name.TXT'
    # alread present.
    if (defined $ARGV[1] ) {
        $dest_name = $ARGV[1];
        if ($dest_name !~ /\./) {
            $dest_file = $dest_name . '.txt';
        } elsif ($dest_name =~ /(.*)\.$/) {
            $dest_file = $1;
        } elsif ($dest_name =~ /\.txt$/i) {
            $dest_file = $dest_name;
        } else {
            $dest_file = $dest_name . '.txt';
        }
    } else {
    # If there is no output filename given, it's created from the input filename.
    # Simply by stipping the final period, or .json from the input name and appending
    # '.txt'. In this case, even if the input ends with a period, the extension will
    # still be added. Otherwise it would be an attempt to replace the file, which is
    # not going to be allowed. This is intended for use inside a script and prompting
    # the user for permission would interrupt the flow of the script.
        $dest_file = ($src_file =~ /^(.*?)\.?(json)?$/i)[0] . '.txt';
    }
    if ( -e $dest_file) {
        say "Error: $dest_file already exists, not overwriting.\n";
        return;
    }
    # Attempt to open the files. Should not be any problem as readability was tested
    # when checking the source name and existing files checked for when making the 
    # output name. However, the system state could change between the testing and the
    # opening, or the directory could be read-only, which was not tested for. If either
    # file cannot be opened, it's a fatal error.
    die "Cannot open $src_file for reading"
        unless open INFILE, "<$src_file";
    die "Cannot open $dest_file for output"
        unless open OUTFILE, ">$dest_file";
    # Force binary data on both files. (UTF-8 for the JSON sometimes messes with systems
    # and the inbetween state of the unencoded blueprint string _is_ binary.
    binmode INFILE;
    binmode OUTFILE;
    my ($json_data, $json_string, $output, $raw_data, $status, $tail_data, $zlib);

    # Open a stream to zlib deflation, fatal error if not possible
    $zlib = deflateInit()
        or die "Cannot create a deflation stream\n" ;
    # Load the JSON file
    chomp ($json_string = <INFILE>);
    close INFILE;
    # Force it into minified format
    $json_data = JSON->new->utf8->encode (decode_json $json_string);
    # Compress it with zlib to level 9
    ($raw_data, $status) = $zlib->deflate($json_data, Z_BEST_COMPRESSION);
    $status == Z_OK
        or die "deflation failed\n" ;
    ($tail_data, $status) = $zlib->flush() ;
    $status == Z_OK
        or die "deflation failed\n" ;
    $raw_data .= $tail_data;
    # Encode it in base64
    $output = encode_base64($raw_data, '');
    # Add the Wube version byte;
    $output = "0" . $output;
    # Save it
    print OUTFILE $output;
    close OUTFILE;
}

sub show_help {
    my $report = <<EOR;

    Factorio Bluprint Conversions version $VERSION

        $SCRIPT <cmd> [<opt>] <infile> [<outfile>]
        
        <cmd> is 
            decode|read|open: convert bp_string to JSON
            encode|write|
            save|make:        convert JSON to bp_string
            version|ver:      show the version information
            help|?:           show this informatoin
        <opt> is
            -p  cause the JSON from decode to be pretty printed.
            Will cause an error for encode.
            
        <infile> must exist.
        <outfile> must not exist.
            If omitted, the filename for <outfile> is created by
            adding .json to the <infile> filename
            
        For more information read the README on GitHub at
        https://github.com/chindraba-work/Facatorio-Blueprint-Conversions

EOR
    print $report
}

sub show_version {
    my $report = <<EOR;

    Factorio Bluprint Conversions version $VERSION
    Copyright © 2022 Chindraba <projects\@chindraba.work>

    A program to convert between Factorio blueprint strings and the JSON
    data they contain.

    For discussions, requests, and bug reports use the features on GitHub
    https://github.com/chindraba-work/Facatorio-Blueprint-Conversions

    For help type "$SCRIPT help"

EOR
    print $report;
}

sub main {
    # Check for a cammand to execute. Options are:
    # "decode"|"encode"|"help"|"make"|"open"|"read"|"save"|"write"|"version"
    # open and read  an alias for decode
    # make, save and write are aliases for encode
    # help is hopefully helpful
    unless (@ARGV) {
        say "Error: No command given.";
        say "Type '",($0 =~ /\/([^\/]+)$/)[0]," help' for options.\n";
        return;
    }
    #say Dumper \@ARGV;
    if ($ARGV[0] =~ /^((--)?help|-h|h|\?)$/i) {
        show_help();
    } elsif ($ARGV[0] =~ /^((--)?ver|version|-v|v)$/i) {
        show_version();
    } elsif ($ARGV[0] =~ /^(((--)?(make|write|save|encode))|((-)?(m|w|s|e)))$/i) {
        shift @ARGV;
        encode_bp();
    } elsif ($ARGV[0] =~ /^(((--)?(read|open|decode))|((-)?(r|o|d|c)))$/i) {
        my $format_json = 0;
        shift @ARGV;
        if (defined $ARGV[0] && $ARGV[0] =~ /^-p$/i) {
            $format_json = 1;
            shift @ARGV;
        }
        decode_bp($format_json);
    } else {
        say "Error: Invalid command: '",$ARGV[0],"' given.";
        say "Type '",($0 =~ /\/([^\/]+)$/)[0]," help' for options.\n";
        return;
    }
}

main();

1;
__END__

=head1 NAME

Perl program to convert between Wube data and JSON data

=head1 SYNOPSIS

  $ factorio-blueprint-reader.pl decode -p wube.txt wube.json
  $ factorio-blueprint-reader.pl encode my-print.json my-print.txt

=head1 DESCRIPTION

Read the contents of a file with a Factorio blueprint export string.
Write a file with the JSON data of the string.

Read the contents of a JSON data file. Write a blueprint export string
to a text file.

=head2 EXPORT

None.

=head1 AUTHOR

Chindraba, E<lt>projects@chindraba.workE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright © 2019, 2020  Chindraba (Ronald Lamoreaux)
                  <projects@chindraba.work>
- All Rights Reserved

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use, copy,
modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
# Vim: syntax=perl ts=4 sts=4 sw=4 et sr:
