#!/usr/bin/env bash  

SECONDS=0 

# Install packages
echo "Script assumes you have R installed. If not, first install base R."
echo "Install necessary packages (may take several minutes)."
sudo su - -c "R -e \"install.packages('tidyverse', repos='http://cran.rstudio.com/', quiet = TRUE)\""
sudo su - -c "R -e \"install.packages('ineq', repos='http://cran.rstudio.com/', quiet = TRUE)\""
sudo su - -c "R -e \"install.packages('blscrapeR', repos='http://cran.rstudio.com/', quiet = TRUE)\""
sudo su - -c "R -e \"install.packages('stargazer', repos='http://cran.rstudio.com/', quiet = TRUE)\""

for i in {1993..2017}
    do for j in {1..4}
	    do Rscript download_clean.R $i $j
	    echo "Complete: $i Q$j"
	done
done

Rscript mmc.R

for i in {1993..2017}
        do Rscript Rscript t100_loop.R $i
        echo "Complete: $i"
done

Rscript t100_clean.R

Rscript hub.R

Rscript hhi.R

Rscript outsourcing.R

Rscript networksize.R

Rscript desc_table.R

# Get runtime
if (( $SECONDS > 3600 )) ; then
    let "hours=SECONDS/3600"
    let "minutes=(SECONDS%3600)/60"
    let "seconds=(SECONDS%3600)%60"
    echo "Completed in $hours hour(s), $minutes minute(s) and $seconds second(s)" 
elif (( $SECONDS > 60 )) ; then
    let "minutes=(SECONDS%3600)/60"
    let "seconds=(SECONDS%3600)%60"
    echo "Completed in $minutes minute(s) and $seconds second(s)"
else
    echo "Completed in $SECONDS seconds"
fi
