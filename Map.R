if(!require("osmdata")) install.packages("osmdata")
if(!require("tidyverse")) install.packages("tidyverse")
if(!require("sf")) install.packages("sf")
if(!require("ggmap")) install.packages("ggmap")

#load packages
library(tidyverse)
library(osmdata)
library(sf)
library(ggmap)
library(RgoogleMaps)


google <- get_map(location = c(-64.4,45.08), zoom = 10, maptype = "satellite")
p <- ggmap(google)
plot(p)