## Preprocess data, write TAF data tables

## Before:
## After: report_template.docx, dist.csv,
##        ad_long.csv, ad_long_ex.csv,
##        ad_wide.csv, ad_wide_ex.csv

library(icesTAF)
library(jsonlite)
library(dplyr)
library(tidyr)

# create data directory
mkdir("data")

# get utility functions
source("utilities_data.R")

# load configuration
config <- read_json("config.json", simplifyVector = TRUE)

# get data from begin folder  -------------------------------

ad <- read.taf("begin/data.csv")
dist <- read.taf("begin/dist.csv")

# quick hacks -------------------------------

# use pixel distance if no scale
dist$distance[is.na(dist$distance)] <- dist$pixelDistance[is.na(dist$distance)]

# remove annotations on (and very near) the centre
dist <- dist[dist$pixelDistance > 2,]
# adjust ages in age data
ad$age <- unname(table(factor(dist$AnnotationID, levels = ad$AnnotationID))[paste(ad$AnnotationID)])

# convert reader expertise
ad$expertise <- c("Basic", "Advanced")[ad$expertise + 1]

# prepare data -------------------------------

# add date columns
ad <-
  within(ad, {
    year = lubridate::year(catch_date)
    qtr = lubridate::quarter(catch_date)
    month = lubridate::month(catch_date)
  })


# Calculate modal ages and cv of modal age
ad_long <- add_modalage(ad, config$ma_method)
ad_long_ex <- add_modalage(ad[ad$expertise == "Advanced", ], config$ma_method)


# prepare data in wbgr output format
# IMAGE,1,2,3,4,5,6,7,8,9,10,11,12,13
# Expertise level,-,-,-,-,-,-,-,-,-,-,-,-,-
# Stock assessment,no,no,no,no,no,no,no,no,no,no,no,no,no
# 6698256.jpg,1,1,1,1,1,-,2,1,-,2,-,1,-
# 6698257.jpg,3,3,3,3,2,1,3,3,-,3,-,3,-
readers <- sort(unique(ad$reader))
webgr <- spread(ad_long[c("sample", "reader", "age")], key = reader, value = age)
webgr[] <- paste(unlist(webgr))
webgr[webgr == "NA"] <- "-"
webgr <-
  rbind(c("Expertise level", rep("-", length(readers))),
        c("Stock assessment", rep("no", length(readers))),
        webgr)
names(webgr) <- c("IMAGE", 1:length(readers))
head(webgr)


# write out input data tables for use later
write.taf(dist, "data/dist.csv")
write.taf(ad, "data/data.csv")
write.taf(ad_long, "data/ad_long.csv")
write.taf(ad_long_ex, "data/ad_long_ex.csv")
write.taf(webgr, "data/WebGR_ages_all.csv")
