# 📸 INSTRUCCIONES PROYECTO AWS + TERRAFORM
# Página web serverless para registro de usuarios y mural público de fotos

*ANTES DE NADA ESTE PROYECTO NO ES COMPATIBLE CON ENTORNOS SANDBOX DE AWS*

Este proyecto despliega automáticamente una aplicación web serverless donde:

- Los usuarios pueden **registrarse e iniciar sesión**
- Cada usuario puede **subir fotos**
- Existe un **mural público compartido**
- Cada imagen muestra qué usuario la ha subido
- Se utilizan servicios AWS:

```text
AWS Lambda
AWS API Gateway
AWS DynamoDB
AWS S3
Terraform
```

---

# 📥 Preparación inicial del entorno

Antes de desplegar el proyecto debes instalar Git, crear una carpeta de trabajo y clonar el repositorio.

---

# 0️⃣ Instalar Git (necesario para clonar el repositorio)

## Instalar Git automáticamente con Winget

Abrir PowerShell/CMD como administrador y ejecutar:

```powershell
winget install Git.Git
```

Comprobar instalación:

```powershell
git --version
```

Debe mostrar algo parecido a:

```text
git version 2.xx.x.windows.x
```

---

## Si Winget no funciona

Descargar Git manualmente desde:

```text
https://git-scm.com/downloads
```

Instalar con configuración por defecto.

---

# 1️⃣ Crear una carpeta para el proyecto

Abrir PowerShell o CMD y moverse al escritorio:

```powershell
cd $HOME\Desktop
```

Crear carpeta:

```powershell
mkdir mis-proyectos
```

Entrar:

```powershell
cd .\mis-proyectos\
```

Puedes usar cualquier ubicación.

Ejemplo:

```text
C:\mis-proyectos\
D:\desarrollo\
```

---

# 2️⃣ Clonar el repositorio

Dentro de la carpeta donde guardarás el proyecto:

Ejecutar:

```powershell
git clone URL_DEL_REPOSITORIO
```

Ejemplo:

```powershell
git clone https://github.com/usuario/proyecto.git
```

Git descargará todos los archivos.

---

# 3️⃣ Entrar al proyecto

Después del clonado:

```powershell
cd nombre-del-repositorio
```

Ejemplo:

```powershell
cd serverless-photo-gallery-aws-terraform
```

Comprobar archivos:

```powershell
dir
```

Deberías ver algo parecido:

```text
modules/
scripts/
terraform/
README.md
terraform.tfvars.example
deploy.ps1
```

---

# ✅ Entorno preparado

A partir de aquí ya puedes continuar con:

```powershell
.\instalar-herramientas-necesarias.ps1
```

y seguir el resto del documento.

---

# ⚙️ Cómo ejecutar scripts

## En PowerShell (recomendado ejecutarlo como administrador para evitar errores)

Ejecutar scripts desde el directorio:

```powershell
.\nombre-del-script.ps1
```

Ejemplo:

```powershell
.\deploy.ps1
```

---

## En el CMD (recomendado ejecutarlo como administrador para evitar errores)

Si PowerShell bloquea scripts:

```cmd
powershell.exe -ExecutionPolicy Bypass -File "C:\Ruta\De\Tu\Script.ps1"
```

Ejemplo:

```cmd
powershell.exe -ExecutionPolicy Bypass -File ".\deploy.ps1"
```

---

# 🚀 PASOS PARA DESPLEGAR EL PROYECTO

---

# 1️⃣ Instalar herramientas necesarias

Ejecuta:

```powershell
.\instalar-herramientas-necesarias.ps1
```

Este script comprobará si existen:

- AWS CLI
- Terraform

Si faltan, los instalará automáticamente.

Tras instalar:

⚠️ **Cierra y vuelve a abrir CMD o PowerShell en el mismo directorio antes de continuar**

---

# 2️⃣ Configurar credenciales AWS

*(Omite este paso si ya tienes un perfil AWS configurado)*

Ejecuta:

```powershell
.\awsconfigure.ps1
```

Este script abrirá una interfaz gráfica donde podrás:

- Crear perfiles AWS
- Editarlos
- Validar credenciales

Necesitarás:

```text
AWS Access Key
AWS Secret Key
Región
Nombre del perfil
```

Las credenciales pueden obtenerse:

### Cuenta AWS normal:

Perfil → Security Credentials

---

### Learner Lab / Vocareum:

Botón:

```text
AWS Details
```

dentro del ejecutor del laboratorio.

---

