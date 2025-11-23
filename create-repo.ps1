# GitHub Repository Creation Script
# This script creates a GitHub repository using the GitHub API

param(
    [Parameter(Mandatory=$true)]
    [string]$Token,
    
    [Parameter(Mandatory=$false)]
    [string]$RepoName = "k8sgitops",
    
    [Parameter(Mandatory=$false)]
    [string]$Username = "murtadah-1984",
    
    [Parameter(Mandatory=$false)]
    [switch]$Private = $false
)

$headers = @{
    "Authorization" = "token $Token"
    "Accept" = "application/vnd.github.v3+json"
}

$body = @{
    name = $RepoName
    description = "Helm-centric GitOps repository with ArgoCD for Kubernetes platform management"
    private = $Private
    auto_init = $false
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Method Post -Headers $headers -Body $body -ContentType "application/json"
    Write-Host "✅ Repository created successfully!" -ForegroundColor Green
    Write-Host "Repository URL: $($response.html_url)" -ForegroundColor Cyan
    Write-Host "Clone URL: $($response.clone_url)" -ForegroundColor Cyan
    
    # Add remote and push
    Write-Host "`nAdding remote and pushing..." -ForegroundColor Yellow
    git remote add origin $response.clone_url
    git push -u origin main
    
    Write-Host "`n✅ Done! Repository is now on GitHub." -ForegroundColor Green
} catch {
    Write-Host "❌ Error creating repository: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "Authentication failed. Please check your token." -ForegroundColor Red
    }
}

