variable "application_name" {
  type        = string
  description = "Display name of the GitHub application."
}

variable "github_repository" {
  type        = string
  description = "Exact GitHub owner/repository."
}

variable "github_environment" {
  type        = string
  description = "Exact GitHub environment name."
}

variable "github_owner_id" {
  type        = string
  description = "Numeric GitHub owner ID."
}

variable "github_repository_id" {
  type        = string
  description = "Numeric GitHub repository ID."
}