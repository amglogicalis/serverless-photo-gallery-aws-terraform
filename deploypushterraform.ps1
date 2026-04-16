# Terraform
terraform init

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error en terraform init"
    exit 1
}

terraform apply -auto-approve

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error en terraform apply"
    exit 1
}

# Git
git add .

git commit -m "New Update"

if ($LASTEXITCODE -eq 0) {
    git push origin main
} else {
    Write-Host "No hay cambios para commitear"
}