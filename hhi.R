# HHI

library(tidyverse)

load("~/Desktop/final_tix.rda")

# Calculate HHIs

temp_HHI <- NULL

for (y in unique(final_tix$year)) {
  for (q in unique(final_tix$quarter)) {
    
    temp_HHI <- final_tix %>%
      filter(year == y, quarter == q) %>%
      group_by(route, TkCarrier) %>%
      summarise(car_pass = sum(db1b_pass),
                .groups = "keep") %>%
      ungroup() %>%
      group_by(route) %>%
      mutate(tot_pass = sum(car_pass), s2 = (car_pass/tot_pass)^2) %>%
      summarise(year = y,
                quarter = q,
                HHI = sum(s2),
                .groups = "keep")
    
    temp_HHI <- rbind(temp_HHI, temp_HHI)
    
    if (y == 1993 & q == 1) {
      hhi <- temp_HHI
    } else {
      load("~/Desktop/final_tix.rda")
      hhi <- rbind(hhi,temp_HHI)
    }
    
  }
}

# Join hhi to final_tix

hhi$concat <- paste(hhi$route, hhi$year, hhi$quarter)
hhi <- hhi[!duplicated(hhi$concat),]

final_tix <- final_tix %>%
  inner_join(hhi %>% select(-concat),
            by = c("route", "year", "quarter"))

save(final_tix, file = "~/Desktop/final_tix.rda")
