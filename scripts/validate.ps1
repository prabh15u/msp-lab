$ErrorActionPreference = "Stop"
$repo = Split-Path $PSScriptRoot -Parent
Push-Location $repo
try {
    tofu fmt -check -recursive
    if ($LASTEXITCODE -ne 0) { throw "Formatting check failed" }
    foreach ($root in @("environments/bootstrap", "environments/github-identity", "customers/summit-property-management/lab")) {
        tofu "-chdir=$root" init -backend=false -input=false
        if ($LASTEXITCODE -ne 0) { throw "Initialization failed: $root" }
        tofu "-chdir=$root" validate
        if ($LASTEXITCODE -ne 0) { throw "Validation failed: $root" }
    }
} finally { Pop-Location }

