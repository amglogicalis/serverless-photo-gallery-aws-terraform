# HEALTHCHECK.md

## Recursos Serverless Creados

### 1. Lambda Function
- **Nombre**: `serverless-photo-gallery-aws-terraform-lambda`
- **Descripción**: Función Lambda que maneja las solicitudes a la API Gateway.
- **Dependencias**:
  - S3 Bucket para almacenamiento de imágenes.
  - DynamoDB Table para almacenamiento de metadatos.

### 2. S3 Bucket
- **Nombre**: `serverless-photo-gallery-aws-terraform-bucket`
- **Descripción**: Almacena las imágenes subidas por los usuarios.
- **Dependencias**:
  - Lambda Function para procesar las imágenes y guardarlas en el bucket.

### 3. DynamoDB Table
- **Nombre**: `serverless-photo-gallery-aws-terraform-table`
- **Descripción**: Almacena metadatos de las imágenes, como URL pública.
- **Dependencias**:
  - Lambda Function para leer y escribir datos en la tabla.

### 4. API Gateway
- **URL**: `https://xxxxxxxx.execute-api.aws...` (proporcionada por Terraform)
- **Descripción**: Endpoint público que expone las operaciones de la aplicación.
- **Dependencias**:
  - Lambda Function para manejar las solicitudes a través de la API Gateway.

## Comandos Recomendados de Depuración

### 1. Verificar Estado de los Recursos
```bash
aws cloudformation describe-stack-events --stack-name serverless-photo-gallery-aws-terraform
```

### 2. Verificar Logs de Lambda
```bash
aws logs get-log-events --log-group-name /aws/lambda/serverless-photo-gallery-aws-terraform-lambda --start-time $(date +%s)
```

### 3. Probar la API Gateway
Puedes usar `curl` o herramientas como Postman para probar las operaciones de la API Gateway.

#### Ejemplo con `curl`:
```bash
curl -X POST https://xxxxxxxx.execute-api.aws.../endpoint -H "Content-Type: application/json" -d '{"key": "value"}'
```

### 4. Verificar el Bucket S3
Puedes usar el AWS Management Console o la CLI para listar los objetos en el bucket.

#### Ejemplo con `aws s3 ls`:
```bash
aws s3 ls s3://serverless-photo-gallery-aws-terraform-bucket/
```

### 5. Verificar la Tabla DynamoDB
Puedes usar el AWS Management Console o la CLI para consultar los datos en la tabla.

#### Ejemplo con `aws dynamodb scan`:
```bash
aws dynamodb scan --table-name serverless-photo-gallery-aws-terraform-table
```

---
