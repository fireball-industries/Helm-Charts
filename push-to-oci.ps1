# Push all Helm charts to OCI registry
# Compatible with Helm v3.x and v4.x - Modern Rancher OCI standard
# 
# REQUIREMENTS:
#   - Helm v3.x or v4.x installed
#   - Valid OCI registry credentials
#   - Chart.yaml in each chart directory

param(
    [Parameter(Mandatory=$true)]
    [string]$Registry,  # e.g., "ghcr.io/fireball-industries"
    
    [Parameter(Mandatory=$false)]
    [string]$Username,
    
    [Parameter(Mandatory=$false)]
    [string]$Password
)

$ErrorActionPreference = "Stop"

# Verify Helm is installed
Write-Host "Verifying Helm installation..." -ForegroundColor Cyan
try {
    $helmVersionOutput = helm version 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        throw "Helm not found"
    }
    
    # Extract version from output (works for both v3 and v4)
    if ($helmVersionOutput -match 'Version:"v?([0-9]+\.[0-9]+\.[0-9]+[^"]*)"') {
        $helmVersion = $matches[1]
        Write-Host "✓ Helm v$helmVersion detected" -ForegroundColor Green
    } else {
        Write-Host "✓ Helm found (version detection skipped)" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ ERROR: Helm is not installed or not in PATH" -ForegroundColor Red
    Write-Host "`nInstall Helm: https://helm.sh/docs/intro/install/" -ForegroundColor Yellow
    exit 1
}

# Login to OCI registry
if ($Username -and $Password) {
    Write-Host "`nLogging into $Registry..." -ForegroundColor Cyan
    try {
        # Works with both Helm v3 and v4
        $Password | helm registry login $Registry --username $Username --password-stdin 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Login command failed"
        }
        Write-Host "✓ Authenticated to $Registry" -ForegroundColor Green
    } catch {
        Write-Host "✗ Registry login failed: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "`nNo credentials provided - using existing authentication..." -ForegroundColor Yellow
    Write-Host "(Run 'helm registry login $Registry' first if needed)" -ForegroundColor Gray
}

# Get script directory and construct absolute paths
$scriptDir = $PSScriptRoot
if (-not $scriptDir) {
    $scriptDir = Get-Location
}

$chartsDir = Join-Path $scriptDir "charts"
$distPath = Join-Path $scriptDir "dist"

# Verify charts directory exists
if (-not (Test-Path $chartsDir)) {
    Write-Host "✗ ERROR: charts/ directory not found at: $chartsDir" -ForegroundColor Red
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Gray
    exit 1
}

# Ensure dist directory exists
if (-not (Test-Path $distPath)) {
    New-Item -ItemType Directory -Path $distPath -Force | Out-Null
}

$charts = Get-ChildItem -Path $chartsDir -Directory

Write-Host "`n" + ("=" * 80) -ForegroundColor Gray
Write-Host "Packaging and pushing $($charts.Count) charts to: $Registry" -ForegroundColor Green
Write-Host ("=" * 80) -ForegroundColor Gray

$successCount = 0
$failCount = 0

foreach ($chart in $charts) {
    $chartName = $chart.Name
    $chartYamlPath = Join-Path $chart.FullName "Chart.yaml"
    
    # Verify Chart.yaml exists (Helm v4 is stricter about this)
    if (-not (Test-Path $chartYamlPath)) {
        Write-Host "`n[$chartName] ✗ SKIP - Chart.yaml not found at $chartYamlPath" -ForegroundColor Red
        $failCount++
        continue
    }
    
    # Extract version from Chart.yaml
    try {
        $chartYaml = Get-Content $chartYamlPath -Raw -ErrorAction Stop
        if ($chartYaml -match '(?m)^version:\s*["\']?([^"\'\r\n]+)["\']?') {
            $version = $matches[1].Trim()
        } else {
            Write-Host "`n[$chartName] ✗ SKIP - No version found in Chart.yaml" -ForegroundColor Red
            $failCount++
            continue
        }
    } catch {
        Write-Host "`n[$chartName] ✗ SKIP - Failed to read Chart.yaml: $_" -ForegroundColor Red
        $failCount++
        continue
    }
    
    Write-Host "`n[$chartName] v$version" -ForegroundColor Yellow
    Write-Host "  Chart path: $($chart.FullName)" -ForegroundColor Gray
    
    # Package chart - works with Helm v3.x and v4.x
    # CRITICAL: Use absolute path and -d flag (not --destination for v3 compatibility)
    Write-Host "  - Packaging..." -NoNewline
    try {
        # Change to chart directory to avoid path issues
        Push-Location $chart.FullName
        
        # Package from current directory (.) to absolute dist path
        $packageOutput = helm package . -d "$distPath" 2>&1 | Out-String
        $packageExitCode = $LASTEXITCODE
        
        Pop-Location
        
        if ($packageExitCode -ne 0) {
            throw "Packaging failed (exit code $packageExitCode): $packageOutput"
        }
        Write-Host " ✓" -ForegroundColor Green
    } catch {
        Pop-Location -ErrorAction SilentlyContinue
        Write-Host " ✗ FAILED" -ForegroundColor Red
        Write-Host "    Error: $_" -ForegroundColor Red
        $failCount++
        continue
    }
    
    # Push to OCI registry - works with Helm v3.x and v4.x
    # Syntax: helm push <CHART_PACKAGE> oci://<REGISTRY>
    $packageFile = Join-Path $distPath "$chartName-$version.tgz"
    
    if (-not (Test-Path $packageFile)) {
        Write-Host "  - Push... ✗ Package file not found: $packageFile" -ForegroundColor Red
        $failCount++
        continue
    }
    
    Write-Host "  - Pushing to OCI..." -NoNewline
    try {
        $pushOutput = helm push "$packageFile" "oci://$Registry" 2>&1 | Out-String
        $pushExitCode = $LASTEXITCODE
        
        if ($pushExitCode -ne 0) {
            throw "Push failed (exit code $pushExitCode): $pushOutput"
        }
        Write-Host " ✓" -ForegroundColor Green
        Write-Host "    → oci://$Registry/$chartName:$version" -ForegroundColor Gray
        $successCount++
        
        # Clean up package after successful push
        Remove-Item $packageFile -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host " ✗ FAILED" -ForegroundColor Red
        Write-Host "    Error: $_" -ForegroundColor Red
        $failCount++
    }
}

# Cleanup
Remove-Item $distPath -Recurse -Force -ErrorAction SilentlyContinue

# Summary
Write-Host "`n" + ("=" * 80) -ForegroundColor Gray
Write-Host "SUMMARY:" -ForegroundColor Cyan
Write-Host "  ✓ Success: $successCount charts" -ForegroundColor Green
Write-Host "  ✗ Failed:  $failCount charts" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Gray" })
Write-Host ("=" * 80) -ForegroundColor Gray

if ($successCount -gt 0) {
    Write-Host "`nCharts available at: oci://$Registry/CHART_NAME" -ForegroundColor Green
    Write-Host "`nInstall a chart:" -ForegroundColor Cyan
    Write-Host "  helm install my-release oci://$Registry/CHART_NAME --version VERSION" -ForegroundColor White
    Write-Host "`nAdd to Rancher:" -ForegroundColor Cyan
    Write-Host "  Cluster → Apps → Repositories → Create" -ForegroundColor White
    Write-Host "  Type: OCI" -ForegroundColor White
    Write-Host "  URL: oci://$Registry" -ForegroundColor White
}

if ($failCount -gt 0) {
    Write-Host "`n⚠ Some charts failed to push. Review errors above." -ForegroundColor Yellow
    exit 1
}

exit 0
