package Workflow::VCF;

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
   my ($class, $donor) = @_;

   my @donors_run_parameters;
   foreach my $es_donor_id (keys %{$donor}) {
       my $donor_info = $donor->{$es_donor_id};
       my ($project_code, $donor_id) = split '::', $es_donor_id;
       my $control_analysis_id = $donor_info->{normal_alignment_status}{aligned_bam}{gnos_id};
       my $control_bam = $donor_info->{normal_alignment_status}{aligned_bam}{bam_file_name};

       my (@tumour_analysis_ids,@tumour_bams, @tumour_aliquot_ids);

       my $tumour; 
       foreach $tumour (@{$donor_info->{tumor_alignment_status}}) {              
            push @tumour_analysis_ids, $tumour->{aligned_bam}{gnos_id};
            push @tumour_bams, $tumour->{aligned_bam}{bam_file_name};
            push @tumour_aliquot_ids, $tumour->{aliquot_id};
       } 
  
       my %run_parameters = ( donor_id => $donor_id,
                              project_code => $project_code,
                              tumourAliquotIds =>  join(',', @tumour_aliquot_ids),
                              tumourAnalysisId => join(',', @tumour_analysis_ids),
                              tumourBams => join(',', @tumour_bams),
                              controlAnalysisId => $control_analysis_id,
                              controlBam => $control_bam,
                            );
       push @donors_run_parameters, \%run_parameters;
   }

   return \@donors_run_parameters;
}


1;
