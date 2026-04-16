$originalPath = Get-Location

try {
    Set-Location C:\terraform-testing\modules\lambda

    if (Test-Path "lambda.zip") {
        Remove-Item "lambda.zip" -Force
        Write-Host "Old zip removed"
    }

    Compress-Archive -Path "lambda_function.py" -DestinationPath "lambda.zip"

    Write-Host "New lambda.zip created successfully"
}
finally {
    Set-Location $originalPath
}