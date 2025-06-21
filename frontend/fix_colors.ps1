Write-Host "Fixing withValues to withOpacity across all Dart files..."

# Get all Dart files in lib directory
$dartFiles = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse

$totalReplacements = 0

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    
    # Replace .withValues(alpha: X) with .withOpacity(X)
    $content = $content -replace '\.withValues\(alpha:\s*([0-9]*\.?[0-9]+)\)', '.withOpacity($1)'
    
    if ($content -ne $originalContent) {
        # Count replacements
        $replacements = ([regex]::Matches($originalContent, '\.withValues\(alpha:')).Count
        $totalReplacements += $replacements
        
        # Write back to file
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Host "Fixed $replacements instances in: $($file.FullName)"
    }
}

Write-Host "✅ Fixed $totalReplacements withValues usages across $($dartFiles.Count) files"

# Check for any remaining issues
Write-Host "`nRunning Flutter analyze to check for remaining issues..."
flutter analyze | Select-String -Pattern "(error|warning)" | Select-Object -First 20 