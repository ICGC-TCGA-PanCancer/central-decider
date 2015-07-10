#!/usr/bin/env perl

use strict;
use warnings;

use feature 'say';

use autodie qw(:all);
use IPC::System::Simple;

use Capture::Tiny ':all';

my $repo_dir = "/home/ubuntu/git";

say "\nCHECK: Does $repo_dir exists";
if (-d $repo_dir) {
    say "CONCLUSION: $repo_dir exists";
}
else {
    die "CONCLUSION: $repo_dir does not exist";
}

$repo_dir = $1 if($repo_dir=~/(.*)\/$/); # remove trailing slash if exists
my $repo_path = "$repo_dir/pcawg-operations";

say "\nCHECK: Does $repo_path exist";
if (-d $repo_path) {
    say "CONCLUSION: $repo_path exists";
}
else {
    say "CONCLUSION: $repo_path does not exist... cloning repo";
    `cd $repo_dir; git clone https://github.com/ICGC-TCGA-PanCancer/pcawg-operations.git;`
}

say 'Fetching tags from GitHub';
`cd $repo_path; git fetch --tags`;

say 'Finding latest tag';
my $stdout;
my ($latest_tag, $stderr) = capture {
   system("cd $repo_path; git describe --tags `git rev-list --tags --max-count=1`")
};
chomp $latest_tag;

say "Latest tag is $latest_tag";

say 'Checking out latest tag';

`cd $repo_path; git checkout $latest_tag`;
