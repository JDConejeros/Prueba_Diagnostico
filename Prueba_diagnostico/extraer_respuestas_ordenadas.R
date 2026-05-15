# Extrae nombre, RUT y respuestas de preguntas en orden (q01, q02, ...)

library(surveydown)
library(readxl)

archivo_salida <- "respuestas_ordenadas.csv"
archivo_pauta <- "Pauta_prueba.xlsx"
guardar_copia_origen <- TRUE

# Lee datos de respuestas desde la base (origen)
db <- sd_db_connect()
resultados <- sd_get_data(db)

if (guardar_copia_origen) {
  archivo_origen <- sprintf("resultados_encuesta_%s.csv", format(Sys.Date(), "%Y%m%d"))
  write.csv(resultados, archivo_origen, row.names = FALSE, fileEncoding = "UTF-8")
}

# Detecta columnas de preguntas tipo q1_..., q01_..., q10_..., q100_...
cols_preguntas <- grep("^q[0-9]+_", names(resultados), value = TRUE)

if (length(cols_preguntas) == 0) {
  stop("No se encontraron columnas de preguntas con formato q<number>_.", call. = FALSE)
}

# Ordena preguntas por el numero detectado en el identificador
num_pregunta <- as.integer(sub("^q([0-9]+)_.*$", "\\1", cols_preguntas))
cols_preguntas_ordenadas <- cols_preguntas[order(num_pregunta)]

# Define columnas de identificacion
cols_identificacion <- grep("^identificacion", names(resultados), value = TRUE)

if (length(cols_identificacion) == 0) {
  stop("No se encontraron columnas de identificacion con prefijo 'identificacion'.", call. = FALSE)
}

faltantes <- setdiff(cols_identificacion, names(resultados))
if (length(faltantes) > 0) {
  stop(
    sprintf("Faltan columnas requeridas: %s", paste(faltantes, collapse = ", ")),
    call. = FALSE
  )
}

# Arma tabla final
salida <- resultados[, c(cols_identificacion, cols_preguntas_ordenadas), drop = FALSE]

# Lee pauta y calcula nivel de exito
pauta <- read_excel(archivo_pauta)

if (!("Alternativa correcta" %in% names(pauta))) {
  stop("La pauta debe contener la columna 'Alternativa correcta'.", call. = FALSE)
}

respuestas_correctas <- tolower(trimws(as.character(pauta[["Alternativa correcta"]])))
respuestas_correctas <- respuestas_correctas[!is.na(respuestas_correctas) & nzchar(respuestas_correctas)]

if (length(respuestas_correctas) < length(cols_preguntas_ordenadas)) {
  stop(
    sprintf(
      "La pauta tiene %s respuestas correctas, pero se detectaron %s preguntas.",
      length(respuestas_correctas),
      length(cols_preguntas_ordenadas)
    ),
    call. = FALSE
  )
}

respuestas_correctas <- respuestas_correctas[seq_along(cols_preguntas_ordenadas)]

resp_estudiante <- as.matrix(salida[, cols_preguntas_ordenadas, drop = FALSE])
resp_estudiante <- tolower(trimws(resp_estudiante))

aciertos_detalle <- sweep(resp_estudiante, 2, respuestas_correctas, FUN = "==")
aciertos_detalle[is.na(aciertos_detalle)] <- FALSE

salida$cantidad_respuestas_correctas <- rowSums(aciertos_detalle)
salida$porcentaje_logro <- round(
  100 * salida$cantidad_respuestas_correctas / length(cols_preguntas_ordenadas),
  2
)

# Exporta resultado
write.csv(salida, archivo_salida, row.names = FALSE, fileEncoding = "UTF-8")

cat(sprintf("Archivo creado: %s\n", archivo_salida))
cat(sprintf("Filas: %s | Preguntas: %s\n", nrow(salida), length(cols_preguntas_ordenadas)))
cat("Se agregaron columnas: cantidad_respuestas_correctas y porcentaje_logro\n")
if (guardar_copia_origen) {
  cat(sprintf("Copia de origen guardada: %s\n", archivo_origen))
}
