# Central Decider
This tool is intended to be used to scheduled VCF workflows for the PanCancer project. It reads from the centralized Elasticsearch  database and keeps track of what has been scheduled in one central location. 

The Decider takes cgi get requests and forms responses based on information in the pancancer.info Elasticsearch database. The Decider itself has a SQLite database in order to keep track of what has been scheduled. 

## installation

###Install Perl Modules:
      sudo cpan
           install DBD::SQLite
                   JSON
                   CGI
                   IPC::System::Simple
                   Carp::Always
                   Data::Dumper

###Enable Apahe CGI 
      sudo a2enmod cgi
 
###Install SQLite
      sudo apt-get install sqlite3 libsqlite3-dev
      
###Cloning Repo
      cd /usr/lib/cgi-bin/;
      git clone <central-decider>
      
##Sample CGI URL
     http://<hostname>/cgi-bin/central-decider/donor-vcf?workflow-name=SangerPancancerCgpCnIndelSnvStr&donor=1&gnos-repo=https://gtrepo-ebi.annailabs.com/
     
This will return back one donors wroth of information to be used in combination with a workflow.ini template. Specific donors can be specified with the donor parameter instead of specifying the number of donors worth of information you would like.
     
If a number is specified that number of donors will be returned. Once a donor has been sent out using this method it will not be sent out again unless it has not been completed and it has been over 30 days since it has been scheduled.  

##Blacklist
This file should contain a list of donors that should not be scheduled. The main reaons for this is because a list of donors has been reserved to be ran at a particular location. The file should contain two columns seperated by white space - project_code and donor_id;

##Maintaining SQLite Database:
       
###Logging in: 
      sqlite3 running.db
###Creating schema
      CREATE TABLE scheduled (id integer primary key autoincrement , workflow_name varchar(255), project varchar(255), donor_id varchar(255), gnos_repo varchar(255), dt datetime default current_timestamp); 

Make sure this table is empty if running the decider for the first time. 
      
