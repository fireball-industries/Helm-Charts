<#
.SYNOPSIS
    Manage TimescaleDB deployments in Kubernetes
    
.DESCRIPTION
    Comprehensive management script for TimescaleDB Helm releases.
    Because clicking around in Lens/K9s is fun, but automation is better.
    
    Actions:
    - deploy: Deploy or upgrade a TimescaleDB release
    - upgrade: Upgrade an existing release
    - delete: Delete a release (with confirmation)
    - backup: Trigger a manual backup
    - restore: Restore from backup
    - health-check: Check database health and status
    - compression-status: Show compression statistics
    - retention-status: Show retention policy status
    - hypertable-info: Display hypertable information
    - continuous-aggregate-refresh: Refresh continuous aggregates
    - vacuum: Run VACUUM ANALYZE
    - analyze: Run ANALYZE
    - logs: Tail pod logs
    
.PARAMETER Action
    The action to perform (see description)
    
.PARAMETER ReleaseName
    Helm release name (default: timescaledb)
    
.PARAMETER Namespace
    Kubernetes namespace (default: databases)
    
.PARAMETER ValuesFile
    Path to custom values.yaml (for deploy/upgrade)
    
.PARAMETER BackupFile
    Path to backup file (for restore)
    
.PARAMETER Follow
    Follow logs in real-time (for logs action)
    
.EXAMPLE
    .\manage-timescaledb.ps1 -Action deploy -Namespace production
    
.EXAMPLE
    .\manage-timescaledb.ps1 -Action health-check -ReleaseName tsdb-prod
    
.EXAMPLE
    .\manage-timescaledb.ps1 -Action compression-status -Namespace production
    
.NOTES
    Author: Patrick Ryan / Fireball Industries
    Version: 1.0.0
    Requires: kubectl, helm, psql (PostgreSQL client)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('deploy', 'upgrade', 'delete', 'backup', 'restore', 'health-check', 
                 'compression-status', 'retention-status', 'hypertable-info', 
                 'continuous-aggregate-refresh', 'vacuum', 'analyze', 'logs')]
    [string]$Action,
    
    [Parameter(Mandatory = $false)]
    [string]$ReleaseName = "timescaledb",
    
    [Parameter(Mandatory = $false)]
    [string]$Namespace = "databases",
    
    [Parameter(Mandatory = $false)]
    [string]$ValuesFile = "",
    
    [Parameter(Mandatory = $false)]
    [string]$BackupFile = "",
    
    [Parameter(Mandatory = $false)]
    [switch]$Follow
)

# Color output functions (because monochrome is for the '90s)
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Success { param([string]$Message) Write-ColorOutput "✅ $Message" "Green" }
function Write-Error { param([string]$Message) Write-ColorOutput "❌ $Message" "Red" }
function Write-Warning { param([string]$Message) Write-ColorOutput "⚠️  $Message" "Yellow" }
function Write-Info { param([string]$Message) Write-ColorOutput "ℹ️  $Message" "Cyan" }
function Write-Header { param([string]$Message) Write-ColorOutput "`n🔥 $Message" "Magenta" }

# Check prerequisites
function Test-Prerequisites {
    Write-Header "Checking Prerequisites"
    
    $missing = @()
    
    # Check kubectl
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        $missing += "kubectl"
    } else {
        $kubectlVersion = kubectl version --client -o json | ConvertFrom-Json
        Write-Success "kubectl: $($kubectlVersion.clientVersion.gitVersion)"
    }
    
    # Check helm
    if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
        $missing += "helm"
    } else {
        $helmVersion = helm version --short
        Write-Success "helm: $helmVersion"
    }
    
    # Check psql (optional but recommended)
    if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
        Write-Warning "psql not found (optional, but recommended for database operations)"
    } else {
        $psqlVersion = psql --version
        Write-Success "psql: $psqlVersion"
    }
    
    if ($missing.Count -gt 0) {
        Write-Error "Missing required tools: $($missing -join ', ')"
        Write-Info "Install missing tools and try again"
        exit 1
    }
    
    # Check kubectl context
    $currentContext = kubectl config current-context
    Write-Info "Current kubectl context: $currentContext"
}

# Get database password from secret
function Get-DatabasePassword {
    $password = kubectl get secret "$ReleaseName-secret" -n $Namespace -o jsonpath="{.data.password}" 2>$null
    if ($password) {
        return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($password))
    }
    return $null
}

# Get pod name
function Get-PodName {
    param([int]$Index = 0)
    
    $pods = kubectl get pods -n $Namespace -l "app.kubernetes.io/name=timescaledb,app.kubernetes.io/instance=$ReleaseName" -o jsonpath="{.items[$Index].metadata.name}" 2>$null
    return $pods
}

