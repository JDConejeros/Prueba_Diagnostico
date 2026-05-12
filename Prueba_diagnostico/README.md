# Encuesta con surveydown

Este proyecto contiene una encuesta online creada en R con `surveydown` a partir del archivo `Preguntas_diagnostico_JC.xlsx`.

## Archivos

- `survey.qmd`: contenido de la encuesta.
- `app.R`: aplicación Shiny que ejecuta la encuesta y guarda respuestas en base de datos.
- `generar_encuesta.R`: script para regenerar `survey.qmd` leyendo el Excel.
- `configurar_bd.R`: asistente para crear/actualizar credenciales `.env`.
- `obtener_resultados.R`: descarga resultados desde la base y los guarda en CSV.
- `Preguntas_diagnostico_JC.xlsx`: banco de preguntas.
- `Graf_erroneo.jpeg`: imagen usada en la pregunta 10.

## Paquetes de R necesarios

```r
install.packages(c("surveydown", "shiny", "readxl"))
```

## Paso a paso (base de datos + publicación + resultados)

### 1) Crear base de datos en Supabase

1. Crea cuenta en Supabase y crea un proyecto.
2. En el proyecto, abre **Connect** y elige **Transaction Pooler**.
3. Ten a mano host, puerto, dbname, user, password y nombre de tabla.

### 2) Guardar credenciales en `.env`

Ejecuta:

```r
source("configurar_bd.R")
```

o directamente:

```r
surveydown::sd_db_config()
```

Esto crea (o actualiza) el archivo `.env` en la raíz del proyecto.

### 3) Ejecutar y probar la encuesta

Con `.env` ya creado, ejecuta:

```r
shiny::runApp()
```

La app usa `sd_db_connect()` en `app.R`, por lo que las respuestas se registran en Supabase.

### 4) Publicar la encuesta

Publica `app.R` en **shinyapps.io** (botón Publish en RStudio/Positron, o flujo equivalente).

Importante: la app publicada también escribirá en la misma tabla remota definida en `.env`.

### 5) Obtener resultados

Ejecuta:

```r
source("obtener_resultados.R")
```

Esto descarga los datos con `sd_get_data()` y crea un archivo `resultados_encuesta_YYYYMMDD.csv`.

## Regenerar la encuesta desde el Excel

Si cambias las preguntas del Excel, corre:

```r
source("generar_encuesta.R")
```

Eso volverá a construir `survey.qmd` agrupando las preguntas según la columna `Tipo pregunta`.
