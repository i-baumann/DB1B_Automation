library(tidyverse)

load("~/Desktop/final_tix.rda")

# Airline hub data was collected personally,
# Kim et al. do not provide it. I am only marking
# hubs for the 26 airlines in their data, even though
# my data includes more airlines

hubs <- read_csv("https://raw.githubusercontent.com/my-cabbages/R-Basics/master/hubs.csv")

hubs$concat <- paste(hubs$Airline, hubs$`DOT Code`, sep = "")

# Create hub indicator

final_tix <- final_tix %>%
  separate(route, c("origin", "dest"), "-", remove = FALSE)

  origin <- final_tix$origin
  dest <- final_tix$dest
  carrier <- final_tix$TkCarrier
  final_tix$hub <- ifelse(paste(carrier, origin, sep = "") %in% hubs$concat |
           paste(carrier, dest, sep = "") %in% hubs$concat, 1, 0)

final_tix <- final_tix %>% select(-origin, -dest)

save(final_tix, file = "~/Desktop/final_tix.rda")