# Execute SQL command
function Invoke-SQL {
    param(
        [string]$Query,
        [switch]$Quiet
    )
    
    $podName = Get-PodName
    if (-not $podName) {
        Write-Error "No pods found for release $ReleaseName in namespace $Namespace"
        return $null
    }
    
    if ($Quiet) {
        $result = kubectl exec -n $Namespace $podName -- psql -U tsadmin -d tsdb -c $Query -t 2>&1
    } else {
        $result = kubectl exec -n $Namespace $podName -- psql -U tsadmin -d tsdb -c $Query 2>&1
    }
    
    return $result
}

# Actions
function Deploy-Release {
    Write-Header "Deploying TimescaleDB Release: $ReleaseName"
    
    $chartPath = Split-Path -Parent $PSScriptRoot
    
    $helmArgs = @(
        "upgrade",
        "--install",
        $ReleaseName,
        $chartPath,
        "--namespace", $Namespace,
        "--create-namespace"
    )
    
    if ($ValuesFile) {
        if (Test-Path $ValuesFile) {
            $helmArgs += "--values", $ValuesFile
            Write-Info "Using custom values file: $ValuesFile"
        } else {
            Write-Error "Values file not found: $ValuesFile"
            exit 1
        }
    }
    
    Write-Info "Running: helm $($helmArgs -join ' ')"
    
    & helm $helmArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Deployment successful!"
        Write-Info "Run health-check to verify the deployment"
    } else {
        Write-Error "Deployment failed with exit code $LASTEXITCODE"
        exit 1
    }
}

function Delete-Release {
    Write-Header "Deleting TimescaleDB Release: $ReleaseName"
    Write-Warning "This will DELETE the release and all associated resources"
    Write-Warning "PersistentVolumeClaims may be retained depending on your configuration"
    
    $confirmation = Read-Host "Type 'DELETE' to confirm"
    
    if ($confirmation -ne "DELETE") {
        Write-Info "Deletion cancelled"
        return
    }
    
    helm uninstall $ReleaseName --namespace $Namespace
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Release deleted"
        Write-Info "Note: PVCs may still exist. Delete manually if needed:"
        Write-Info "  kubectl delete pvc -n $Namespace -l app.kubernetes.io/instance=$ReleaseName"
    } else {
        Write-Error "Failed to delete release"
    }
}

function Start-Backup {
    Write-Header "Triggering Manual Backup"
    
    Write-Info "Creating job from CronJob..."
    $jobName = "$ReleaseName-backup-manual-$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    kubectl create job $jobName --from=cronjob/$ReleaseName-backup -n $Namespace
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Backup job created: $jobName"
        Write-Info "Monitor progress with: kubectl logs -n $Namespace job/$jobName -f"
    } else {
        Write-Error "Failed to create backup job"
    }
}

function Get-HealthCheck {
    Write-Header "TimescaleDB Health Check"
    
    # Check pods
    Write-Info "Pod Status:"
    kubectl get pods -n $Namespace -l "app.kubernetes.io/instance=$ReleaseName"
    
    # Check services
    Write-Info "`nService Status:"
    kubectl get svc -n $Namespace -l "app.kubernetes.io/instance=$ReleaseName"
    
    # Check PVCs
    Write-Info "`nPersistent Volume Claims:"
    kubectl get pvc -n $Namespace -l "app.kubernetes.io/instance=$ReleaseName"
    
    # Database connection test
    Write-Info "`nDatabase Connection:"
    $connTest = Invoke-SQL "SELECT version();" -Quiet
    if ($connTest) {
        Write-Success "Database connection successful"
        Write-Info $connTest
    } else {
        Write-Error "Database connection failed"
    }
    
    # TimescaleDB version
    Write-Info "`nTimescaleDB Version:"
    $tsVersion = Invoke-SQL "SELECT extversion FROM pg_extension WHERE extname='timescaledb';" -Quiet
    if ($tsVersion) {
        Write-Success "TimescaleDB: $tsVersion"
    }
    
    # Database size
    Write-Info "`nDatabase Size:"
    Invoke-SQL "SELECT pg_size_pretty(pg_database_size(current_database()));"
}

