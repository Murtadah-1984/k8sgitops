# Quick GitHub Repository Creation
# Run this script and follow the prompts

Write-Host "=== GitHub Repository Creator ===" -ForegroundColor Cyan
Write-Host ""

# Get repository name
$repoName = "k8sgitops"
$username = "murtadah-1984"

Write-Host "Repository will be created as: $username/$repoName" -ForegroundColor Yellow
Write-Host ""

# Check if remote already exists
$existingRemote = git remote get-url origin 2>$null
if ($existingRemote) {
    Write-Host "⚠️  Remote 'origin' already exists: $existingRemote" -ForegroundColor Yellow
    $overwrite = Read-Host "Do you want to remove it and create new? (y/n)"
    if ($overwrite -eq "y") {
        git remote remove origin
    } else {
        Write-Host "Cancelled." -ForegroundColor Red
        exit
    }
}

Write-Host ""
Write-Host "To create the repository, you have two options:" -ForegroundColor Cyan
Write-Host ""
Write-Host "OPTION 1: Create via Web (30 seconds)" -ForegroundColor Green
Write-Host "1. Go to: https://github.com/new" -ForegroundColor White
Write-Host "2. Repository name: $repoName" -ForegroundColor White
Write-Host "3. Description: Helm-centric GitOps repository with ArgoCD" -ForegroundColor White
Write-Host "4. Choose Private or Public" -ForegroundColor White
Write-Host "5. DO NOT check 'Initialize with README'" -ForegroundColor White
Write-Host "6. Click 'Create repository'" -ForegroundColor White
Write-Host ""
Write-Host "Then run these commands:" -ForegroundColor Yellow
Write-Host "  git remote add origin https://github.com/$username/$repoName.git" -ForegroundColor White
Write-Host "  git push -u origin main" -ForegroundColor White
Write-Host ""
Write-Host "OPTION 2: Use Personal Access Token (automated)" -ForegroundColor Green
Write-Host "1. Create token at: https://github.com/settings/tokens/new" -ForegroundColor White
Write-Host "2. Check 'repo' scope" -ForegroundColor White
Write-Host "3. Copy the token (starts with ghp_)" -ForegroundColor White
Write-Host "4. Run: .\create-repo.ps1 -Token YOUR_TOKEN" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Have you created the repo via web? (y/n)"
if ($choice -eq "y") {
    Write-Host ""
    Write-Host "Adding remote and pushing..." -ForegroundColor Yellow
    git remote add origin "https://github.com/$username/$repoName.git"
    git push -u origin main
    Write-Host ""
    Write-Host "✅ Done! Check your repo at: https://github.com/$username/$repoName" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Please create the repository first, then run this script again." -ForegroundColor Yellow
}

