library(tidyverse)
library(stargazer)

load("~/Desktop/final_tix.rda")

final_tix_sg <- as.data.frame(final_tix)

stargazer(final_tix_sg %>% select(mean_itin_fare_adj,
                                  itin_fare_10q,
                                  itin_fare_90q,
                                  gini_itin_fare,
                                  avg_mmc,
                                  own_out,
                                  comp_out,
                                  networksize,
                                  hub,
                                  HHI),
          out = "~/Desktop/final_tix.tex")

# Manually place itin_lodd row in table
stargazer(final_tix_sg %>% 
            filter(is.finite(gini_itin_lodd)) %>%
            select(gini_itin_lodd))