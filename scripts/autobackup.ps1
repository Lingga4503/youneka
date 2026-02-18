# Auto-backup git worktree to a dedicated branch.
# Usage:  ./scripts/autobackup.ps1 [-Branch autobackup] [-IntervalSeconds 300]
param(
  [string]$Branch = "autobackup",
  [int]$IntervalSeconds = 300
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Info($msg) {
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Write-Host "[$ts] $msg"
}

Write-Info "Starting auto-backup to branch '$Branch' every $IntervalSeconds seconds. Press Ctrl+C to stop."

while ($true) {
  try {
    # Skip if no changes.
    $status = git status --porcelain
    if (-not $status) {
      Start-Sleep -Seconds $IntervalSeconds
      continue
    }

    # Ensure branch exists and is checked out locally.
    $current = (git rev-parse --abbrev-ref HEAD).Trim()
    if ($current -ne $Branch) {
      if (-not (git show-ref --verify --quiet "refs/heads/$Branch")) {
        git checkout -b $Branch
      } else {
        git checkout $Branch
      }
    }

    git add -A
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    git commit -m "auto-backup $timestamp" | Out-Null
    git push -u origin $Branch
    Write-Info "Pushed auto-backup commit to '$Branch'."

    # Return to original branch if it was different.
    if ($current -ne $Branch) {
      git checkout $current | Out-Null
    }
  } catch {
    Write-Host "Error: $_" -ForegroundColor Red
  }

  Start-Sleep -Seconds $IntervalSeconds
}
