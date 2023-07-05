---
layout: default
title: Home
---
# Home

I'm Leon and I lke to write little utilities to help people with tasks related to REST API's and other things.  

I work at VMware and I'm a member of the Workspace ONE team.

## Projects

### [WSOneLogConverterForLNAV](https://github.com/leonletto/WSOneLogConverterForLNAV)

A handy tool to convert some incompatible logs into a format compatible with the powerful LNAV log file viewer.
Designed for use with Workspace ONE windows Log Bundles.

#### Features:
- Converts out of order logs in case of time changes during deployment
- Converts Installer logs to a format that LNAV can read
- Converts Windows Event Logs to a format that LNAV can read
- Provides parsers for the converted logs

### [ca-for-labs](https://github.com/leonletto/ca-for-labs)

ca-for-labs - formerly littleCa - Create your own CA for your environment and issue and revoke certificates as needed.
#### Features: 
- Create your own CA for your lab, home network or demo environment
- Issue server certificates for your environment
- Creates PEM and PFX certificates
- Revoke certificates for your environment
- Create a certificate revocation list (CRL) for your environment


### [bashLogger](https://github.com/leonletto/bashLogger)

logging module for bash scripts

#### Features:
- This script is used to log messages to the console and to a log file and is designed to be similar the API of the python logging module. It includes log rotation by size and by number of log files.
- There are a couple of additional functions to show how you could create custom logging functions for yourself.
- There is a test script that you can run to see how the logging works.

### [bash_compare_numbers](https://github.com/leonletto/bash_compare_numbers)

Comparing integers in bash is included in the base functionality but floating point numbers and version numbers in bash is difficult. This library makes it easier fast for use in bash functions without having to develop your own strategy. The base comparison is using integers so any combination of integers, ascii characters, and floating point numbers can be compared.

By necessity it is opinionated but I hope that it is flexible enough to be useful.

#### Features:
- I have included 5 helper functions which can be used to compare floating point numbers and version numbers. 
-  The functions are: gt lt ge le and eq.


### [bashExportCsv](https://github.com/leonletto/bashExportCsv)

Bash function to export flattened csv files from curl responses or other json.

#### Why is this needed?
If you have large multi-level json that you want to flatten, for exporting to csv for visualization in Spreadsheets or importing into databases, the modules available lack the multi-level functionality which I prefer.  I wrote another project which did this in an Excel Add-on ( using javascript ) but that does not work for the command line.

I found mot of what I needed in jq for flattening json objects and arrays. However, if you try to do the export using jq and bash, the speed suffers immensely and I could only get to 20-30 lines/records per second to export with 500 byte records. This is unusable for large responses from enterprise REST API's with tens ( or hundreds ) of thousands of records per response so getting a spreadsheet out of a REST query would be very slow. 

Using [jq](https://stedolan.github.io/jq/download/) and [sqlite-utils]( https://sqlite-utils.datasette.io/en/stable/) together, I was able to go from 20-30 records per second to 2000-3000 records per second which is quite usable.


## Contributing

Bug reports and pull requests are welcome on GitHub at the repositories listed above. These projects are intended to be safe, welcoming spaces for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.
