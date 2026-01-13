# Push all Helm charts to OCI registry
# Modern Rancher standard: OCI-based chart distribution

param(
    [Parameter(Mandatory=$true)]
    [string]$Registry,  # e.g., "ghcr.io/yourusername" or "registry.example.com"
    
    [Parameter(Mandatory=$false)]
    [string]$Username,
    
    [Parameter(Mandatory=$false)]
    [string]$Password
)

$ErrorActionPreference = "Stop"

# Login to registry if credentials provided
if ($Username -and $Password) {
    Write-Host "Logging into $Registry..." -ForegroundColor Cyan
    $Password | helm registry login $Registry --username $Username --password-stdin
}

# Get all charts
$charts = Get-ChildItem -Path ".\charts" -Directory

Write-Host "`nPackaging and pushing $($charts.Count) charts to OCI registry: $Registry" -ForegroundColor Green
Write-Host ("=" * 80) -ForegroundColor Gray

foreach ($chart in $charts) {
    $chartPath = $chart.FullName
    $chartName = $chart.Name
    
    # Read Chart.yaml to get version
    $chartYaml = Get-Content "$chartPath\Chart.yaml" -Raw
    if ($chartYaml -match 'version:\s*(.+)') {
        $version = $matches[1].Trim()
    } else {
        Write-Warning "Skipping $chartName - no version found in Chart.yaml"
        continue
    }
    
    Write-Host "`n[$chartName] v$version" -ForegroundColor Yellow
    
    # Package the chart
    Write-Host "  - Packaging..." -NoNewline
    helm package $chartPath -d .\dist | Out-Null
    Write-Host " ✓" -ForegroundColor Green
    
    # Push to OCI registry
    Write-Host "  - Pushing to OCI..." -NoNewline
    $packageFile = ".\dist\$chartName-$version.tgz"
    helm push $packageFile "oci://$Registry"
    Write-Host " ✓" -ForegroundColor Green
    
    # Clean up package
    Remove-Item $packageFile -Force
}

# Clean up dist directory
Remove-Item .\dist -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n" + ("=" * 80) -ForegroundColor Gray
Write-Host "All charts pushed successfully to OCI registry!" -ForegroundColor Green
Write-Host "`nTo install a chart from OCI registry:" -ForegroundColor Cyan
Write-Host "  helm install my-release oci://$Registry/CHART_NAME --version VERSION" -ForegroundColor White
