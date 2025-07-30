# Prompt the user for the file paths
$filePath1 = Read-Host "Enter the path to the first text file"
$filePath2 = Read-Host "Enter the path to the second text file"

# Check if the files exist
if (-not (Test-Path $filePath1)) {
    Write-Host "File not found: $filePath1"
    exit
}
if (-not (Test-Path $filePath2)) {
    Write-Host "File not found: $filePath2"
    exit
}

# Read the contents of each file, skipping the first line
$content1 = Get-Content $filePath1 | Select-Object -Skip 1
$content2 = Get-Content $filePath2 | Select-Object -Skip 1

# Extract Domain and User pairs into arrays
$pairs1 = @()
foreach ($line in $content1) {
    if ($line -match "Domain:\s*(.*?),\s*User:\s*(.*)") {
        $pairs1 += "$($matches[1].Trim())|$($matches[2].Trim())"
    }
}

$pairs2 = @()
foreach ($line in $content2) {
    if ($line -match "Domain:\s*(.*?),\s*User:\s*(.*)") {
        $pairs2 += "$($matches[1].Trim())|$($matches[2].Trim())"
    }
}

# Compare sets
$onlyInFile1 = $pairs1 | Where-Object { $_ -notin $pairs2 }
$onlyInFile2 = $pairs2 | Where-Object { $_ -notin $pairs1 }

# Output differences
if ($onlyInFile1.Count -eq 0 -and $onlyInFile2.Count -eq 0) {
    Write-Host "No differences found. All Domain-User pairs match."
} else {
    if ($onlyInFile1.Count -gt 0) {
        Write-Host "`nPairs only in '$filePath1':"
        $onlyInFile1 | ForEach-Object { Write-Host "  $_" }
    }
    if ($onlyInFile2.Count -gt 0) {
        Write-Host "`nPairs only in '$filePath2':"
        $onlyInFile2 | ForEach-Object { Write-Host "  $_" }
    }
}
