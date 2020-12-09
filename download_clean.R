################################
####    ECON 740 PROJECT    ####
####      ISAAC BAUMANN     ####
################################

# PICK YOUR FIGHTERS:
#######################################################

library(dplyr)
library(magrittr)
library(readr)
library(ineq)
library(blscrapeR)

#######################################################
# DATA SOURCES
#
# Airline service and fare data:
# DB1B: https://www.transtats.bts.gov/Tables.asp?DB_ID=125&DB_Name=Airline%20Origin%20and%20Destination%20Survey%20%28DB1B%29&DB_Short_Name=Origin%20and%20Destination%20Survey
# T100: https://www.transtats.bts.gov/Tables.asp?DB_ID=111&DB_Name=Air%20Carrier%20Statistics%20%28Form%2041%20Traffic%29-%20All%20Carriers&DB_Short_Name=Air%20Carriers
# 
# Additional data from FAA and EIA:
# FAA PFC charge data: https://www.faa.gov/airports/pfc/monthly_reports/
# EIA jet fuel data: https://www.eia.gov/dnav/pet/hist/LeafHandler.ashx?n=PET&s=EMA_EPJK_PTG_NUS_DPG&f=M
#######################################################

#######################################################
# READ IF HAVING ISSUES WITH BTS DOWNLOADS
#
# The BTS server security is kind of crap, so you may need
# to downgrade your SSL security settings in order to avoid
# SSL/dh key errors
#
# For Linux:
# https://askubuntu.com/questions/1233186/ubuntu-20-04-how-to-set-lower-ssl-security-level
#
# Should work on Macs wihtout settings changes though
#######################################################






# Load, clean, and build the ticket data
# THIS LOOP WILL TAKE HOURS TO RUN
# IF YOU DO NOT HAVE ADEQUATE RAM EMAIL ME FOR CLEANED FINAL FILE
# It might also be easier to run this in base R (not via RStudio)
# BE SURE TO USE SH SCRIPT, DO NOT RUN BY ITSELF

# Print command line args
args <- commandArgs()

i <- as.numeric(args[6])

j <- as.numeric(args[7])

# Create temp directory for DB1B downloads
temp <- tempfile()

# List of major carriers (from Table 12 in Kim et al.)
major <- c("AA", "AS", "CO", "DL", "NW", "TW", "US", "UA")
airlines <- c("AA", "AS", "CO", "DL", "NW", "TW", "US", "UA",
              "B6", "F9", "FL", "J7", "KN", "KP", "N7", "NJ",
              "NK", "P9", "QQ", "SY", "TZ", "W7", "W9", "WN",
              "ZA")

# Define notin function
`%notin%` <- Negate(`%in%`)

# Get coupon data
coupon_url <- paste("https://transtats.bts.gov/PREZIP/Origin_and_Destination_Survey_DB1BCoupon_",i,"_",j,".zip", sep = "")
coupon_file <- paste("Origin_and_Destination_Survey_DB1BCoupon_",i,"_",j,".csv", sep = "")
download.file(coupon_url, temp, method = "wget", quiet = TRUE)
coupon <- read_csv(unz(temp, coupon_file),
                   col_types = cols_only( ItinID = col_double(),
                                          FareClass = col_character(),
                                          Coupons = col_double(),
                                          Break = col_character()))

# Get market data
market_url <- paste("https://transtats.bts.gov/PREZIP/Origin_and_Destination_Survey_DB1BMarket_",i,"_",j,".zip", sep = "")
market_file <- paste("Origin_and_Destination_Survey_DB1BMarket_",i,"_",j,".csv", sep = "")
download.file(market_url, temp, method = "wget", quiet = TRUE)
market <- read_csv(unz(temp, market_file),
                   col_types = cols_only( Year = col_double(),
                                          Quarter = col_double(),
                                          ItinID = col_double(),
                                          MktID = col_double(),
                                          Origin = col_character(),
                                          OriginAirportID = col_double(),
                                          Dest = col_character(),
                                          DestAirportID = col_double(),
                                          RPCarrier = col_character(),
                                          TkCarrier = col_character(),
                                          OpCarrier = col_character(),
                                          MktFare = col_double()))

