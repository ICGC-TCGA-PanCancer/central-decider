package GlobalGNOS::Search;

use strict;
use warnings;

use autodie;
use Carp::Always;

use feature qw(say);

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

sub get_donors {
    my ($self, $query_donors, $filter_donors, $force, $number_of_donors) = @_;
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
                ]
          }
        }
    };

    my $term;
    if ($self->{workflow_name} eq 'Workflow_Bundle_BWA') {
         $term = [ {
                     "term" => {
                         "flags.are_all_tumor_specimens_aligned" => [
                             "F"
                          ]
                      }
                   },
                   {
                     "term" => {
                         "flags.is_normal_specimen_aligned" => [
                             "F"
                          ]
                      }
                   }
                ];
         push $es_query->{filter}{bool}{must}, {or => $term};

    } 
    elsif ($self->{workflow_name} eq 'Workflow_GNOS_to_S3') {
        $term =  {
                 "terms" => {
                     "flags.are_all_file_in_s3" => [
                             "T"
                     ]
                 }
              };
        push $es_query->{filter}{bool}{"must_not"}, $term;

    }
    else {
        $term =  {
                 "terms" => {
                     "flags.are_all_tumor_specimens_aligned" => [
                             "T"
                     ]
                 }
              };
        push $es_query->{filter}{bool}{must}, $term;
        $term =  {
                 "terms" => {
                     "flags.is_normal_specimen_aligned" => [
                             "T"
                     ]
                 }
              };
        push $es_query->{filter}{bool}{must}, $term;


    }

    if (defined ($filter_donors) && %{$filter_donors}) {
        $term = {
                     "terms" => { 
                               "donor_unique_id" => $filter_donors
                     }
                };
        
        push $es_query->{filter}{bool}{"must_not"}, $term unless $force;
    }

    if ($number_of_donors) {
         $es_query->{from} = 0;
         $es_query->{size} = $number_of_donors;
    }
    else {
        $term = {
                   "terms" => {
                         "_id" => $query_donors
                   }       
                };
        push $es_query->{filter}{bool}{must}, $term;
        $es_query->{size} = 100000;
    }

    if ($force) {
       #Retruning even if the INI has been run before
    }
    elsif ($self->{workflow_name} eq 'SangerPancancerCgpCnIndelSnvStr') {
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
                            "flags.is_dkfz_variant_calling_performed" => [
                                   "F"
                             ]
                       }       
                   };
        push $es_query->{filter}{bool}{must}, $term;
        $term = {
                       "terms" => {
                            "flags.is_embl_variant_calling_performed" => [
                                   "F"
                             ]
                       }       
                   };
        push $es_query->{filter}{bool}{must}, $term;
    }
    elsif ($self->{workflow_name} eq 'DKFZWorkflow') {
        $term = {
                       "terms" => {
                            "flags.is_dkfz_variant_calling_performed" => [
                                   "F"
                             ]
                       }       
                   };
        push $es_query->{filter}{bool}{must}, $term;
    }
    elsif ($self->{workflow_name} eq 'EMBLWorkflow') {
        $term = {
                       "terms" => {
                            "flags.is_embl_variant_calling_performed" => [
                                   "F"
                             ]
                       }       
                   };
        push $es_query->{filter}{bool}{must}, $term;
    }
    elsif ($self->{workflow_name} ne 'Workflow_Bundle_BWA' && $self->{workflow_name} ne 'Workflow_GNOS_to_S3') {
        die "Incorrect workflow_name: $self->{workflow_name}";
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

1;
