# Update the blog post(s) with the latest content.

# Split lines
Write-Host '--------------------------------'

# Change directory to blog source location
Set-Location -Path (Join-Path $HOME "Hugo-Projects\Anawaert-Blog")

# Default remote repository
$remoteSSHRepo = git remote get-url origin
$remoteSSHRepo443 = "ssh://" + $remoteSSHRepo -replace "github.com[:/]", "ssh.github.com:443/"
Write-Host "UB [$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Current default remote repository: $remoteSSHRepo"
Write-Host "UB [$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Current default remote repository on port 443: $remoteSSHRepo443"

# Test 22 port first. If it is not reachable, fallback to 443.
$testRetVal = Test-NetConnection "github.com" -Port 22 -WarningAction SilentlyContinue -InformationLevel Quiet
if (-not $testRetVal.TcpTestSucceeded)
{
    Write-Host "UB [$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Failed to connect to GitHub on port 22. Falling back to port 443."
    git remote set-url origin $remoteSSHRepo443
}

# Try to pull the latest changes from the repository.
# If failed, try it for at most 5 times.
$maxAttempts = 3
$attempt = 0
$success = $false
$alreadyUpToDate = $false

while (-not $success -and $attempt -lt $maxAttempts) 
{
    try 
    {
        # Convert output to string type. If the output string contains "timed out", "can't be established", etc, retry it again.
        $pullRetVal = git pull origin master 2>&1
        Write-Host "UB [$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Result of git pull: $pullRetVal"
        if ($pullRetVal -match "timed out|can't be established|Permission denied") 
        {
            throw $pullRetVal
        }
        if ($pullRetVal -match "up to date") 
        {
            Write-Host "UB [$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] No new changes found. Blog is already up to date."
            $alreadyUpToDate = $true
        }
        $success = $true
    } 
    catch 
    {
        $attempt++
        Write-Host "UB [$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Error occurred while pulling changes: $pullRetVal. Retried $attempt times."
        Start-Sleep -Seconds 3
    }
}

# if it is still unsuccessful but it has attempted for 5 times, give up the update and display the error message
if (-not $success) 
{
    Write-Host "UB [$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Failed to pull latest changes of Anawaert-Blog after $maxAttempts attempts."
}

try 
{
    # If local repository is already up to date, skip Hugo build and other operations.
    if ($alreadyUpToDate) 
    {
        Write-Host "UB [$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Local repository is already up to date. Skipping Hugo build."
    }
    else 
    {
        # Run Hugo command to compile the blog
        hugo

        # Copy ./public to expected location
        Copy-Item -Recurse -Force .\public (Join-Path $HOME "Website\Anawaert Blog")

        # Run npm for updating search indices
        npm run algolia

        # Display success message on console
        Write-Host "UB [$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Blog updated successfully."
    }
}
catch 
{
    # Display error message on console
    Write-Host "UB [$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Error occurred while updating blog: $_"
}
finally 
{
    # Clean up the complied files if they exist.
    # Recover the default SSH repository address
    if (Test-Path .\public) 
    {
        Remove-Item -Recurse -Force .\public
    }
    
    $currentRepo = git remote get-url origin
    if ($currentRepo -ne $remoteSSHRepo)
    {
        git remote set-url origin $remoteSSHRepo
    }
}
