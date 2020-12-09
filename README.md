# DB1B downloading and cleaning

The scripts in this repo were written in an attempt to replicate summary statistics for [a recent transportation economics paper](https://evergreen.loyola.edu/kmtan/www/Research/TacitCollusionSouthwestAirlines_KimKimTan.pdf), but are a useful baseline in general for downloading and cleaning the Dept. of Transportation's [DB1B](https://www.transtats.bts.gov/Tables.asp?DB_ID=125&DB_Name=Airline%20Origin%20and%20Destination%20Survey%20%28DB1B%29&DB_Short_Name=Origin%20and%20Destination%20Survey) and [T100](https://www.transtats.bts.gov/Tables.asp?DB_ID=111&DB_Name=Air%20Carrier%20Statistics%20%28Form%2041%20Traffic%29-%20All%20Carriers&DB_Short_Name=Air%20Carriers) data for empirical research projects.

**The authors of the paper use cleaning methods and decision rules that I do not endorse or necessarily agree with, so edit these scripts as needed.**

These steps assume no prior knowledge of Bash or R scripting

**This entire process will likely take half a day or more to run, depending on your hardware**

## General overview

This process primarily utilizes two datasets from the US DOT's aviation databases: the DB1B and the T100. *These are large datasets*: the entirety of the DB1B used in the sample period is roughly 350 GB, uncompressed. This process automates both the downloading and cleaning of the data.

## Optional: modifying SSL security settings

*This step may be optional if you are using MacOS. If you are running a Linux flavor you will likely need to perform this step. I do not know if this step is necessary for Windows.*

The US DOT site's security is pretty pathetic and you may need to temporarily downgrade your default SSL settings for the script to download the data files via `wget`. To do so, find your `openssl.cnf` file and add the following to the top of the file:

```
openssl_conf = default_conf
```

And then add the following to the bottom of the file:

```
[ default_conf ]

ssl_conf = ssl_sect

[ssl_sect]

system_default = system_default_sect

[system_default_sect]
MinProtocol = TLSv1.2
CipherString = DEFAULT:@SECLEVEL=2
```
The default security level is 2. In order to download the data, you may need to change the security level to 1, as in `DEFAULT:@SECLEVEL=1`. *Do not forget to change the level back to 2 after the script is finished running.*

For those running Ubuntu or similar Linux flavors, see [this post](https://askubuntu.com/questions/1233186/ubuntu-20-04-how-to-set-lower-ssl-security-level) for more details.

## Running the process

### `summary_stats.sh`

- In terminal, navigate to the directory where you have saved the following files:
	- `summary_stats.sh`
- In terminal, run the shell script by entering `./summary_stats.sh`
	- The shell script is already executable, you do not need to `chmod` it
- The shell script will execute the R script. As noted before, *this process will take several hours, at least.*

### `download_clean.R`

- *Do not run the R script by itself* but feel free to look inside to see what it does. In short, the R script:
	- Automatically downloads the US DOT data needed for the paper replication
		- These files are saved in a temporary directory, so you will not need to worry about having 350 or so GB of free disk space and the files will automatically be deleted when the script is done with them
	- Cleans and joins the data to create the final dataset
	- Saves the dataset to your desktop (feel free to change the save directory wherever there is a `save()` function)
	- Produces a summary statistics table

### `mmc.R`

- This script runs the multimarket contact and average multimarket contact loops to create those variables once the cleaned data is ready. For each year-route-carrier combination, the multimarket contact index of each airline is calculated, then the average of the combinations of each airline-pair's multimarket contact index is calculated for each route-quarter.

### `hub.R`

- This script creates the `hub` variable.

### `t100_loop.R`

- This script automates the downloading of the T100 datasets and compiles them into one file.

### `t100_clean.R`

- One the T100 data are downloaded, this script cleans them (removes aircraft differentiation and creates market deciles for use in the outsourcing and HHI variable creation steps).

### `hhi.R`

- This script calculates the quarter-route-level Herfindahl index for each observation. It calculates the route-level squared market shares for each airline on a route and then sums them over each route.

### `outsourcing.R`

- This script calculates the `own_outsourcing` and `competitor outsourcing` variables. It groups observations by quarter, airline, and route to calculate outsourcing proportions for all routes j != 1 and then uses uses that proportion to calculate outsourcing proportions for all competitors on a given route (i.e., for all airlines i != 1).

### `networksize.R`

- This script creates the `networksize` variable, which is the percentage of routes flying out of a particular airline that are flown by an airline, by quarter.

### `desc_table.R`

- This script outputs the summary statistics table. You will need to manually replace the row for `gini_lodds` because some values are not finite.

## Why do I have to use a bash script for this process?

Particularly for the data download and cleaning process, statistical stoftware that [lazily loads](https://en.wikipedia.org/wiki/Lazy_loading) data will hold referenced data in memory in the background, even if you use removal and garbage collection methods. For this reason, the script cannot run all at one time in R. Attempting to loop through all quarterly data for 1993-2017 in R will cause you run out of RAM before it has even finished cleaning the data, causing R to crash and terminate the loop.

Instead, the download and cleaning loops run within the bash script and calls the R script in each iteration. This restarts R for each iteration, but it runs nearly as fast as if the entire loop could take place in R and ensures that R dumps unecessarily allocated memory, which allows the process to run for the entire period of 1993-2017. After each iteration, the final cleaned dataset is appended to and then saved to disk. While this is not ideal, it is the best option short of having an obscene amount of RAM.
