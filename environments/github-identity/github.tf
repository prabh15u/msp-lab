data "http" "github_repository" {
  url = "https://api.github.com/repos/${var.github_repository}"

  request_headers = {
    Accept                 = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
    "User-Agent"           = "msp-lab-opentofu"
  }
}

locals {
  github_repository_metadata = jsondecode(
    data.http.github_repository.response_body
  )
}