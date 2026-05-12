# Prueba de diagnóstico

Proyecto de encuesta diagnóstica en R usando `surveydown` + `shiny`, con almacenamiento de respuestas en Supabase.

## Estructura del proyecto

```text
Prueba_diagnostico/
├─ app.R
├─ survey.qmd
├─ generar_encuesta.R
├─ configurar_bd.R
├─ obtener_resultados.R
├─ extraer_respuestas_ordenadas.R
├─ Preguntas_diagnostico_JC.xlsx
├─ Pauta_prueba.xlsx
├─ Graf_erroneo.png
├─ .env                      # credenciales BD (no versionar)
├─ resultados_encuesta_YYYYMMDD.csv
└─ respuestas_ordenadas.csv
```

## Rol de cada archivo

- `app.R`: levanta la app Shiny de la encuesta y conecta a la base con `sd_db_connect()`.
- `survey.qmd`: definición de páginas, preguntas y navegación de la encuesta.
- `generar_encuesta.R`: reconstruye `survey.qmd` desde `Preguntas_diagnostico_JC.xlsx`.
- `configurar_bd.R`: ejecuta `sd_db_config()` para crear/actualizar `.env`.
- `obtener_resultados.R`: descarga respuestas crudas desde la base y las guarda en CSV.
- `extraer_respuestas_ordenadas.R`: consulta directamente la base, ordena respuestas (`q01` a `q10`) y calcula logro usando `Pauta_prueba.xlsx`.
- `Pauta_prueba.xlsx`: pauta con respuestas correctas (columna `Alternativa correcta`).

## Dependencias

```r
install.packages(c("surveydown", "shiny", "readxl"))
```

## Flujo recomendado

### 1) Configurar base de datos (una vez)

1. Crea proyecto en Supabase.
2. En **Connect**, usa **Transaction Pooler**.
3. Ejecuta:

```r
source("configurar_bd.R")
```

Esto crea `.env` en la raíz del proyecto.

### 2) Ejecutar encuesta

```r
shiny::runApp()
```

La app registra respuestas directamente en Supabase.

### 3) Publicar encuesta

Publica `app.R` en shinyapps.io (o plataforma equivalente). La app publicada seguirá escribiendo en la misma tabla remota.

### 4) Extraer resultados crudos (opcional)

```r
source("obtener_resultados.R")
```

Genera `resultados_encuesta_YYYYMMDD.csv`.

### 5) Generar resultados ordenados + logro

```r
source("extraer_respuestas_ordenadas.R")
```

Genera `respuestas_ordenadas.csv` con:

- `nombre_completo`
- `rut`
- respuestas ordenadas por pregunta (`q01` ... `q10`)
- `cantidad_respuestas_correctas`
- `porcentaje_logro`

## Actualizar preguntas de la encuesta

Si cambias `Preguntas_diagnostico_JC.xlsx`, vuelve a generar el cuestionario:

```r
source("generar_encuesta.R")
```

Esto sobrescribe `survey.qmd` con la versión actualizada de preguntas.
