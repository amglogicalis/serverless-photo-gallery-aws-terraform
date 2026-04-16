variable "project_name" {
  type        = string
  description = "Nombre base del proyecto. Se usa como prefijo para nombrar todos los recursos."
  default     = "demo"
}

variable "aws_region" {
  type        = string
  description = "Region de AWS donde se desplegara la infraestructura."
  default     = "us-east-1"
}

variable "aws_profile" {
  type        = string
  description = "Perfil de AWS a usar para la autenticacion (configurado en ~/.aws/credentials)."
  default     = "default"
}

variable "role_arn" {
  type        = string
  description = "ARN del IAM Role que se asignara a la funcion Lambda. Debe existir en tu cuenta de AWS."
}
