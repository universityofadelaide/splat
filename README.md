# SPLAT - Self & Peer Learning Assessment Tool

## Requirements
* Ruby 2.4.2
* MySQL / MariaDB
* Canvas LMS

## Configuration
Under "config" you find a couple of "*_sample.yml" files. The "_sample" part has to be removed and the file populated with your configuration details:
### **app.yml**
* "google_analytics" allows you to specify if you want to use Google Analytics and your individual ID.
* "learner_banner" allows you to specify a piece of HTML that gets displayed in the right upper corner (learner role only).
### **database.yml**
* Allows you to configure your database per environment. The sample configuration is using MySQL / MariaDB.
### **secrets.yml**
* Defines your LTI consumer key and secret to be used within Canvas. It also defines your "secret_key_base" which is used to identify the integrity of signed cookies.
### **services.yml**
* Defines the URL, the API prefix (usually "api/v1/") and the API token (needs Admin access) of your instance of Canvas LMS. This setting is needed to connect to Canvas to gather group memberships and to sync with the grade book.
### **General tasks**
* Run "bundle install" to install all dependencies.
* The file "db/migrate/20180824014659_base_migration.rb" contains the standard questions defined for our institution. Feel free to create a new migration to delete our questions and define your own.
* Run "rake db:create" and "rake db:migrate" to configure the database structure.


## Canvas LMS
After SPLAT is deployed to your environment, it needs to be configured in Canvas LMS.
* Add a new LTI pointing to your deployed instance of SPLAT and use the credentials defined in "secrets.yml".
* Create a new assignment within Canvas and select SPLAT as an external tool.
* Once you save it, SPLAT should launch and you'll be able to configure your questions and then import a groupset from Canvas.
* After the assignment is configured, your students can submit their ratings and an instructor can manage the assignment (see results, remove a submission, notify students who haven't submitted yet, or integrate with Canvas grade book).

## User guide
Please see https://myuni.adelaide.edu.au/courses/24800/pages/self-and-peer-learning-and-assessment-tool-splat-staff-user-guide for a detailed staff user guide

## Contribution
Please consider forking this project and contributing via pull requests.