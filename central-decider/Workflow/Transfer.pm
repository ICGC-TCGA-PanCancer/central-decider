package Workflow::Transfer;

use strict;
use warnings;

use feature qw(say);

use IPC::System::Simple;
use autodie qw(:all);
use Carp::Always;

use Data::Dumper;

sub new {
    my $class = shift;

    my $self = bless {
                      workflow_name       => $_[0],
                      download_gnos_repo  => $_[1]
                     }, $class;

    return $self;
}

sub generate_run_parameters {
   my ($self, $donor) = @_;
  
   # need to add checks based on flags to only include files that are not already in S3
   my @donors_run_parameters;
   foreach my $es_donor_id (keys %{$donor}) {
       my @gnos_repos;
       my @analysis_ids;

       my $donor_info = $donor->{$es_donor_id};
       my ($project_code, $donor_id) = split '::', $es_donor_id;

       my $control_bam_analysis_id = $donor_info->{normal_alignment_status}{aligned_bam}{gnos_id};
       if ($control_bam_analysis_id) {
            my @array = @{$donor_info->{normal_alignment_status}{aligned_bam}{gnos_repo}};
 #           my $gnos_repos = join('|', @{$donor_info->{normal_alignment_status}{aligned_bam}{gnos_repo}});
            my $gnos_repos = $donor_info->{normal_alignment_status}{aligned_bam}{gnos_repo}[0];
            push @gnos_repos, $gnos_repos;
            push @analysis_ids, $control_bam_analysis_id;
       }

       my $tumour; 
       foreach $tumour (@{$donor_info->{tumor_alignment_status}}) {
  #          my $gnos_repos = join('|', @{$tumour->{aligned_bam}{gnos_repo}});
            my $gnos_repos = $tumour->{aligned_bam}{gnos_repo}[0];
            push @gnos_repos, $gnos_repos;
            push @analysis_ids, $tumour->{aligned_bam}{gnos_id};
       } 
  
       if (defined $donor_info->{variant_calling_results}{sanger_variant_calling}) {
 #           my $gnos_repos = join('|', @{$donor_info->{variant_calling_results}{sanger_variant_calling}{gnos_repo}}); This should be used if you want to make logic on the client side of what repo to use
            my $gnos_repos = $donor_info->{variant_calling_results}{sanger_variant_calling}{gnos_repo}[0];
            push @gnos_repos, $gnos_repos;
            push @analysis_ids,  $donor_info->{variant_calling_results}{sanger_variant_calling}{gnos_id};
       }

       my %run_parameters = ( donor_id            => $donor_id,
                              project_code        => $project_code,
                              gnos_repos          => join(',', @gnos_repos),
                              analysis_ids        => join(',', @analysis_ids)
                            );

       push @donors_run_parameters, \%run_parameters;
   }

   return \@donors_run_parameters;
}


1;