function Get-CompressionStatus {
    Write-Header "Compression Status"
    
    $query = @"
SELECT
  hypertable_schema || '.' || hypertable_name AS hypertable,
  pg_size_pretty(before_compression_total_bytes) AS before_compression,
  pg_size_pretty(after_compression_total_bytes) AS after_compression,
  pg_size_pretty(before_compression_total_bytes - after_compression_total_bytes) AS saved,
  CASE
    WHEN before_compression_total_bytes > 0 THEN
      ROUND(100 * (1 - after_compression_total_bytes::NUMERIC / before_compression_total_bytes), 2)
    ELSE 0
  END AS compression_ratio
FROM timescaledb_information.hypertables h
LEFT JOIN LATERAL hypertable_compression_stats(format('%I.%I', hypertable_schema, hypertable_name)) ON true
WHERE before_compression_total_bytes > 0
ORDER BY before_compression_total_bytes DESC;
"@
    
    Invoke-SQL $query
}

function Get-RetentionStatus {
    Write-Header "Retention Policy Status"
    
    $query = @"
SELECT
  hypertable_schema || '.' || hypertable_name AS hypertable,
  config->>'drop_after' AS retention_period,
  next_start AS next_run
FROM timescaledb_information.jobs
WHERE proc_name = 'policy_retention'
ORDER BY hypertable_schema, hypertable_name;
"@
    
    Invoke-SQL $query
}

function Get-HypertableInfo {
    Write-Header "Hypertable Information"
    
    $query = @"
SELECT
  hypertable_schema || '.' || hypertable_name AS hypertable,
  pg_size_pretty(total_bytes) AS total_size,
  chunk_count,
  compression_enabled,
  replication_factor
FROM (
  SELECT
    h.*,
    COUNT(c.*) AS chunk_count,
    total_bytes
  FROM timescaledb_information.hypertables h
  LEFT JOIN timescaledb_information.chunks c ON h.hypertable_name = c.hypertable_name AND h.hypertable_schema = c.hypertable_schema
  LEFT JOIN LATERAL hypertable_size(format('%I.%I', h.hypertable_schema, h.hypertable_name)) total_bytes ON true
  GROUP BY h.hypertable_schema, h.hypertable_name, h.owner, h.compression_enabled, h.replication_factor, total_bytes
) sub
ORDER BY total_bytes DESC;
"@
    
    Invoke-SQL $query
}

function Invoke-ContinuousAggregateRefresh {
    Write-Header "Refreshing Continuous Aggregates"
    
    $query = @"
DO \$\$
DECLARE
  agg RECORD;
BEGIN
  FOR agg IN
    SELECT view_schema, view_name
    FROM timescaledb_information.continuous_aggregates
  LOOP
    RAISE NOTICE 'Refreshing %.%', agg.view_schema, agg.view_name;
    EXECUTE format('CALL refresh_continuous_aggregate(%L, NULL, NULL);', agg.view_schema || '.' || agg.view_name);
  END LOOP;
END
\$\$;
"@
    
    Invoke-SQL $query
    Write-Success "Continuous aggregates refreshed"
}

function Invoke-Vacuum {
    Write-Header "Running VACUUM ANALYZE"
    Write-Info "This may take a while on large databases..."
    
    Invoke-SQL "VACUUM (VERBOSE, ANALYZE);"
    Write-Success "VACUUM completed"
}

function Invoke-Analyze {
    Write-Header "Running ANALYZE"
    
    Invoke-SQL "ANALYZE VERBOSE;"
    Write-Success "ANALYZE completed"
}

function Get-Logs {
    Write-Header "Pod Logs"
    
    $podName = Get-PodName
    if (-not $podName) {
        Write-Error "No pods found"
        return
    }
    
    Write-Info "Fetching logs from: $podName"
    
    if ($Follow) {
        kubectl logs -n $Namespace $podName -f
    } else {
        kubectl logs -n $Namespace $podName --tail=100
    }
}

# Main execution
try {
    Test-Prerequisites
    
    switch ($Action) {
        'deploy'                         { Deploy-Release }
        'upgrade'                        { Deploy-Release }
        'delete'                         { Delete-Release }
        'backup'                         { Start-Backup }
        'health-check'                   { Get-HealthCheck }
        'compression-status'             { Get-CompressionStatus }
        'retention-status'               { Get-RetentionStatus }
        'hypertable-info'                { Get-HypertableInfo }
        'continuous-aggregate-refresh'   { Invoke-ContinuousAggregateRefresh }
        'vacuum'                         { Invoke-Vacuum }
        'analyze'                        { Invoke-Analyze }
        'logs'                           { Get-Logs }
        default {
            Write-Error "Unknown action: $Action"
            exit 1
        }
    }
    
    Write-Success "`nOperation completed successfully!"
    
} catch {
    Write-Error "An error occurred: $_"
    exit 1
}
