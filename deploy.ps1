$projectRoot = $PSScriptRoot
$lambdaPath  = Join-Path $projectRoot "modules\lambda"
$lambdaFile  = Join-Path $lambdaPath "lambda_function.py"
$zipFile     = Join-Path $lambdaPath "lambda.zip"

try {
    if (-not (Test-Path $lambdaFile)) {
        throw "No existe: $lambdaFile"
    }

    Remove-Item $zipFile -Force -ErrorAction SilentlyContinue

    Compress-Archive `
        -Path $lambdaFile `
        -DestinationPath $zipFile `
        -Force

    Write-Host "ZIP generado correctamente:"
    Write-Host $zipFile
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}