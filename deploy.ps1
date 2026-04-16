# Ir a carpeta lambda
Set-Location C:\terraform-testing\modules\lambda

# Borrar zip anterior si existe
if (Test-Path "lambda.zip") {
    Remove-Item "lambda.zip"
    Write-Host "Old zip removed"
}

# Crear nuevo zip con el código
Compress-Archive -Path "lambda_function.py" -DestinationPath "lambda.zip"

# Volver al directorio del script
Set-Location C:\terraform-testing

Write-Host "New lambda.zip created successfully"