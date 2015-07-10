[![Build Status](https://travis-ci.org/ICGC-TCGA-PanCancer/central-decider.svg?branch=develop)](https://travis-ci.org/ICGC-TCGA-PanCancer/central-decider)

# Central Decider
This tool is intended to be used to schedule VCF and BWA workflows for the PanCancer project. The tool pulls information from the centralized Elasticsearch database and keeps track of what has been scheduled in one central location. 

The Decider takes http (CGI) get requests and forms responses based on information in the pancancer.info Elasticsearch database. The Decider itself has a SQLite database for keeping track of what has been scheduled. 

The tool can be queried in two distinct ways. The first way is to provide a whitelist of donors or samples. And the second way is to provide the number of results you would like. 

#Option 1 - Whitelist
If you are providing a whitelist the central decider will return the infromation required to generate an INI to run the sample for each sample that should be run. The whitelists can be found in the [pcawg-operations](https://github.com/ICGC-TCGA-PanCancer/pcawg-operations) repo. Alternatively, the user can specify the parameter "cloud-env" to get the central decider to grab the correct whitelist for the cloud environment and send back the relevant ini's to the client. The central dececider grabs the latest tag of the pcawg-operations repo on a nightly basis.  

If the get paramerter "force" is used, it will return all INI's regardless of whether they have been previously completed or not. 

In this case the system will not record that the ini files were retrieved and will be able to be queried as many times as desired.

#Option 2 - specifying number of INI's
If the number of donors is specified, without a whitelist, it will return the specified number of donors unless fewer are available. 

With this method the default is for the decider to record that information was sent out in a database table. It will not resend the same INI 30 days. If the INI had been processed and the sample was completed within the 30 days it will never be resent (almost all of them should fall in this catigory).  

## installation

###Environment

Spin up a ubuntu 14.04 VM. This interface requires minimal CPU and RAM. I have been using a Micro instance on AWS to run the decider.
      
###Installing Packages
      sudo apt-get update
      sudo apt-get install make gcc libconfig-simple-perl libdbd-sqlite3-perl libjson-perl apache2 libcgi-session-perl libipc-system-simple-perl libcarp-always-perl libdata-dumper-simple-perl libio-socket-ssl-perl sqlite3 libsqlite3-dev libcapture-tiny-perl git cpan

###Enable Apache CGI 
      sudo a2enmod cgi
      
###Cloning Repo
      cd /usr/lib/cgi-bin/;
      git clone <central-decider>

##Adding Apache authentication 
      sudo htpasswd -c /var/passwd/passwords
      sudo vim /etc/apache2/conf-enabled/serve-cgi-bin.conf
      Addto directory:
            AuthType Basic
            AuthName "Pancancer Metadata"
            AuthUserFile /var/passwd/passwords
            Require user pancancer
      sudo service apache2 restart

## Setting up Whitelist
      mkdir ~/git (this is where the git repo pcawg-operations will be located)
      cd /usr/lib/cgi-bin/central-decider
      perl bin/get-whitelist.pl 

## Setup Whitelist cronjob
      crontab -e  # to edit crontab
      add line "0 4 * * * perl /usr/lib/cgi-bin/central-decider/bin/get-whitelist.pl" to have the whitelist be updated daily at 4am
      

##Get URL parameters
|  parameter | values description |
|------------|--------------------|
| workflow-name | As would appear to seqware and in the metadata |
| donor| Specifying a donor name |
| number-of-donors | To be used if you are not using whitelists. Specifies number of donors worth of results |
| vm-location-code | If specified the central decider will check to make sure the location code being  used is on the list of locations |
| gnos-repo | The repos you intend on pulling the aligned BAMs from |
| local-file-dir | If specified this directory will be used to generate full paths to the bam files |
| test | If specified the the database will not record the sample that has been scheduled |
| force | To be used when you want it to return INI files for workflows that have already been run |

     
##Sample CGI URL
     http://<hostname>/cgi-bin/central-decider/get-ini?workflow-name=SangerPancancerCgpCnIndelSnvStr&donor=1&gnos-repo=https://gtrepo-ebi.annailabs.com/
     
This will return back one donors worth of information to be used in combination with a workflow.ini template. Specific donors can be specified by repeating the donor parameter with different donors (format <project_code>::<donor_id>) instead of specifying the number of donors worth of information you would like.
     
If a number is specified that number of donors will be returned. Once a donor has been sent out using this method it will not be sent out again unless it has not been completed and it has been over 30 days since it has been scheduled.  

##Blacklist
This file should contain a list of donors that should not be scheduled. The main reaons for this is because a list of donors has been reserved to be ran at a particular location. The file should contain two columns seperated by white space - project\_code and donor\_id;

## workflow-map.cfg
This file specifies the workflows and organizes them into the type of workflow (VCF or BAM). This is used by the program to determine how to treat the workflow. When specifying a workflow\_name, the decider will only return results for a specific donor if it has not been completed yet. The only exception to this is the workflow\_name "DEWrapperWorkflow". With this workflow it checks to make sure neither EMBL or DKFZ have been run.

##Maintaining SQLite Database:
       
###Logging in: 
      sqlite3 running.db
###Creating schema
      CREATE TABLE vcf_scheduled (id integer primary key autoincrement , workflow_name varchar(255), project varchar(255), donor_id varchar(255), gnos_repo varchar(255), analysis_center varchar(255), dt datetime default current_timestamp); 
      CREATE TABLE bwa_scheduled (id integer primary key autoincrement , workflow_name varchar(255), project varchar(255), sample_id varchar(255), gnos_repo varchar(255), analysis_center varchar(255), dt datetime default current_timestamp); 


Make sure this table is empty if running the decider for the first time. 
      
