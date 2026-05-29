# Code 1: Preparación de respuestas -----

library(rio)
library(tidyverse)
library(janitor)

# Revisemos la pauta 
pauta <- rio::import("Reporte_respuestas/pauta.xlsx") |> clean_names()
glimpse(pauta) 

# Limpiemos las respuestas
data <- rio::import("Reporte_respuestas/respuestas_ordenadas.csv")
glimpse(data) # 43 respuestas 

# Editamos los textos de edit y nombre
data_pro <- data |> 
  drop_na() |> 
  mutate(
    id = str_replace(identificacion_rut, "-|\\.|DNI ", ""),
    id = str_replace_all(id, "\\D", ""), 
    id = as.numeric(id),
    nombre = str_extract(identificacion_nombre_completo, "^\\S+")  
  ) 

glimpse(data_pro)
unique(data_pro$nombre)

# Ajutemos la tabla de datos a un formato largo 
data_prol <- data_pro |> 
  pivot_longer(
    cols = starts_with("q"),
    names_to = "q",
    values_to = "respuesta"
  ) |> 
  rename(correo = identificacion_correo) |>
  select(id, nombre, correo, q, respuesta)

# Generamos área de estudio 
data_prol <- data_prol |> 
  mutate(
    area_estudio = case_when(
      str_detect(q, "q01|q02|q03|q09") ~ "Programación",
      str_detect(q, "q04|q05|q06|q08") ~ "Estadística",
      str_detect(q, "q07|q10") ~ "Políticas Públicas",
      TRUE ~ NA_character_
    ),
    area_estudio = factor(area_estudio, 
      levels = c(
        "Estadística", 
        "Programación", 
        "Políticas Públicas")) 
  )

glimpse(data_prol)

# Unimos con la pauta 
glimpse(pauta)

data_final <- data_prol |> 
  left_join(pauta, by = c("q" = "id"))

glimpse(data_final)

# Generamos métricas de logro 
data_final <- data_final |> 
  mutate(
    logro = if_else(respuesta == alternativa_correcta, 1, 0)
  )

resultados_estudiantes <- data_final |> 
  group_by(id) |> 
  summarise(
    puntaje = sum(logro),
    maximo = n(), 
    porcentaje_logro = round(puntaje / maximo * 100, 2),
    .groups = "drop"
  ) |> 
  mutate(
    nota = if_else(
      porcentaje_logro/100 <= 0.6,
      1 + ((porcentaje_logro/100) / 0.6) * 3,                     # 0..0.6 -> 1..4
      4 + (((porcentaje_logro/100) - 0.6) / 0.4) * 3              # 0.6..1 -> 4..7
    ),
    nota = round(nota, 1)
  )

glimpse(resultados_estudiantes)
summary(resultados_estudiantes)

data_final <- data_final |> 
  left_join(resultados_estudiantes, by = "id")

glimpse(data_final)

# Guardamos los datos 
rio::export(data_final, "Reporte_respuestas/respuestas_procesadas.csv")
