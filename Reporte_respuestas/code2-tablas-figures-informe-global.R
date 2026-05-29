# Code 2: Construcción de tablas y figures reporte -----

library(rio)
library(tidyverse)
library(janitor)

data <- rio::import("Reporte_respuestas/respuestas_procesadas.RDS")
glimpse(data)

# Tabla de resultados descriptivos 
tabla0a <- data |> 
  distinct(id, puntaje) |> 
  summarise(
    "Promedio" = mean(puntaje),
    "Porcentaje de logro" = (mean(puntaje)/10)*100,
    "Desviación estándar" = sd(puntaje),
    "Mínimo" = min(puntaje),
    "Mediana" = median(puntaje),
    "Máximo" = max(puntaje), 
    "Número de estudiantes" = n()
  ) |> 
    mutate_if(is.numeric, ~ round(., 2)) |> 
    mutate("Área de evaluación" = "Global")

tabla0b <- data |> 
  group_by(id, area_estudio) |> 
  summarise(logro = sum(logro)) |>
  ungroup() |> 
  mutate(
    max = case_when(
      area_estudio == "Estadística" ~ 4,
      area_estudio == "Programación" ~ 4,
      area_estudio == "Políticas Públicas" ~ 2
    ),
    logro_prop = logro / max
  ) |>
  group_by(area_estudio) |>
  summarise(
    "Promedio" = mean(logro),
    "Porcentaje de logro" = mean(logro_prop)*100,
    "Desviación estándar" = sd(logro),
    "Mínimo" = min(logro),
    "Mediana" = median(logro),
    "Máximo" = max(logro), 
    "Número de estudiantes" = n()
  ) |> 
  mutate_if(is.numeric, ~ round(., 2)) |> 
  rename("Área de evaluación" = area_estudio) 

tabla0 <- bind_rows(tabla0a, tabla0b) |> 
  select("Área de evaluación", everything())

rio::export(tabla0, "Reporte_respuestas/Output/tabla_resumen_general.xlsx")

# Tabla con el % de logro en cada pregunta 

tabla1 <- data |> 
  group_by(area_estudio, pregunta) |> 
  summarise(logro = mean(logro)) |> 
  ungroup() |> 
  rename(
    "Área de evaluación" = area_estudio,
    "Pregunta" = pregunta, 
    "Logro (%)" = logro
  ) |> 
  mutate_if(is.numeric, ~ round(.*100, 2))

rio::export(tabla1, "Reporte_respuestas/Output/tabla_logro_pregunta.xlsx")


