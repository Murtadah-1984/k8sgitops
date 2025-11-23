# Quick push script - Run this after creating the repo on GitHub

Write-Host "Pushing to GitHub..." -ForegroundColor Yellow

# Remove existing remote if it exists
git remote remove origin 2>$null

# Add remote
git remote add origin https://github.com/murtadah-1984/k8sgitops.git

# Push
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Successfully pushed to GitHub!" -ForegroundColor Green
    Write-Host "Repository: https://github.com/murtadah-1984/k8sgitops" -ForegroundColor Cyan
} else {
    Write-Host "`n❌ Push failed. Make sure you:" -ForegroundColor Red
    Write-Host "1. Created the repository at https://github.com/new" -ForegroundColor Yellow
    Write-Host "2. Repository name is exactly: k8sgitops" -ForegroundColor Yellow
    Write-Host "3. You're logged into GitHub" -ForegroundColor Yellow
}

