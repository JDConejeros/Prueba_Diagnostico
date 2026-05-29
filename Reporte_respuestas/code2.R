# Code 2: Construcción de reportes individuales -----

library(rio)
library(tidyverse)
library(janitor)

data <- rio::import("Reporte_respuestas/respuestas_procesadas.csv")
glimpse(data)
