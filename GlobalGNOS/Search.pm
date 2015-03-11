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
    my ($self, $query_donors, $filter_donors ) = @_;

    my $query = (defined $self->{gnos_repo})? 'gnos_repos_with_complete_alignment_set: "'.$self->{gnos_repo}."\"" : '*';
    $query = '*';
    my $es_query = { 
       body => {
           "query" => {
              "filtered" => {
                 "query" => {
                    "bool" => {
                       "must" => [
                          {
                             "query_string" => {
                                "query" => "$query"
                             }
                          }
                       ],
                    }
                 },
                 "filter" => {
                    "bool" => {
                       "must" => [
                          {
                             "terms" => {
                                "flags.is_normal_specimen_aligned" => [
                                   "T"
                                ]
                             }
                          },
                          {
                             "terms" => {
                                "flags.are_all_tumor_specimens_aligned" => [
                                   "T"
                                ]
                             }
                          },
                          {
                             "terms" => {
                                "flags.is_donor_blacklisted" => [
                                   "F"
                                ]
                             }
                          },
                          {
                             "terms" => {
                                "flags.are_all_tumor_specimens_aligned" => [
                                   "T"
                                ]
                             }
                          }
                       ],
                       "must_not" => {
                           "terms" => { 
                                  "donor_unique_id" =>
                                  $filter_donors
                           }
                       }
                   }
                }
              }
            },
            "sort" => [
              {
                 "gnos_study" => {
                    "order" => "asc",
                    "ignore_unmapped" => "true"
                 }
              }
           ]
       }
    };

    if ($query_donors->[0] =~ /^\d+$/) {
         $es_query->{body}{from} = 0;
         $es_query->{body}{size} = $query_donors->[0];
    }
    else {
        my $term = {
                       "terms" => {
                            "_id" => $query_donors
                       }       
                   };
        push $es_query->{body}{query}{filtered}{filter}{bool}{must}, $term;
    }

    if ($self->{workflow_name} eq 'SangerPancancerCgpCnIndelSnvStr') {
        my $term = {
                       "terms" => {
                            "flags.is_sanger_variant_calling_performed" => [
                                   "T"
                             ]
                       }       
                   };

        push $es_query->{body}{query}{filtered}{filter}{bool}{must}, $term;
    }
    elsif ($self->{workflow_name} eq 'DEWrapperWorkflow') {
         my $term = {
                       "terms" => {
                            "flags.is_german_variant_calling_performed" => [
                                   "T"
                             ]
                       }       
                   };

        push $es_query->{body}{query}{filtered}{filter}{bool}{must}, $term;
     
    }
    else {
        die 'Incorrect workflow_name';
    }

    my $e = Search::Elasticsearch->new( nodes =>  $self->{elasticsearch_url} );
    my $results = $e->search($es_query);
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
    my ($self, $query_donors, $filter_donors ) = @_;

    my $donors = get_donors_for_variant_calling($self, $query_donors, $filter_donors);

    my %aligned_sets;
    foreach my $donor_id (keys %{$donors}) {
        my $tumour_specimen = $donors->{$donor_id}{aligned_tumor_specimens};
        my $normal_specimen = $donors->{$donor_id}{normal_specimen};
        $aligned_sets{$donor_id} = { aligned_tumor_specimens => $tumour_specimen,
                                     normal_specimen         => $normal_specimen };
    }

    return \%aligned_sets;
}

1;
