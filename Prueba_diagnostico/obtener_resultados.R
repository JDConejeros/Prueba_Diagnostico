library(surveydown)

# Requiere que exista .env configurado con sd_db_config()
db <- sd_db_connect()

# Obtiene respuestas desde la tabla definida en .env
resultados <- sd_get_data(db)

# Guarda copia local con fecha
archivo_salida <- sprintf("resultados_encuesta_%s.csv", format(Sys.Date(), "%Y%m%d"))
write.csv(resultados, archivo_salida, row.names = FALSE, fileEncoding = "UTF-8")

cat(sprintf("Se descargaron %s respuestas.\n", nrow(resultados)))
cat(sprintf("Archivo guardado: %s\n", archivo_salida))
