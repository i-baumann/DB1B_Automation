# Outsourcing variables
library(tidyverse)

load("~/Desktop/final_tix.rda")

# Get own outsourcing

own_out <- final_tix %>%
  group_by(year, quarter, TkCarrier, mkt_decile) %>%
  summarise(sum_own_out = sum(outsource),
            n_routes_own = length(unique(route)),
            .groups = "keep")

final_tix <- final_tix %>%
  left_join(own_out,
            by = c("year", "quarter", "TkCarrier", "mkt_decile"))

final_tix$own_out <- (final_tix$sum_own_out - final_tix$outsource) / (final_tix$n_routes_own - 1)

# Replace NaNs with 0
final_tix$own_out <- ifelse(is.na(final_tix$own_out), 0, final_tix$own_out)

# Get competitor outsourcing

comp_out <- final_tix %>%
  group_by(year, quarter, route) %>%
  summarise(total_sum_own_out = sum(sum_own_out),
            total_n_route = sum(n_routes_own),
            .groups = "keep")

final_tix <- final_tix %>%
  left_join(comp_out,
            by = c("year", "quarter", "route"))

final_tix$comp_out <- (final_tix$total_sum_own_out - final_tix$sum_own_out) / (final_tix$total_n_route - final_tix$n_routes_own)

save(final_tix, file = "~/Desktop/final_tix.rda")
