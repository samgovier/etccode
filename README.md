# EtcCode

This is a repository of various recent code that I have developed. This readme is a guide for that code.

(Note: some configuration values have been ommitted or replaced for privacy)

## 2023

### TerraformEnvironment

This directory contains much of the build code specifying Azure resources for two web apps. This includes some modulization for reusable code, along with the use of Terraform Workspaces for production and staging.

### GitReleasePipeline

This directory contains the code used for a Git release strategy that makes merge changes, modifies version numbers in a repository, and waits for pipeline completion to confirm success.

## 2021

### CWTools

This directory just contains a PowerShell profile to load all necessary data for running Chef kitchen tests. Useful as a runnable profile to easily get to Chef Workstation PowerShell.

### DellPRTGAlerting

Dell PRTG Alerting is a series of Powershell scripts for pulling certain Dell Storage metrics and sending them to a PRTG server, which will be ingested and displayed as metrics over time and for alerting.

### GetDashboardChanges

Is a C# CLI application to save and scrape for changes to the monitoring dashboard, displaying them as a table in Windows Terminal. More details in the readme for that project.

### RDMManagement

RDM Management is a series of Powershell scripts for managing a Remote Desktop Manager database via CSV imports, exports, using the provided RDM Powershell module. This database can be used as a shared data source for team remote server needs.

### General

General has various other items, such as:

#### Various Scripts

Scripts in Python, Bash, and Powershell used for various purposes.

#### chef-*

Various examples of chef JSON or Ruby code from specific scenarios.

#### terraform-chef

Terraform build from a chef server deployment
