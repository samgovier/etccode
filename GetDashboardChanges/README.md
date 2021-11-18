# Introduction 
GetDashboardChanges is used to dynamically determine what changes have occurred to the EOD Dashboard since a previous scrape happened.

# Getting Started
The application is just a tiny CLI program with one-word commands generally either set the baseline or scrape and compare to the baseline.

## scrape
Scrape is the function to actually get changes: it performs a scrape of the dashboard and shows the differences between that scrape and the user's set baseline.

## set
Set similarly scrapes data from the Dashboard, and then uses that data as a baseline to diff against.

## get
Get pulls the currently saved Baseline for reference.

## creds
Creds allows you to change the credentials being used on the Dashboard request (used in the HTTP request header)

## help
Help displays basic information about all possible commands

## exit and quit
This will exit the application

# Build and Test
Runs as a simple compiled executable. Make sure your can read/write from the executable's directory. It will browse to the Dashboard from the local machine, using provided credentials.

# Contribute
Feel free to pull as you like.