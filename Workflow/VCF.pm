package Workflow::VCF;

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
   my ($self, $donor, $local_file_dir) = @_;
  
   my ($upload_gnos_url, $download_key, $upload_key, $gnos_repo);
   if ($self->{download_gnos_repo} eq 'https://cghub.ucsc.edu/') {
        $download_key = 'cghub';
        $upload_key = 'TCGA';
        $upload_gnos_url = 'https://gtrepo-osdc-tcga.annailabs.com/';
   }
   else {
        $download_key = 'ICGC';
        $upload_key = 'ICGC';
        $upload_gnos_url =  $self->{download_gnos_repo};
   }

   my @donors_run_parameters;
   foreach my $es_donor_id (keys %{$donor}) {
       my $donor_info = $donor->{$es_donor_id};
       my ($project_code, $donor_id) = split '::', $es_donor_id;
       my $control_analysis_id = $donor_info->{normal_alignment_status}{aligned_bam}{gnos_id};
       my $control_bam;
       if ($local_file_dir) {
           $control_bam = $local_file_dir.$control_analysis_id.'/'.$donor_info->{normal_alignment_status}{aligned_bam}{bam_file_name};
       }
       else {
           $control_bam = $donor_info->{normal_alignment_status}{aligned_bam}{bam_file_name}; 
       }
       my (@tumour_analysis_ids,@tumour_bams, @tumour_aliquot_ids);

       my $tumour; 
       foreach $tumour (@{$donor_info->{tumor_alignment_status}}) {              
            push @tumour_analysis_ids, $tumour->{aligned_bam}{gnos_id};
            if ($local_file_dir) {
                push @tumour_bams, $local_file_dir.$tumour->{aligned_bam}{gnos_id}.'/'.$tumour->{aligned_bam}{bam_file_name};
            }
            else {
                push @tumour_bams, $tumour->{aligned_bam}{bam_file_name};
            }

            push @tumour_aliquot_ids, $tumour->{aliquot_id};
       } 
  
       my %run_parameters = ( donor_id            => $donor_id,
                              project_code        => $project_code,
                              workflow_name       => $self->{workflow_name},
                              tumour_aliquot_ids  => join(',', @tumour_aliquot_ids),
                              tumour_analysis_ids => join(',', @tumour_analysis_ids),
                              tumour_bams         => join(',', @tumour_bams),
                              control_analysis_id => $control_analysis_id,
                              control_bam         => $control_bam,
                              upload_gnos_url     => $upload_gnos_url,
                              upload_gnos_key     => $upload_key,
                              download_gnos_url   => $self->{download_gnos_repo},
                              download_gnos_key   => $download_key
                            );
       push @donors_run_parameters, \%run_parameters;
   }

   return \@donors_run_parameters;
}


1;
