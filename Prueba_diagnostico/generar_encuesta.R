# Instalamos paquetes
#install.packages("pak")
#pak::pak("surveydown-dev/surveydown")
#install.packages("shiny")

library(readxl)

ruta_excel <- "Preguntas_diagnostico_JC.xlsx"
ruta_salida <- "survey.qmd"

normalizar_texto <- function(x) {
  x <- tolower(trimws(iconv(x, to = "ASCII//TRANSLIT")))
  x <- gsub("[^a-z0-9]+", " ", x)
  trimws(x)
}

buscar_columna <- function(nombres, objetivo) {
  idx <- which(normalizar_texto(nombres) == normalizar_texto(objetivo))
  if (length(idx) == 0) stop(sprintf("No se encontró la columna '%s'.", objetivo), call. = FALSE)
  nombres[idx[1]]
}

slugificar <- function(x) {
  x <- tolower(trimws(iconv(x, to = "ASCII//TRANSLIT")))
  x <- gsub("[^a-z0-9]+", "_", x)
  x <- gsub("(^_+|_+$)", "", x)
  x
}

escapar_r <- function(x) {
  x <- gsub("\\\\", "\\\\\\\\", x)
  x <- gsub('"', '\\\\"', x)
  x <- gsub("\r|\n", " ", x)
  trimws(x)
}

crear_bloque_pregunta <- function(fila, col_tipo, col_pregunta, letras_cols) {
  numero <- as.integer(fila[["numero_interno"]])
  tipo_id <- slugificar(fila[[col_tipo]])
  pregunta_id <- sprintf("q%02d_%s", numero, tipo_id)
  pregunta <- escapar_r(as.character(fila[[col_pregunta]]))

  opciones <- c()
  letras <- names(letras_cols)
  for (letra in letras) {
    texto_opcion <- trimws(as.character(fila[[letras_cols[[letra]]]]))
    if (!is.na(texto_opcion) && nzchar(texto_opcion)) {
      opciones <- c(opciones, sprintf('    "%s) %s" = "%s"', letra, escapar_r(texto_opcion), letra))
    }
  }

  c(
    "```{r}",
    "sd_question(",
    sprintf('  id = "%s",', pregunta_id),
    '  type = "mc",',
    sprintf('  label = "%s",', pregunta),
    "  option = c(",
    paste(opciones, collapse = ",\n"),
    "  )",
    ")",
    "```"
  )
}

encabezado <- c(
  "---",
  'title: "Prueba diagnóstica"',
  "format: html",
  'theme: cosmo',
  'barcolor: "#2C7FB8"',
  'barposition: top',
  "survey-settings:",
  "  show-previous: true",
  "  all-required: true",
  "  auto-scroll: false",
  "  system-language: es",
  "---",
  "",
  "```{r}",
  "library(surveydown)",
  "```",
  "",
  "--- bienvenida",
  "",
  "# Prueba diagnóstica: Aproximación a las Políticas Públicas desde los Datos",
  "",
  "Esta prueba tiene como objetivo medir el nivel de conocimiento inicial de cada estudiante en tres dimensiones: estadística, programación y políticas públicas. Esta prueba NO posee calificación alguna, su importancia radica en la necesidad de medir el conocimiento base para adaptar de la mejor manera posible la dinámica de las clases y tutorías.",
  "",
  "```{r}",
  'sd_nav(show_previous = FALSE, label_next = "Ir a identificación")',
  "```",
  "",
  "--- identificacion",
  "",
  "# Identificación",
  "",
  "```{r}",
  "sd_question(",
  '  id = "identificacion_nombre_completo",',
  '  type = "text",',
  '  label = "Ingrese su nombre completo"',
  ")",
  "```",
  "",
  "```{r}",
  "sd_question(",
  '  id = "identificacion_rut",',
  '  type = "text",',
  '  label = "Ingrese su RUT (sin puntos ni guión)"',
  ")",
  "```",
  "",
  "```{r}",
  'sd_nav(label_next = "Comenzar diagnóstico")',
  "```",
  ""
)

datos <- read_excel(ruta_excel)
datos <- datos[rowSums(is.na(datos)) < ncol(datos), ]

col_numero <- if ("Nº" %in% names(datos)) "Nº" else if ("No" %in% names(datos)) "No" else names(datos)[1]
col_tipo <- buscar_columna(names(datos), "Tipo pregunta")
col_pregunta <- buscar_columna(names(datos), "Pregunta")
col_a <- buscar_columna(names(datos), "Alternativa a")
col_b <- buscar_columna(names(datos), "Alternativa b")
col_c <- buscar_columna(names(datos), "Alternativa c")
col_d <- buscar_columna(names(datos), "Alternativa d")

letras_cols <- list(a = col_a, b = col_b, c = col_c, d = col_d)

datos$numero_interno <- suppressWarnings(as.integer(datos[[col_numero]]))
if (any(is.na(datos$numero_interno))) {
  datos$numero_interno <- seq_len(nrow(datos))
}

datos <- datos[order(normalizar_texto(datos[[col_tipo]]), datos$numero_interno), ]

grupo_tipos <- split(datos, datos[[col_tipo]])

lineas <- encabezado
for (tipo in names(grupo_tipos)) {
  grupo <- grupo_tipos[[tipo]]
  pagina_id <- slugificar(tipo)

  lineas <- c(lineas, sprintf("--- %s", pagina_id), "", sprintf("# %s", tipo), "")

  for (i in seq_len(nrow(grupo))) {
    fila <- grupo[i, , drop = FALSE]

    if (file.exists("Graf_erroneo.png") && grepl("grafico|gráfico", as.character(fila[[col_pregunta]]), ignore.case = TRUE)) {
      lineas <- c(lineas, "## Observa la siguiente figura", "", "![](Graf_erroneo.png){fig-align=\"center\" width=\"70%\"}", "")
    }

    lineas <- c(lineas, crear_bloque_pregunta(fila, col_tipo, col_pregunta, letras_cols), "")
  }

  lineas <- c(lineas, "```{r}", 'sd_nav(label_next = "Continuar")', "```", "")
}

lineas <- c(
  lineas,
  "--- cierre",
  "",
  "# ¡Gracias por responder!",
  "",
  "```{r}",
  "sd_nav(show_previous = FALSE, show_next = FALSE)",
  "```",
  "",
  "```{r}",
  'sd_close(label_close = "Terminar", show_previous = FALSE)',
  "```",
  ""
)

writeLines(enc2utf8(lineas), ruta_salida, useBytes = TRUE)
cat(sprintf("Encuesta generada en '%s'.\n", ruta_salida))
