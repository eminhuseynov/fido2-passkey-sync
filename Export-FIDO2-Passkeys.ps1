# Export-FIDO2-Passkeys.ps1

$exePath = Join-Path $PSScriptRoot "fido2-manage.exe"
$outputDir = $PSScriptRoot

if (!(Test-Path $exePath)) {
    Write-Host ""
    Write-Host "ERROR: fido2-manage.exe not found in this folder!" -ForegroundColor Red
    exit 1
}

$keyName = Read-Host "Enter a name for this key (e.g., primary, backup1)"
if ([string]::IsNullOrWhiteSpace($keyName)) {
    Write-Host "ERROR: Key name cannot be empty." -ForegroundColor Red
    exit 1
}

# Masked PIN input
$pin = Read-Host "Enter the PIN for the key" -AsSecureString
$pinPlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pin))
if ([string]::IsNullOrWhiteSpace($pinPlainText)) {
    Write-Host "ERROR: PIN cannot be empty." -ForegroundColor Red
    exit 1
}

$outputFile = Join-Path $outputDir "$keyName.txt"

Write-Host "Reading all resident credentials from device 1..."
try {
    $credOutput = & $exePath -residentKeys -device 1 -pin $pinPlainText 2>&1
    if ($LASTEXITCODE -ne 0 -or $credOutput -match "error") {
        Write-Host "ERROR: Failed to retrieve credentials." -ForegroundColor Red
        Write-Host $credOutput
        exit 1
    }
} catch {
    Write-Host "ERROR: Unexpected error while listing credentials: $_" -ForegroundColor Red
    exit 1
}

# Filter relevant lines
$filtered = $credOutput | Where-Object { $_ -match 'User:' }
if ($filtered.Count -eq 0) {
    Write-Host "No resident credentials found on this key." -ForegroundColor Yellow
    exit 0
}

# Write output header
"Resident Keys on '$keyName' ($(Get-Date -Format 'yyyy-MM-dd HH:mm'))" | Out-File -Encoding UTF8 $outputFile
"`n--------------------------------------------`n" | Out-File -Append -Encoding UTF8 $outputFile

# Process each domain and write only domain and user to the file
$content = $filtered -join "`n"
$domains = [regex]::Matches($content, 'User:\s*(.+)') | ForEach-Object {
    $_.Groups[1].Value.Trim()
}

foreach ($domain in $domains) {
    Write-Host "Processing domain: $domain"
    try {
        $domainOutput = & $exePath -residentKeys -device 1 -domain $domain -pin $pinPlainText 2>&1
        if ($LASTEXITCODE -ne 0 -or $domainOutput -match "error") {
            Write-Host "ERROR: Failed to retrieve credentials for domain $domain." -ForegroundColor Red
            Write-Host $domainOutput
        } else {
            Write-Host "Successfully processed domain: $domain"
            # Extract and append only domain and user to the file
            $users = [regex]::Matches($domainOutput, 'User:\s*(.+)') | ForEach-Object {
                $_.Groups[1].Value.Trim()
            }
            foreach ($user in $users) {
				#Remove credential ID, they are unique per key, so we do not compare them
				$user = $user -replace ' Credential ID: [^,]+,?', "`nDomain: $domain,"
                "Domain: $domain, User: $user" | Out-File -Append -Encoding UTF8 $outputFile
            }
        }
    } catch {
        Write-Host "ERROR: Unexpected error while processing domain $domain`: $_" -ForegroundColor Red
    }
}

Write-Host "Done! Export saved to '$outputFile'" -ForegroundColor Green
