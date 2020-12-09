# Networksize

library(tidyverse)

load("~/Desktop/final_tix.rda")

# Create origin airport variable
final_tix$origin <- word(final_tix$route, 1, sep = "-")

# Group to get counts of routes per origin
final_tix <- final_tix %>%
  group_by(year, quarter, origin) %>%
  mutate(origin_routes = n_distinct(route))

# Get counts of routes per origin per airline
final_tix <- final_tix %>%
  group_by(year, quarter, origin, TkCarrier) %>%
  mutate(origin_routes_airline = n_distinct(route)) %>%
  ungroup()

# Divide the two to get network percentage
final_tix$networksize <- final_tix$origin_routes_airline / final_tix$origin_routes

# Remove intermediate variables
final_tix <- final_tix %>% 
  select(-origin, -origin_routes, -origin_routes_airline)

save(final_tix, file = "~/Desktop/final_tix.rda")
