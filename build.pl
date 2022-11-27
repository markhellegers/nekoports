#!/usr/bin/perl

use File::Path qw(mkpath rmtree);
use File::Copy;
use Cwd;

print "Starting build\n";

sub build_port {
	my (@port) = @_;
	my $port_path = @port[0];
	my $port_recipe = @port[1];

	# Save current directory to get the recipe data
	my $nekoports_dir = getcwd;

	my $nekoports_build_dir = "/var/tmp/nekoports/build/$port_path";
	my $nekoports_install_dir = "/var/tmp/nekoports/install/$port_path";
	my $nekoports_recipe_path = "$nekoports_dir/$port_path/$port_recipe";
	my $source_uri;
	my $system_result;
	my %environment_variables;

	# Open the recipe file and read all the interesting data
	open(RECIPE, $nekoports_recipe_path) or die "Unable to open recipe at $nekoports_recipe_path";
	my $line;
	while ($line = <RECIPE>) {
		chomp($line);
		if ($line =~ /^SOURCE_URI/) {
			my @line_fields = split(/=/, $line);
			$source_uri = @line_fields[1];
			# Strip the quotes from the uri
			$source_uri =~ s/\"//g;
		}
		elsif ($line =~ /^ENVIRONMENT/) {
			# Read the next lines until we reach the end quote character
			# and put the results in a hash
			$line = <RECIPE>;
			chomp($line);
			until ($line eq '"') {
				my @line_fields = split(/\s/, $line, 2);
				my $env_variable = @line_fields[0];
				my $env_value = @line_fields[1];
				# Strip the quotes from the value
				$env_value =~ s/\'//g;
				$environment_variables{$env_variable} = $env_value;
				$line = <RECIPE>;
				chomp($line);
			}

		}
	}
	close RECIPE;

	print "Clearing existing data\n";
	rmtree($nekoports_build_dir);
	rmtree($nekoports_install_dir);

	print "Creating directories\n";

	mkpath($nekoports_build_dir);
	mkpath($nekoports_install_dir);

	chdir $nekoports_build_dir;

	print "Downloading source\n";
	# Assuming everything after the last / is the filename
	my @source_uri_fields = split(/\//, $source_uri);
	my $source_filename = @source_uri_fields[-1];
	$system_result = system("curl $source_uri > $source_filename");
	if ($system_result) {
		die "Failed to download file from $source_uri";
	}

	print "Unpacking source\n";
	$system_result = system("gunzip -dc $source_filename | tar xf -");
	if ($system_result) {
		die "Failed to unpack file $source_filename";
	}

	my $source_dir = $source_filename;
	$source_dir =~ s/\.tar\.gz//;
	chdir $source_dir;

	print "Initializing repository\n";
	$system_result = system("git init -q");
	if ($system_result == 0) {
		$system_result = system("git add .");
		if ($system_result == 0) {
			$system_result = system('git commit -m "Initial commit" -q');
		}
	}
	if ($system_result) {
		die "Failed to initialize repository";
	}

	print "Applying patch\n";
	my $patch_file = "$nekoports_dir/$port_path/patches/$source_dir.patch";
	$system_result = system("git am $patch_file -q");
	if ($system_result) {
		die "Failed to apply patch";
	}

	print "Setting up environment\n";
	foreach $key (keys %environment_variables)
	{
		$ENV{$key} = $environment_variables{$key};
	}

	print "Configuring source\n";
	$system_result = system("./configure --prefix=/usr/nekoware");
	if ($system_result) {
		die "Failed to configure";
	}

	print "Building source\n";
	$system_result = system("gmake");
	if ($system_result) {
		die "Failed to build";
	}

	print "Installing in temporary directory\n";
	$system_result = system("gmake DESTDIR=$nekoports_install_dir install");
	if ($system_result) {
		die "Failed to install";
	}

	print "Creating distribution directories\n";
	$nekoports_install_dir = "$nekoports_install_dir/usr/nekoware";
	mkpath("$nekoports_install_dir/patches");
	mkpath("$nekoports_install_dir/src");
	mkpath("$nekoports_install_dir/relnotes");
	mkpath("$nekoports_install_dir/dist");

	print "Copying files to distribution directory\n";
	my $nekoports_relnotes_path = $nekoports_recipe_path;
	$nekoports_relnotes_path =~ s/recipe/relnotes/g;
	copy($patch_file, "$nekoports_install_dir/patches") or die "Failed to copy patch $patch_file to $nekoports_install_dir/patches";
	copy($source_filename, "$nekoports_install_dir/src") or die "Failed to copy source $source_filename to $nekoports_install_dir/src";
	copy($nekoports_relnotes_path, "$nekoports_install_dir/relnotes") or die "Failed to copy source $nekoports_relnotes_path to $nekoports_install_dir/relnotes";

	print "Done!\n";
}

print "Building port of bash\n";
build_port("app-shells/bash", "bash-5.1.16.recipe");
