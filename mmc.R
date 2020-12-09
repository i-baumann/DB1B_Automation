library(tidyverse)

load("~/Desktop/final_tix.rda")

# Get only routes with more than one carrier per year-q-route

carriers_per <- final_tix %>%
  group_by(route, year, quarter) %>%
  summarise(carriers = length(unique(TkCarrier)),
            .groups = "keep") %>%
  filter(carriers > 1)

carriers_per$concat <- paste(carriers_per$route,
                             carriers_per$year,
                             carriers_per$quarter,
                             sep = "-")

final_tix$concat <- paste(final_tix$route,
                             final_tix$year,
                             final_tix$quarter,
                             sep = "-")

final_tix <- final_tix %>%
  filter(concat %in% carriers_per$concat)

final_tix <- final_tix %>% select(-concat)

save(final_tix, file = "~/Desktop/final_tix.rda")

# Get MMC

  mmc_df <- NULL
  
  for (y in unique(final_tix$year)) {
    for (q in unique(final_tix$quarter)) {
      
      yq_temp <- final_tix %>%
        filter(year == y, quarter == q)
      
      carriers <- unique(yq_temp$TkCarrier)
      
      for (c1 in carriers) {
        
        c1_routes <- yq_temp %>%
          filter(year == y, 
                 quarter == q,
                 TkCarrier == c1) %>%
          ungroup() %>%
          select(route)
        
        for (c2 in unique(final_tix$TkCarrier)) {
          
          c2_routes <- yq_temp %>%
            filter(year == y, 
                   quarter == q,
                   TkCarrier == c2) %>%
            ungroup() %>%
            select(route)
          
          mmc <- nrow(intersect(c1_routes, c2_routes))
          
          label <- paste(c1,c2)
          
          mmc_df <- bind_rows(mmc_df, tibble(y, q, c1, c2, mmc))
          
        }
      }
      print(paste(y, q))
    }
  }
  
# Rename columns
colnames(mmc_df) <- c("year", "quarter", "carrier_1", "carrier_2", "mmc")

# Remove same-carrier MMC pairs
mmc_df <- mmc_df %>%
  filter(carrier_1 != carrier_2)

ammc_overall <- NULL

# Calculate average mmc per route
for (y in unique(final_tix$year)) {
  for (q in unique(final_tix$quarter)) {
    
    yq_temp <- final_tix %>%
      filter(year == y, quarter == q)
    
    for (j in unique(yq$route)) {
      
      temp_tix <- yq_temp %>%
        filter(route == j)
      
      carrier_n <- length(unique(temp_tix$TkCarrier))
      
      # Calculate weight
      lhs <- 1 / carrier_n
      
      # Get all combinations of airlines on route j
      cars_1 <- temp_tix$TkCarrier
      cars_2 <- temp_tix$TkCarrier
      
      expanded <- expand_grid(cars_1,
                  cars_2)
      
      # Delete own-airline combinations
      expanded <- expanded %>%
        filter(cars_1 != cars_2)
      
      expanded <- tibble(y, q, j, expanded)
      
      # Get MMCs
      expanded <- expanded %>%
        left_join(mmc_df,
                  by = c("y" = "year",
                         "q" = "quarter",
                         "cars_1" = "carrier_1",
                         "cars_2" = "carrier_2"))
      
      # Calculate average MMC
      tot_mmc <- sum(expanded$mmc)
      
      avg_mmc <- lhs * tot_mmc
      
      ammc_overall <- bind_rows(ammc_overall, tibble(y, q, j, avg_mmc))
      
    }
    print(paste(y, q))
  }
}

colnames(ammc_overall) <- c("year", "quarter", "route", "avg_mmc")

# Join average MMCs to final_tix

final_tix <- final_tix %>%
  left_join(ammc_overall,
            by = c("year", "quarter", "route"))

save(final_tix, file = "~/Desktop/final_tix.rda")
