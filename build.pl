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
	my $nekoports_dist_dir = "/var/tmp/nekoports/dist/$port_path";
	my $nekoports_recipe_path = "$nekoports_dir/$port_path/$port_recipe";
	my $nekoports_port_and_version = $port_recipe;
	$nekoports_port_and_version =~ s/.recipe//;
	my @nekoports_port_fields = split(/-/, $nekoports_port_and_version);
	my $nekoports_port = @nekoports_port_fields[0];

	my $source_uri;
	my $source_filename;
	my $source_dir;
	my $system_result;
	my %environment_variables;
	my $configure_flags;
	my $make_flags;
	my $custom_makefile;
	my $skip_configure;

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
		elsif ($line =~ /^SOURCE_FILENAME/) {
			my @line_fields = split(/=/, $line);
			$source_filename = @line_fields[1];
			# Strip the quotes from the filename
			$source_filename =~ s/\"//g;
		}
		elsif ($line =~ /^SOURCE_DIR/) {
			my @line_fields = split(/=/, $line);
			$source_dir = @line_fields[1];
			# Strip the quotes from the filename
			$source_dir =~ s/\"//g;
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
		elsif ($line =~ /^CONFIGURE_FLAGS/) {
			my @line_fields = split(/=/, $line);
			$configure_flags = @line_fields[1];
			# Strip the quotes from the configure flags
			$configure_flags =~ s/\"//g;
		}
		elsif ($line =~ /^MAKE_FLAGS/) {
			my @line_fields = split(/=/, $line, 2);
			$make_flags = @line_fields[1];
			# Strip the quotes from the configure flags
			$make_flags =~ s/\"//g;
		}
		elsif ($line =~ /^CUSTOM_MAKEFILE/) {
			my @line_fields = split(/=/, $line);
			$custom_makefile = @line_fields[1];
			# Strip the quotes from the setting
			$custom_makefile =~ s/\"//g;
		}
		elsif ($line =~ /^SKIP_CONFIGURE/) {
			my @line_fields = split(/=/, $line);
			$skip_configure = @line_fields[1];
			# Strip the quotes from the setting
			$skip_configure =~ s/\"//g;
		}
	}
	close RECIPE;

	print "Clearing existing data\n";
	rmtree($nekoports_build_dir);
	rmtree($nekoports_install_dir);
	rmtree($nekoports_dist_dir);

	print "Creating directories\n";

	mkpath($nekoports_build_dir);
	mkpath($nekoports_install_dir);
	mkpath($nekoports_dist_dir);

	chdir $nekoports_build_dir;

	print "Downloading source\n";
	# Assuming everything after the last / is the filename
	my @source_uri_fields = split(/\//, $source_uri);
	if ($source_filename eq "")
	{
		# No specific filename speficied. Using name of the url
		$source_filename = @source_uri_fields[-1];
	}
	$system_result = system("curl -L $source_uri -o $source_filename");
	if ($system_result) {
		die "Failed to download file from $source_uri";
	}

	if ($source_filename =~ /tar.gz$/)
	{
		print "Unpacking source\n";
		$system_result = system("gunzip -dc $source_filename | tar xf -");
		if ($system_result) {
			die "Failed to unpack file $source_filename";
		}

		if ($source_dir eq "")
		{
			$source_dir = $source_filename;
			$source_dir =~ s/\.tar\.gz//;
		}
	}
	else {
		print "Creating source directory\n";
		mkpath("$nekoports_build_dir/$nekoports_port_and_version");
		$source_dir = $nekoports_port_and_version;
		copy($source_filename, $source_dir) or die "Failed to copy source $source_filename to $source_dir";
	}
	chdir $source_dir;

	if ($custom_makefile eq "1")
	{
		print "Copying custom makefile\n";
		copy("$nekoports_dir/$port_path/Makefile", "Makefile") or die "Failed to copy custom makefile $nekoports_dir/$port_path/Makefile to $source_dir";
		my $makefile_dir = "$nekoports_dir/$port_path/Makefile_files";
		if (-e $makefile_dir) {
			print "Copying custom makefile directory\n";
			$system_result = system("cp -R $makefile_dir $nekoports_build_dir/$nekoports_port_and_version");
			if ($system_result) {
				die "Failed to copy custom makefile directory $makefile_dir to $source_dir";
			}
		}
	}

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

	my $patch_file = "$nekoports_dir/$port_path/patches/$source_dir.patch";
	if (-e $patch_file) {
		print "Applying patch\n";
		$system_result = system("git am $patch_file -q");
		if ($system_result) {
			die "Failed to apply patch";
		}
	}
	else {
		print "No patch to apply\n";
	}

	print "Setting up environment\n";
	foreach $key (keys %environment_variables)
	{
		$ENV{$key} = $environment_variables{$key};
	}

	if (($custom_makefile ne "1") and ($skip_configure ne "1"))
	{
		print "Configuring source\n";
		$system_result = system("./configure --prefix=/usr/nekoware $configure_flags");
		if ($system_result) {
			die "Failed to configure";
		}
	}

	print "Building source\n";
	$system_result = system("gmake $make_flags");
	if ($system_result) {
		die "Failed to build";
	}

	print "Installing in temporary directory\n";
	$system_result = system("gmake DESTDIR=$nekoports_install_dir install $make_flags");
	if ($system_result) {
		die "Failed to install";
	}

	print "Creating distribution directories\n";
	my $nekoports_install_nekoware_dir = "$nekoports_install_dir/usr/nekoware";
	if (-e $patch_file) {
		mkpath("$nekoports_install_nekoware_dir/patches");
	}
	mkpath("$nekoports_install_nekoware_dir/src");
	mkpath("$nekoports_install_nekoware_dir/relnotes");
	mkpath("$nekoports_install_nekoware_dir/dist");

	print "Copying files to distribution directory\n";
	my $nekoports_source_file_path = "$nekoports_build_dir/$source_filename";
	my $nekoports_relnotes_path = $nekoports_recipe_path;
	$nekoports_relnotes_path =~ s/recipe/relnotes/g;
	my $nekoports_idb_path = "$nekoports_dir/$port_path/dist/neko_$nekoports_port.idb";
	my $nekoports_spec_path = "$nekoports_dir/$port_path/dist/neko_$nekoports_port.spec";
	if (-e $patch_file) {
		copy($patch_file, "$nekoports_install_nekoware_dir/patches") or die "Failed to copy patch $patch_file to $nekoports_install_nekoware_dir/patches";
	}
	copy($nekoports_source_file_path, "$nekoports_install_nekoware_dir/src") or die "Failed to copy source $source_filename to $nekoports_install_nekoware_dir/src";
	copy($nekoports_relnotes_path, "$nekoports_install_nekoware_dir/relnotes") or die "Failed to copy release notes $nekoports_relnotes_path to $nekoports_install_nekoware_dir/relnotes";
	copy($nekoports_idb_path, "$nekoports_install_nekoware_dir/dist") or die "Failed to copy idb file $nekoports_idb_path to $nekoports_install_nekoware_dir/dist";
	copy($nekoports_spec_path, "$nekoports_install_nekoware_dir/dist") or die "Failed to copy spec file $nekoports_spec_path to $nekoports_install_nekoware_dir/dist";

	print "Generating distribution\n";
	$system_result = system("gendist -sbase $nekoports_install_dir -idb $nekoports_dir/$port_path/dist/neko_$nekoports_port.idb -spec $nekoports_dir/$port_path/dist/neko_$nekoports_port.spec -dist $nekoports_dist_dir");
	if ($system_result) {
		die "Failed to generate distribution";
	}

	print "Creating package\n";
	chdir $nekoports_dist_dir;
	$system_result = system("tar -cvf neko_$nekoports_port_and_version.tardist *");
	if ($system_result) {
		die "Failed to createo package file neko_$nekoports_port_and_version.tardist";
	}

	print "Done!\n";
}

print "Building port of bash\n";
build_port("app-shells/bash", "bash-5.1.16.recipe");
print "Building port of less\n";
build_port("sys-apps/less", "less-608.recipe");
print "Building port of git\n";
build_port("dev-vcs/git", "git-2.36.0.recipe");
print "Building port of ca_root_certificates\n";
build_port("neko-data/ca_root_certificates", "ca_root_certificates-2022.10.11.recipe");
print "Building port of nedit\n";
build_port("app-editors/nedit", "nedit-5.7.recipe");
