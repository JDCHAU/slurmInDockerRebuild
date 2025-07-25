use 5.008;
use ExtUtils::MakeMaker;


# Most all the extra code is to deal with MakeMaker < 6.11 not working
# correctly to build rpms

my(
   $mm_version,
   $mm_knows_destdir,
   $mm_has_destdir,
   $mm_has_good_destdir,
   $mm_needs_destdir,
   );

# Gather some information about what EU::MM offers and/or needs

# Store the version for later use
$mm_version          = $ExtUtils::MakeMaker::VERSION;

# MakeMaker prior to 6.11 doesn't support DESTDIR which is needed for
# packaging with builddir!=destdir. See bug 2388.
$mm_knows_destdir    = $ExtUtils::MakeMaker::Recognized_Att_Keys{DESTDIR};
$mm_has_good_destdir = $mm_version >= 6.11;
# Add DESTDIR hack only if it's requested (and necessary)
$mm_needs_destdir    = !$mm_has_good_destdir;
$mm_has_destdir      = $mm_knows_destdir || $mm_needs_destdir;
$ExtUtils::MakeMaker::Recognized_Att_Keys{"DESTDIR"} = 1 if $mm_needs_destdir;

if ($mm_needs_destdir) {
	my $error = <<DESTDIR_HACK;

    ***********************************************************************
    ExtUtils::MakeMaker ${mm_version} does not include support for DESTDIR,
    so if you want to be on the safe side, you might want to upgrade your
    ExtUtils::MakeMaker to version 6.11 or later. It is available via CPAN.

    You can use either the CPAN shell or go to
      <http://search.cpan.org/search?module=ExtUtils::MakeMaker>
    to get an up-to-date version.

    This should only be necessary if you are creating binary packages.
    ***********************************************************************

DESTDIR_HACK
       $error =~ s/^ {4}//gm;
       warn $error;
} elsif (!$mm_has_good_destdir) {
	my $error = <<DESTDIR_BUG;

    ***********************************************************************
    ExtUtils::MakeMaker ${mm_version} contains bugs that may cause problems
    in the \"make\" process.  It is recommended that you upgrade
    ExtUtils::MakeMaker to version 6.11 or later. It is available via CPAN.

    You can use either the CPAN shell or go to
      <http://search.cpan.org/search?module=ExtUtils::MakeMaker>
    to get an up-to-date version.

    This should only be necessary if you are creating binary packages.
    ***********************************************************************

DESTDIR_BUG
       $error =~ s/^ {4}//gm;
       warn $error;
}

# AIX has problems with not always having the correct
# flags so we have to add some :)
my $os = lc(`uname`);
my $other_ld_flags = '-Wl,-rpath,../../../../src/db_api/.libs -Wl,-rpath,${prefix}/lib/x86_64-linux-gnu';
$other_ld_flags = " -brtl -G -bnoentry -bgcbypass:1000 -bexpfull"
	if $os =~ "aix";

# Define .inc files to clean up as default behavior
# misses them when generating Makefile
my @inc_clean_files = qw(const-c.inc const-xs.inc);

WriteMakefile(
    NAME              => 'Slurmdb',
    VERSION_FROM      => 'Slurmdb.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'Slurmdb.pm', # retrieve abstract from module
       AUTHOR         => 'Don Lipari <lipari@llnl.gov>') : ()),
    LIBS              => ['-L../../../../src/api/.libs -L${prefix}/lib/x86_64-linux-gnu -lslurm'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => "-I. -I../../../../.. -I../../../../../contribs/perlapi/common -I../../../..",
    # Un-comment this if you add C files to link with later:
    OBJECT            => '$(O_FILES)', # link all the C files too
    CCFLAGS           => '-g',
    dynamic_lib       => {'OTHERLDFLAGS' => $other_ld_flags},
    #Custom cleanup behavior to clear .inc files
    clean		=> {FILES => join(' ', @inc_clean_files)},
);

if  (eval {require ExtUtils::Constant; 1}) {
	# If you edit these definitions to change the constants used by this module,
	# you will need to use the generated const-c.inc and const-xs.inc
	# files to replace their "fallback" counterparts before distributing your
	# changes.
	my @names = (qw(SLURMDB_CLASSIFIED_FLAG
		 SLURMDB_CLASS_BASE SLURMDB_PURGE_ARCHIVE SLURMDB_PURGE_BASE
		 SLURMDB_PURGE_DAYS SLURMDB_PURGE_FLAGS SLURMDB_PURGE_HOURS
		 SLURMDB_PURGE_MONTHS),
		);
	ExtUtils::Constant::WriteConstants(
		NAME         => 'Slurmdb',
		NAMES        => \@names,
		C_FILE       => 'const-c.inc',
		XS_FILE      => 'const-xs.inc',
		);
}

# Override the install routine to add our additional install dirs and
# hack DESTDIR support into old EU::MMs.
sub MY::install {
	package MY;
	my $self = shift;
	my @code = split(/\n/, $self->SUPER::install(@_));
	init_MY_globals($self);

	foreach (@code) {
		# Write the correct path to perllocal.pod
		next if /installed into/;

		# Replace all other $(INSTALL*) vars (except $(INSTALLDIRS) of course)
		# with their $(DESTINSTALL*) counterparts
		s/\Q$(\E(INSTALL(?!DIRS)${MACRO_RE})\Q)\E/\$(DEST$1)/g;
	 }

	 clean_MY_globals($self);
	 return join("\n", @code);
}

