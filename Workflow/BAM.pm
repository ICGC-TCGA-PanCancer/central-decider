package Workflow::BAM;

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
                      workflow_name => $_[0],
                     }, $class;
    return $self;
}

sub generate_run_parameters {
   my ($class, $donor, $local_file_dir) = @_;

   my @donors_run_parameters;
   foreach my $es_donor_id (keys %{$donor}) {
       my $donor_info = $donor->{$es_donor_id};
       my ($project_code, $donor_id) = split '::', $es_donor_id;

       my $normal_alignment_status = $donor_info->{normal_alignment_status};

       if (($normal_alignment_status->{aligned} eq 'false') 
           && ($normal_alignment_status->{do_lane_count_and_bam_count_match} eq 'true') 
           && ($normal_alignment_status->{do_lane_counts_in_every_bam_entry_match} eq 'true')) {
            my $aliquot_id            = $normal_alignment_status->{aliquot_id};
            my $dcc_specimen_type     = $normal_alignment_status->{dcc_specimen_type};
            my $submitter_sample_id   = $normal_alignment_status->{submitter_sample_id};
            my $submitter_specimen_id = $normal_alignment_status->{submitter_specimen_id};

            my (@gnos_input_file_urls, @input_bam_paths, @gnos_metadata_urls);
            foreach my $bam (@{ $normal_alignment_status->{unaligned_bams} }) {
                push @gnos_input_file_urls, $bam->{gnos_repo}[0]."cghub/data/analysis/download/".$bam->{gnos_id};
                push @gnos_metadata_urls,   $bam->{gnos_repo}[0]."cghub/metadata/analysisFull/".$bam->{gnos_id};
                if ($local_file_dir) {
                    push @input_bam_paths,      $local_file_dir.$bam->{gnos_id}.'/'.$bam->{bam_file_name};
                }
                else {
                    push @input_bam_paths,      $bam->{gnos_id}.'/'.$bam->{bam_file_name};
                }
            }

            push @donors_run_parameters,  { donor_id                    => $donor_id,
                                           project_code                => $project_code,
                                           sample_type                 => "normal",
                                           dcc_specimen_type           => $dcc_specimen_type,
                                           submitter_sample_id         => $submitter_sample_id,
                                           submitter_specimen_id       => $submitter_specimen_id,
                                           aliquot_id                  => $aliquot_id,
                                           gnos_input_file_urls        => join(',', @gnos_input_file_urls),
                                           gnos_input_metadata_urls    => join(',', @gnos_metadata_urls),
                                           input_bam_paths             => join(',', @input_bam_paths),
                                         };
       }

       my $tumour_alignment_status = $donor_info->{tumor_alignment_status};

       my @gnos_input_file_urls = '';
       my @input_bam_paths = '';
       foreach my $tumour (@{$tumour_alignment_status}) {
            if (($tumour->{do_lane_count_and_bam_count_match} eq 'true') 
              && ($tumour->{do_lane_counts_in_every_bam_entry_match} eq 'true')
              && ($tumour->{aligned} eq 'false')) {
    
                my $dcc_specimen_type     = $tumour->{dcc_specimen_type};
                my $submitter_sample_id   = $tumour->{submitter_sample_id};
                my $submitter_specimen_id = $tumour->{submitter_specimen_id};
                my $aliquot_id            = $tumour->{aliquot_id};   
    
                my (@gnos_input_file_urls, @gnos_metadata_urls, @input_bam_paths);
                foreach my $bam (@{ $tumour->{unaligned_bams} }) {
                    push @gnos_input_file_urls, $bam->{gnos_repo}[0]."cghub/data/analysis/download/".$bam->{gnos_id};
                    push @gnos_metadata_urls,   $bam->{gnos_repo}[0]."cghub/metadata/analysisFull/".$bam->{gnos_id};
                    if ($local_file_dir) {
                        push @input_bam_paths, $local_file_dir.$bam->{gnos_id}.'/'.$bam->{bam_file_name};
                    }
                    else {
                        push @input_bam_paths, $bam->{gnos_id}.'/'.$bam->{bam_file_name};
                    }
                }

                my %run_parameters = ( donor_id                 => $donor_id,
                                       project_code             => $project_code,
                                       sample_type              => "tumour",
                                       dcc_specimen_type        => $dcc_specimen_type,
                                       submitter_sample_id      => $submitter_sample_id,
                                       submitter_specimen_id    => $submitter_specimen_id,
                                       aliquot_id               => $aliquot_id,
                                       gnos_input_file_urls     => join(',', @gnos_input_file_urls),
                                       gnos_input_metadata_urls => join(',', @gnos_metadata_urls),
                                       input_bam_paths          => join(',', @input_bam_paths)
                                     );

               push @donors_run_parameters, \%run_parameters;
           }
       }
   }

   return \@donors_run_parameters;
}


1;
