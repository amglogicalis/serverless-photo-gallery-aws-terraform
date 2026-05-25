# Comprueba si Terraform está instalado
$terraform = Get-Command terraform -ErrorAction SilentlyContinue

if ($terraform) {
    Write-Host "Terraform ya está instalado:"
    terraform -version
}
else {
    Write-Host "Terraform no encontrado. Instalando..."
    winget install --id HashiCorp.Terraform -e --silent
}

Write-Host ""

# Comprueba si AWS CLI está instalado
$aws = Get-Command aws -ErrorAction SilentlyContinue

if ($aws) {
    Write-Host "AWS CLI ya está instalado:"
    aws --version
}
else {
    Write-Host "AWS CLI no encontrado. Instalando..."
    winget install --id Amazon.AWSCLI -e --silent
}

Write-Host ""
Write-Host "Comprobacion final..."

# Verificación final
try {
    terraform -version
} catch {
    Write-Host "Terraform sigue sin estar disponible."
}

try {
    aws --version
} catch {
    Write-Host "AWS CLI sigue sin estar disponible."
}