# Now override the constants routine to add our own macros.
sub MY::constants {
	package MY;
	my $self = shift;
	my @code = split(/\n/, $self->SUPER::constants(@_));
	init_MY_globals($self);

	foreach my $line (@code) {
		# Skip comments
		next if $line =~ /^\s*\#/;
		# Skip everything which isn't a var assignment.
		next unless line_has_macro_def($line);

		#tore the assignment string if necessary.
		set_EQ_from_line($line);

		# Add some "dummy" (PERL|SITE|VENDOR)PREFIX macros for later use (only if
		# necessary for old EU::MMs of course)
		if (line_has_macro_def($line, 'PREFIX')) {
			foreach my $r (@REPOSITORIES) {
				my $rprefix = "${r}PREFIX";

				if (!defined(get_macro($rprefix))) {
					set_macro($rprefix, macro_ref('PREFIX'));
					$line .= "\n" . macro_def($rprefix);
				}
			}
		}

 		# fix problem with /usr(/local) being used as a prefix
		# instead of the real thing.

		if ($line =~ 'INSTALL') {
			$line =~ s/= \/usr\/local/= \$(PREFIX)/;
			$line =~ s/= \/usr/= \$(PREFIX)/;
		}

		# Add DESTDIR support if necessary
		if (line_has_macro_def($line, 'INSTALLDIRS')) {
			if(!get_macro('DESTDIR')) {
				$line .= "\n" . macro_def('DESTDIR');
			}
		} elsif (line_has_macro_def($line,
					    qr/INSTALL${MACRO_RE}/)) {
			my $macro = get_macro_name_from_line($line);
			if(!get_macro('DEST' . $macro,
				      macro_ref('DESTDIR')
				      . macro_ref($macro))) {
				$line .= "\n"
					. macro_def('DEST' . $macro,
						    macro_ref('DESTDIR')
						    . macro_ref($macro));
			}
		}
	}
	push(@code, qq{});

	clean_MY_globals($self);
	return join("\n", @code);
}


package MY;

use vars qw(
  @REPOSITORIES

  $MY_GLOBALS_ARE_SANE

  $MACRO_RE
  $EQ_RE
  $EQ

  $SELF
);


sub line_has_macro_def {
	my($line, $name) = (@_, undef);
	$name = $MACRO_RE unless defined $name;

	return $line =~ /^($name)${EQ_RE}/;
}


sub macro_def {
	my($name, $val) = (@_, undef);
	my $error_message = "Problems building report error.";

	die $error_message  unless defined $name;
	die $error_message  unless defined $EQ;
	$val = $SELF->{$name} unless defined $val;

	return $name . $EQ . $val;
}

sub set_EQ_from_line {
	my($line) = (@_);

	return if defined($EQ);

	$line =~ /\S(${EQ_RE})/;
	$EQ = $1;
}

# Reads the name of the macro defined on the given line.
#
# The first parameter must be the line to be expected. If the line doesn't
# contain a macro definition, weird things may happen. So check with
# line_has_macro_def() before!
sub get_macro_name_from_line {
	my($line) = (@_);

	$line =~ /^(${MACRO_RE})${EQ_RE}/;
	return $1;
}

sub macro_ref {
	my($name) = (@_);

	return sprintf('$(%s)', $name);
}

# Reads the value of the given macro from the current instance of EU::MM.
#
# The first parameter must be the name of a macro.
sub get_macro {
	my($name) = (@_);

	return $SELF->{$name};
}

# Sets the value of the macro with the given name to the given value in the
# current instance of EU::MM. Just sets, doesn't write to the Makefile!
#
# The first parameter must be the macro's name, the second the value.
sub set_macro {
	my($name, $val) = (@_);

	$SELF->{$name} = $val;
}

# For some reason initializing the vars on the global scope doesn't work;
# guess its some weird Perl behavior in combination with bless().
sub init_MY_globals {
	my $self = shift;

	# Keep a reference to ourselves so we don't have to feed it to the helper
	# scripts.
	$SELF = $self;

	return if $MY_GLOBALS_ARE_SANE;

	$MY_GLOBALS_ARE_SANE = 1;

	@REPOSITORIES = qw(
			   PERL
			   SITE
			   VENDOR
			   );

	# Macro names follow this RE -- at least stricly enough for our purposes.
	$MACRO_RE = qr/[A-Z0-9_]+/;
	# Normally macros are assigned via FOO = bar. But the part with the equal
	# sign might differ from platform to platform. So we use this RE:
	$EQ_RE = qr/\s*:?=\s*/;
	# To assign or own macros we'll follow the first assignment string we find;
	# normally " = ".
	$EQ = undef;

}

# Unset $SELF to avoid any leaking memory.
sub clean_MY_globals {
	my $self = shift;

	$SELF = undef;
}
