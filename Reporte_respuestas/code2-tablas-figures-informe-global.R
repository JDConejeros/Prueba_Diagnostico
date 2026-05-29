# Code 2: Construcción de tablas y figures reporte -----

library(rio)
library(tidyverse)
library(janitor)

data <- rio::import("Reporte_respuestas/respuestas_procesadas.csv")
glimpse(data)