# 3️⃣ Configurar terraform.tfvars

Haz una copia:

```text
terraform.tfvars.example
```

Renómbrala:

```text
terraform.tfvars
```

Rellena:

```hcl
project_name = "mi-proyecto"

aws_region = "us-east-1"

aws_profile = "personal"

role_arn =
"arn:aws:iam::<ACCOUNT_ID>:role/NombreRole"
```

Debes indicar:

### project_name

Nombre base del proyecto.

Ejemplo:

```text
demo
```

---

### aws_region

Región AWS.

Ejemplo:

```text
us-east-1
eu-west-1
```

---

### aws_profile

"Perfil AWS configurado anteriormente."

---

### role_arn (si no tienes ninguno en una cuenta recién creada, baja al final de los pasos para la guía de como crear el role)

ARN del IAM Role con permisos sobre:

```text
Lambda
S3
DynamoDB
API Gateway
IAM
CloudWatch
Terraform
```

---

## Caso Learner Lab / Vocareum

Normalmente existe:

```text
voclabs
```

Para encontrarlo:

```text
AWS
→ IAM
→ Roles
→ buscar "voclabs"
```

Abrir:

```text
voclabs
```

Copiar:

```text
ARN:
arn:aws:iam::<ACCOUNT_ID>:role/voclabs
```

Pegar en:

```hcl
role_arn =
"arn:aws:iam::<ACCOUNT_ID>:role/voclabs"
```

---

# 4️⃣ Generar ZIP de Lambda

Ejecutar:

```powershell
.\deploy.ps1
```

El script:

- Elimina ZIP anterior (si existe, si no lo crea)
- Reempaqueta Lambda
- Genera nuevo `lambda.zip`

---

# 5️⃣ Inicializar Terraform

Abrir terminal en la raíz del proyecto:

Ejecutar:

```bash
terraform init
```

Después:

```bash
terraform apply
```

---

Si Terraform falla o queda esperando:

Ejecutar:

```bash
terraform apply -auto-approve
```

---

# ✅ Resultado final

Terraform desplegará:

```text
S3 Bucket
Lambda
API Gateway
DynamoDB
IAM
Permisos
```

Al finalizar devolverá:

```text
URL:
https://xxxxxxxx.execute-api.aws...
```

Esa URL será la aplicación lista para usar.

---

*En caso de querer borrar lo creado ejecuta en el cmd/powershell del proyecto "terraform destroy" o "terraform destroy -auto-approve"*

---

# 🔐 Crear un IAM Role con permisos de administrador

*(Solo necesario si NO tienes un rol válido)*

---

## Paso 1 — Abrir IAM

Buscar:

```text
IAM
```

Entrar en:

```text
Identity and Access Management
```

---

## Paso 2 — Crear Role

Ir a:

```text
Access Management
→ Roles
→ Create Role
```

Seleccionar:

```text
AWS Service
```

Caso de uso:

```text
Lambda
```

---

## Paso 3 — Añadir permisos

Buscar:

```text
AdministratorAccess
```

Seleccionar:

```text
AdministratorAccess
```

Esto permite acceso a:

```text
Lambda
S3
DynamoDB
IAM
API Gateway
CloudWatch
Terraform
etc.
```

---

## Paso 4 — Nombre del rol

Ejemplo:

```text
TerraformAdminRole
```

Crear:

```text
Create Role
```

---

## Paso 5 — Obtener ARN

Abrir:

```text
IAM
→ Roles
→ TerraformAdminRole
```

Copiar:

```text
ARN:

arn:aws:iam::<ACCOUNT_ID>:role/TerraformAdminRole
```

Usar en:

```hcl
role_arn =
"arn:aws:iam::<ACCOUNT_ID>:role/TerraformAdminRole"
```

---

# 📜 Explicación de scripts

---

## awsconfigure.ps1

Permite:

- Crear perfiles AWS
- Configurar credenciales
- Validar acceso

---

## deploy.ps1

Permite:

- Eliminar ZIP Lambda anterior
- Reempaquetar Lambda
- Actualizar `lambda.zip`

---

## deploypushterraform.ps1

Permite:

1. Ejecutar Terraform
2. Aplicar cambios
3. Actualizar repositorio automáticamente

---

## instalar-herramientas-necesarias.ps1

Instala automáticamente:

```text
Terraform
AWS CLI
```

si no existen.

---

# 🎯 Proyecto listo para desplegar

Tras completar todos los pasos:

```bash
terraform apply -auto-approve
```

La aplicación quedará publicada automáticamente en AWS.