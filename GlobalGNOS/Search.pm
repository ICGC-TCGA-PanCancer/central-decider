package GlobalGNOS::Search;

use strict;
use warnings;

use autodie;
use Carp::Always;

use feature qw(say);

use Search::Elasticsearch;
use JSON;

use Data::Dumper;

sub new {
    my ($class, $elasticsearch_url, $workflow_name, $gnos_repo) = @_;
    my $self = {
                 elasticsearch_url => $elasticsearch_url,
                 workflow_name => $workflow_name,
                 gnos_repo => $gnos_repo
               };
    return bless $self, $class;
}

sub get_donors_for_variant_calling {
    my ($self, $query_donors, $filter_donors, $training_set_two, $aligned ) = @_;
    my $es_query = {
      "filter" => {
         "bool" => {
            "must_not" => [
               {
                  "terms" => {
                     "flags.is_donor_blacklisted" => [
                        "T"
                     ]
                  }
               },
               {
                  "terms" => {
                     "flags.is_manual_qc_failed" => [
                        "T"
                     ]
                  }
               }
            ],
            "must" => [ 
               {
                 "terms" => {
                     "flags.are_all_tumor_specimens_aligned" => [
                             "T"
                     ]
                 }
              }
            ]
          }
        }
    };

    my $term;
    if (%{$filter_donors}) {
        $term = {
                     "terms" => { 
                               "donor_unique_id" => $filter_donors
                     }
                };
        push  $es_query->{filter}{bool}{"must_not"}, $term;
    }

    if ($query_donors->[0] =~ /^\d+$/) {
         $es_query->{from} = 0;
         $es_query->{size} = $query_donors->[0];
    }
    else {
        $term = {
                   "terms" => {
                         "_id" => $query_donors
                   }       
                };
        push $es_query->{filter}{bool}{must}, $term;
    }

    if ($self->{workflow_name} eq 'SangerPancancerCgpCnIndelSnvStr') {
        $term = {
                      "terms" => {
                          "flags.is_sanger_variant_calling_performed" => [
                                "F"
                          ]
                      }       
                };
        push $es_query->{filter}{bool}{must}, $term;
    }
    elsif ($self->{workflow_name} eq 'DEWrapperWorkflow') {
        $term = {
                       "terms" => {
                            "flags.is_german_variant_calling_performed" => [
                                   "F"
                             ]
                       }       
                   };
        push $es_query->{filter}{bool}{must}, $term;
    }
    else {
        die 'Incorrect workflow_name';
    }

    if ($training_set_two) {
        $term = {
                    "terms" => {
                          "flags.is_train2_donor" => [
                                 "T"
                           ]
                     }       
                };
        push $es_query->{filter}{bool}{must}, $term;
    }

    if ($self->{gnos_repo}) {
        $term = {
                     "terms" => {
                          "gnos_repos_with_complete_alignment_set" => [
                                 "$self->{gnos_repo}"
                           ]
                     }       
                };
        push $es_query->{filter}{bool}{must}, $term;
    }

    my $query_json = to_json($es_query);
    my $command = 'curl -XGET "'.$self->{elasticsearch_url}."_search?pretty\" -d \'".$query_json."\'";

    my $results_json = `$command`;
    my $results = from_json($results_json);
    my @donor_sources = $results->{hits}{hits};
    my %donors;
    foreach my $donor_source (@donor_sources) {
        foreach my $donor (@{$donor_source}) {
           $donors{$donor->{_id}} = $donor->{_source} if ($donor->{_type} eq 'donor');
        }
    }

    return \%donors;
}

sub get_aligned_sets {
    my ($self, $query_donors, $filter_donors, $training_set_two ) = @_;

    my $aligned = 1;
    my $donors = get_donors_for_variant_calling($self, $query_donors, $filter_donors, $training_set_two, $aligned);

    my %aligned_sets;
    foreach my $donor_id (keys %{$donors}) {
        my $tumour_specimen = $donors->{$donor_id}{aligned_tumor_specimens};
        my $normal_specimen = $donors->{$donor_id}{normal_specimen};
        $aligned_sets{$donor_id} = { aligned_tumor_specimens => $tumour_specimen,
                                     normal_specimen         => $normal_specimen };
    }

    return \%aligned_sets;
}

sub get_unaligned_donors {
    my ($self, $query_donors, $filter_donors, $training_set_two, $analysis_id ) = @_;

    my $aligned = 1;
    my $donors = get_donors_for_variant_calling($self, $query_donors, $filter_donors, $training_set_two, $aligned);

    my %unaligned_sets;
    foreach my $donor_id (keys %{$donors}) {
        my $tumour_specimen = $donors->{$donor_id}{aligned_tumor_specimens};
        my $normal_specimen = $donors->{$donor_id}{normal_specimen};
        $unaligned_sets{$analysis_id} = { aligned_tumor_specimens => $tumour_specimen,
                                     normal_specimen         => $normal_specimen };
    }

    return \%unaligned_sets;
}


1;
