# Test and Validate Alert Manager Helm Chart
# Fireball Industries Podstore - Patrick Ryan

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Fireball Industries Podstore - Chart Validation" -ForegroundColor Cyan
Write-Host "Testing Alert Manager Helm Chart" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Continue"
$chartPath = "charts/alert-manager"
$testNamespace = "alertmanager-test"

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check Helm
Write-Host "- Checking Helm installation..." -NoNewline
$helmVersion = helm version --short 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host " ✓ Found: $helmVersion" -ForegroundColor Green
} else {
    Write-Host " ✗ Helm not found!" -ForegroundColor Red
    Write-Host "  Please install Helm: https://helm.sh/docs/intro/install/" -ForegroundColor Yellow
    exit 1
}

# Check kubectl
Write-Host "- Checking kubectl installation..." -NoNewline
$kubectlVersion = kubectl version --client --short 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host " ✓ Found" -ForegroundColor Green
} else {
    Write-Host " ✗ kubectl not found!" -ForegroundColor Red
    Write-Host "  Please install kubectl" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Step 1: Chart Linting" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

helm lint $chartPath
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Chart linting passed!" -ForegroundColor Green
} else {
    Write-Host "✗ Chart linting failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Step 2: Template Validation" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Write-Host "Rendering templates with default values..." -ForegroundColor Yellow
$templates = helm template test-release $chartPath 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Templates rendered successfully!" -ForegroundColor Green
    $templateCount = ($templates | Select-String "^---" | Measure-Object).Count
    Write-Host "  Generated $templateCount Kubernetes resources" -ForegroundColor Cyan
} else {
    Write-Host "✗ Template rendering failed!" -ForegroundColor Red
    Write-Host $templates -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Testing with different resource presets..." -ForegroundColor Yellow

@("small", "medium", "large", "custom") | ForEach-Object {
    $preset = $_
    Write-Host "- Testing preset: $preset..." -NoNewline
    $result = helm template test-release $chartPath --set resources.preset=$preset 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host " ✓" -ForegroundColor Green
    } else {
        Write-Host " ✗" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Testing with different service types..." -ForegroundColor Yellow

@("ClusterIP", "NodePort", "LoadBalancer") | ForEach-Object {
    $serviceType = $_
    Write-Host "- Testing service type: $serviceType..." -NoNewline
    $result = helm template test-release $chartPath --set service.type=$serviceType 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host " ✓" -ForegroundColor Green
    } else {
        Write-Host " ✗" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Step 3: Dry-Run Installation" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Write-Host "Performing dry-run installation..." -ForegroundColor Yellow
$dryRun = helm install test-release $chartPath --dry-run --debug 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Dry-run installation successful!" -ForegroundColor Green
} else {
    Write-Host "✗ Dry-run installation failed!" -ForegroundColor Red
    Write-Host $dryRun -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Step 4: Package Chart" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Write-Host "Packaging chart..." -ForegroundColor Yellow
$package = helm package $chartPath 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Chart packaged successfully!" -ForegroundColor Green
    Write-Host $package -ForegroundColor Cyan
} else {
    Write-Host "✗ Chart packaging failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Step 5: Optional - Test Installation" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "Would you like to test installation to a cluster?" -ForegroundColor Yellow
Write-Host "This will create namespace '$testNamespace' and deploy the chart." -ForegroundColor Yellow
Write-Host ""
$response = Read-Host "Continue with test installation? (y/N)"

if ($response -eq 'y' -or $response -eq 'Y') {
    Write-Host ""
    Write-Host "Testing cluster connectivity..." -ForegroundColor Yellow
    
    $clusterInfo = kubectl cluster-info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Cannot connect to cluster!" -ForegroundColor Red
        Write-Host "  Make sure kubectl is configured correctly" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "✓ Connected to cluster" -ForegroundColor Green
    Write-Host ""
    
    # Create test namespace
    Write-Host "Creating test namespace..." -ForegroundColor Yellow
    kubectl create namespace $testNamespace 2>$null
    
    # Install chart
    Write-Host "Installing chart..." -ForegroundColor Yellow
    helm install test-release $chartPath `
        --namespace $testNamespace `
        --set persistence.enabled=false `
        --set resources.preset=small
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Chart installed successfully!" -ForegroundColor Green
        Write-Host ""
        
        # Wait for pods
        Write-Host "Waiting for pods to be ready..." -ForegroundColor Yellow
        kubectl wait --for=condition=ready pod `
            -l app.kubernetes.io/name=alert-manager `
            -n $testNamespace `
            --timeout=120s
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Pods are ready!" -ForegroundColor Green
            Write-Host ""
            
            # Show status
            Write-Host "Deployment status:" -ForegroundColor Cyan
            kubectl get all -n $testNamespace
            
            Write-Host ""
            Write-Host "================================================" -ForegroundColor Cyan
            Write-Host "Test Installation Complete!" -ForegroundColor Green
            Write-Host "================================================" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "To access Alert Manager:" -ForegroundColor Yellow
            Write-Host "  kubectl port-forward -n $testNamespace svc/test-release-alert-manager 9093:9093" -ForegroundColor Cyan
            Write-Host "  Then open: http://localhost:9093" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "To clean up:" -ForegroundColor Yellow
            Write-Host "  helm uninstall test-release -n $testNamespace" -ForegroundColor Cyan
            Write-Host "  kubectl delete namespace $testNamespace" -ForegroundColor Cyan
        } else {
            Write-Host "✗ Pods failed to become ready" -ForegroundColor Red
            Write-Host ""
            Write-Host "Checking pod status:" -ForegroundColor Yellow
            kubectl get pods -n $testNamespace
            Write-Host ""
            Write-Host "Pod logs:" -ForegroundColor Yellow
            kubectl logs -n $testNamespace -l app.kubernetes.io/name=alert-manager --tail=50
        }
    } else {
        Write-Host "✗ Chart installation failed!" -ForegroundColor Red
    }
} else {
    Write-Host "Skipping cluster installation test." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Validation Summary" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "✓ Chart linting: PASSED" -ForegroundColor Green
Write-Host "✓ Template rendering: PASSED" -ForegroundColor Green
Write-Host "✓ Dry-run installation: PASSED" -ForegroundColor Green
Write-Host "✓ Chart packaging: PASSED" -ForegroundColor Green
Write-Host ""
Write-Host "Your Alert Manager chart is ready for deployment!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Review the generated package: alert-manager-1.0.0.tgz" -ForegroundColor Cyan
Write-Host "2. Push to GitHub repository" -ForegroundColor Cyan
Write-Host "3. Add to Rancher catalog" -ForegroundColor Cyan
Write-Host "4. Deploy to production clusters" -ForegroundColor Cyan
Write-Host ""
Write-Host "Fireball Industries Podstore - Patrick Ryan" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
