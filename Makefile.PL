###############################################################################
#
# This is the MakeMaker skeleton for the RPC-XML extension. Besides the usual
# tricks, this has to add rules to make the *.xpl files from *.code in the
# methods/ subdir, as well as get them into a place where they get installed
# correctly.
#
###############################################################################
use ExtUtils::MakeMaker;
use File::Spec;
use File::Find;

my ($vol, $dir, undef) = File::Spec->splitpath(File::Spec->rel2abs($0));
$dir                   = File::Spec->catpath($vol, $dir, '');

eval "require XML::LibXML;";
if ($@)
{
    print STDERR <<END;
@@@@@
        XML::LibXML not found

        You may ignore the warnings about XML::LibXML not being present, if
        you plan only to use the XML::Parser-based parsing engine. The use
        of XML::LibXML is completely optional.
@@@@@

END
}

$CLEAN = 'pod2html-* *.html *.spec *.rpm rpmrc rpmmacro *.log t/*.log ' .
    't/*.pid META.yml META.json MYMETA.yml MYMETA.json *.ppd cover_db ';

@scripts = (File::Spec->catfile(qw(etc make_method)));
$CLEAN  .= File::Spec->catfile(qw(methods *.xpl));

@PM_FILES = ();

find(sub { push(@PM_FILES, $File::Find::name) if (-f $_ and /\.pm$/) }, 'lib');

# Exclude Apache2 stuff until it's ready for deployment
@PM_FILES = grep(! /Apache2/, @PM_FILES);

%PM_FILES = map { ($temp = $_) =~ s|^lib|\$\(INST_LIB\)|; $_ => $temp }
    @PM_FILES;
# Handle the method code in "methods" specially:
find(sub {
         if (-f $_ and /\.base$/)
         {
             s/\.base$//;
             $PM_FILES{File::Spec->catfile('methods', "$_.xpl")} =
                 File::Spec->catfile('$(INST_LIB)', 'RPC', 'XML', "$_.xpl");
         }
     }, 'methods');
# Anything stuck under "lib" is more generic
find(sub {
         if (-f $_ and /\.base$/)
         {
             $File::Find::name =~ s/base$/xpl/;
             ($tmp = $File::Find::name) =~ s|^lib|\$(INST_LIB)|;
             $PM_FILES{$File::Find::name} = $tmp;
             $CLEAN .= " $File::Find::name";
         }
     }, 'lib');

WriteMakefile(
    NAME      => 'RPC::XML',
    VERSION   => '0.78',
    AUTHOR    => 'Randy J. Ray',
    ABSTRACT  => 'Data, client and server classes for XML-RPC',
    EXE_FILES => \@scripts,
    PM        => \%PM_FILES,
    PREREQ_PM => {
        'File::Spec'   => 0.8,
        'constant'     => 1.03,
        'Scalar::Util' => 1.19,
        'Test::More'   => 0.94,
        'LWP'          => 5.834,
        'XML::Parser'  => 2.31,
        'Module::Load' => 0.24,
    },
    dist      => { COMPRESS => 'gzip -9f' },
    clean     => { FILES => $CLEAN },
    LICENSE   => 'perl',
    MIN_PERL_VERSION => 5.008008,
    META_MERGE => {
        recommends => {
            'XML::LibXML'               => '1.85',
            'DateTime'                  => '0.70',
            'DateTime::Format::ISO8601' => '0.07',
            'Compress::Raw::Zlib'       => '2.063',
        },
        resources => {
            homepage   => 'http://search.cpan.org/dist/RPC-XML',
            bugtracker =>
            'http://rt.cpan.org/Public/Dist/Display.html?Name=RPC-XML',
            repository => 'http://github.com/rjray/rpc-xml',
        }
    },
);

sub MY::post_initialize
{
    my $self = shift;

    my @text;
    my $makemeth = File::Spec->catfile(qw(etc make_method));

    push(@text,
         '.SUFFIXES: .xpl .base',
         '',
         '.base.xpl:',
         "\t\$(PERL) $makemeth --base=\$*",
         '');
    join("\n", @text);
}

sub MY::postamble
{
    my $self = shift;

    my @text;
    my $makemeth = File::Spec->catfile(qw(etc make_method));

    # Create the dependancy rules for the methods/XPL files
    for (sort grep(/\.xpl$/, keys %::PM_FILES))
    {
        s/\.xpl$//;
        push(@text, "$_.xpl: $_.base $_.help $_.code $makemeth");
    }

    join("\n", @text);
}
