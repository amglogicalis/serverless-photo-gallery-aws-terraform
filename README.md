**CREA UNA PÁGINA WEB SERVERLESS PARA REGISTRAR Y CREAR USUARIOS, QUE INICIARAN SESIÓN Y PODRÁN ACCEDER A UN MURAL PÚBLICO DE FOTOS DONDE SUBIR SUS FOTOS Y PONDRÁ DE QUE USUARIO ES CADA FOTO USANDO AWS LAMBDA, DYNAMO DB Y S3**

Tambien adjunto una serie de scripts de utilidad:

**awsconfigure.ps1**: es un script que al ejecutarlo permite crear y configurar usuarios y sus credenciales de aws a través de una interfaz gráfica, además también sirve para validar las credenciales

**deploy.ps1**: es un script que al ejecutarlo actualiza el zip de lambda, eliminando el actual y repaquetando el archivo .py de lambda

**deploypushterraform.ps1**: es un script que al ejecutarlo permite iniciar terraform y aplicar los cambios hechos, acto seguido sube y actualiza los cambios al repositorio.
