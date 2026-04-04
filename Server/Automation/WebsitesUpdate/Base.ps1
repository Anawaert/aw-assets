# This script is used to trigger other PowerShell scripts for implementing automation requirements.

# The script accepts the following parameter(s):
# - repoName: represents the name of the GitHub repository.
param (
    [string]$repoName
)

# 重定向控制台输出至 .\Logs\WebsiteUpdateLog.log 中
$logFile = (Join-Path $PSScriptRoot "Logs\WebsiteUpdateLog.log")
Start-Transcript -Path $logFile -Append

Write-Host $HOME

try 
{
    # If repoName contains "Blog", trigger the blog automation script, same to other automation scripts.
    if ($repoName -match "Blog") 
    {
        & (Join-Path $PSScriptRoot "UpdateBlog.ps1")
    }
    # elseif ($repoName -match "Tree-Hollow") 
    # {
    #     & (Join-Path $PSScriptRoot "UpdateTreeHollow.ps1")
    # }
    elseif ($repoName -match "docs") 
    {
        & (Join-Path $PSScriptRoot "UpdateDocs.ps1")
    }
    else 
    {
        Write-Host "BASE [$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] No matching automation script found."
    }    
}
catch 
{
    Write-Host "BASE [$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Errors occurred while executing the base script: $_"
}

# Stop redirecting console output
Stop-Transcript