# Get ticket data
ticket_url <- paste("https://transtats.bts.gov/PREZIP/Origin_and_Destination_Survey_DB1BTicket_",i,"_",j,".zip", sep = "")
ticket_file <- paste("Origin_and_Destination_Survey_DB1BTicket_",i,"_",j,".csv", sep = "")
download.file(ticket_url, temp, method = "wget", quiet = TRUE)
ticket <- read_csv(unz(temp, ticket_file),
                   col_types = cols_only( ItinID = col_double(),
                                          DollarCred = col_double(),
                                          ItinFare = col_double(),
                                          ItinGeoType = col_double(),
                                          RoundTrip = col_double(),
                                          Passengers = col_double()))

# Ticket df basic cleaning
############################################################################

# Drop if fare not credible
ticket <- ticket %>% subset(DollarCred == 1)

# Get only domestic flights
ticket <- ticket %>% subset(ItinGeoType == 2)

# Drop if one-way fare greater than $2500
ticket <- ticket %>% subset(ItinFare < 2500 & RoundTrip == 0 |
                              RoundTrip == 1)

# Drop if fare below 25 for direct or below 50 for round trip
ticket <- ticket %>% subset((ItinFare > 24.99 & RoundTrip == 0) |
                              (ItinFare > 49.99 & RoundTrip == 1))

# Pare down coupon and market dfs
coupon <- coupon %>%
  filter(ItinID %in% ticket$ItinID)

market <- market %>%
  filter(ItinID %in% ticket$ItinID)

# Coupon df basic cleaning
############################################################################

# Get roundtrip status
coupon <- coupon %>%
  left_join(ticket[c("ItinID", "RoundTrip")],
            by = "ItinID")

coupon$FareClass[coupon$FareClass == "C"] <- "2"
coupon$FareClass[coupon$FareClass == "D"] <- "2"
coupon$FareClass[coupon$FareClass == "G"] <- "3"
coupon$FareClass[coupon$FareClass == "F"] <- "3"
coupon$FareClass[coupon$FareClass == "X"] <- "1"
coupon$FareClass[coupon$FareClass == "Y"] <- "1"
coupon$FareClass[coupon$FareClass == "U"] <- "4"

# Code trip breaks
coupon$Break[!is.na(coupon$Break)] <- "1"
coupon$Break[is.na(coupon$Break)] <- "0"

coupon <- coupon %>%
  mutate(FareClass = as.numeric(FareClass),
         Break = as.numeric(Break))

# Check if fare class is all equal for each itinerary
coupon <- coupon %>%
  mutate(FareClass = as.numeric(FareClass)) %>%
  group_by(ItinID) %>%
  summarise(class = mean(FareClass),
            coupons = max(Coupons),
            breaks = sum(Break),
            roundtrip = max(RoundTrip),
            .groups = "keep")

# Keep only routes that are only economy class
coupon <- coupon %>%
  filter(class == 1)

# Pare down ticket and market dfs
ticket <- ticket %>%
  filter(ItinID %in% coupon$ItinID)

market <- market %>%
  filter(ItinID %in% coupon$ItinID)

# Market df basic cleaning
############################################################################

# Drop tickets where ticketing and operating carriers aren't reported
unreported_drop <- market[c("ItinID", "TkCarrier", "OpCarrier")] %>% 
  group_by(ItinID) %>%
  mutate("carrier_na" = ifelse(is.na(TkCarrier) | is.na(OpCarrier), 1, 0)) %>%
  summarise(drop = max(carrier_na),
            .groups = "keep") %>%
  filter(drop == 0)

# Drop tickets with codesharing (major carrier is ticketing carrier and
# operating carrier is other major carrier)
codeshare_drop <- market[c("ItinID", "TkCarrier", "OpCarrier")] %>% 
  group_by(ItinID) %>%
  mutate("codeshare" = ifelse(TkCarrier != OpCarrier & TkCarrier %in% major & OpCarrier %in% major, 1, 0)) %>%
  summarise(drop = max(codeshare),
            .groups = "keep") %>%
  filter(drop == 0)

# Drop itineraries with unreported carriers and codesharing between majors
market <- market %>% filter(ItinID %in% unreported_drop$ItinID |
                              ItinID %in% codeshare_drop$ItinID)

# Pare down ticket df
ticket <- ticket %>%
  filter(ItinID %in% market$ItinID)

# Get direct flights only
############################################################################

# Get roundtrip status
market <- market %>%
  left_join(ticket[c("ItinID", "RoundTrip")],
            by = "ItinID")

# Get only tickets with direct flights
market_direct <- market %>%
  group_by(ItinID) %>%
  summarise(market_n = length(unique(MktID)),
            roundtrip = max(RoundTrip),
            .groups = "keep")

market_direct <- market_direct %>%
  filter((roundtrip == 0 & market_n == 1) | (roundtrip == 1 & market_n == 2))

# Pare down market and ticket dfs
market <- market %>%
  filter(ItinID %in% market_direct$ItinID)

ticket <- ticket %>%
  filter(ItinID %in% market_direct$ItinID)

# Join
############################################################################

ticket_vars <- c("ItinID",
                 "ItinFare",
                 "RoundTrip",
                 "Passengers")

market_vars <- c("Year",
                 "Quarter",
                 "ItinID",
                 "Origin",
                 "OriginAirportID",
                 "Dest",
                 "DestAirportID",
                 "RPCarrier",
                 "TkCarrier",
                 "OpCarrier",
                 "MktFare")

tix_sum <- market[market_vars] %>%
  inner_join(ticket[ticket_vars],
             by = "ItinID")

# Create outsource indicator
tix_sum$outsource <- ifelse(tix_sum$TkCarrier != tix_sum$OpCarrier, 1, 0)

# Divide round trip fares in half and drop one of the duplicate observations
tix_sum$ItinFare_adj <- ifelse(tix_sum$RoundTrip == 1, tix_sum$ItinFare / 2, tix_sum$ItinFare)
tix_sum <- tix_sum[!duplicated(tix_sum$ItinID),]

# Adjust prices for inflation to 2017 USD
inf_adj <- inflation_adjust(2017)$adj_value[inflation_adjust(2017)$year == i]

tix_sum$ItinFare_adj_inf <- tix_sum$ItinFare_adj / inf_adj
tix_sum$MktFare_inf <- tix_sum$MktFare / inf_adj

# Calculate main statistics
tix_stats <- tix_sum %>%
  mutate(route = paste(OriginAirportID, DestAirportID, sep = "-"),
         year = Year,
         quarter = Quarter,
         orig = Origin,
         dest = Dest) %>%
  group_by(route, TkCarrier, year, quarter) %>%
  summarize(mean_mkt_fare = mean(MktFare),
            mkt_fare_10q = quantile(MktFare, .1),
            mkt_fare_90q = quantile(MktFare, .9),
            gini_mkt_fare = Gini(MktFare),
            mean_itin_fare_adj = mean(ItinFare_adj),
            itin_fare_10q = quantile(ItinFare_adj, .1),
            itin_fare_90q = quantile(ItinFare_adj, .9),
            gini_itin_fare = Gini(ItinFare_adj),
            passengers = sum(Passengers),
            rt_prop = mean(RoundTrip),
            db1b_tix = length(ItinID),
            outsource = mean(outsource),
            roundtrip = mean(RoundTrip),
            .groups = "keep")

tix_stats$gini_itin_lodd = log(tix_stats$gini_itin_fare / (1-tix_stats$gini_itin_fare))
tix_stats$gini_mkt_lodd = log(tix_stats$gini_mkt_fare / (1-tix_stats$gini_mkt_fare))

tix_stats <- tix_stats %>%
  filter(passengers >= 100)

# Save output
if (i == 1993 & j == 1) {
  final_tix <- tix_stats
} else {
  load("~/Desktop/final_tix.rda")
  final_tix <- rbind(final_tix,tix_stats)
}

save(final_tix, file = "~/Desktop/final_tix.rda")

unlink(temp)