# setup-security-windows.ps1
# Windows-specific security setup for GitHub Actions runners
# Configures Windows + WSL 2.0 security hardening

#Requires -RunAsAdministrator
#Requires -Version 5.1

param(
    [Parameter(HelpMessage="Skip WSL configuration")]
    [switch]$SkipWSL,

    [Parameter(HelpMessage="Skip Windows hardening")]
    [switch]$SkipHardening,

    [Parameter(HelpMessage="Dry run - show what would be done")]
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Script configuration
$ScriptVersion = "1.0.0"
$LogFile = Join-Path $PSScriptRoot "..\logs\security-setup-windows-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Colors for output
$ColorReset = "`e[0m"
$ColorRed = "`e[31m"
$ColorGreen = "`e[32m"
$ColorYellow = "`e[33m"
$ColorBlue = "`e[34m"

# Initialize logging
function Initialize-Logging {
    $logDir = Split-Path $LogFile -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    Start-Transcript -Path $LogFile -Append

    Write-Host "=========================================="
    Write-Host "Windows Security Setup v$ScriptVersion"
    Write-Host "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "User: $env:USERNAME"
    Write-Host "Computer: $env:COMPUTERNAME"
    Write-Host "=========================================="
}

# Logging functions
function Write-Info {
    param($Message)
    Write-Host "${ColorBlue}[INFO]${ColorReset} $Message"
}

function Write-Success {
    param($Message)
    Write-Host "${ColorGreen}[SUCCESS]${ColorReset} $Message"
}

function Write-Warning {
    param($Message)
    Write-Host "${ColorYellow}[WARNING]${ColorReset} $Message"
}

function Write-Error {
    param($Message)
    Write-Host "${ColorRed}[ERROR]${ColorReset} $Message" -ForegroundColor Red
}

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Configure WSL 2.0 security
function Configure-WSLSecurity {
    Write-Info "Configuring WSL 2.0 security..."

    # Check if WSL is installed
    $wslInstalled = Get-Command wsl -ErrorAction SilentlyContinue
    if (-not $wslInstalled) {
        Write-Warning "WSL not installed. Skipping WSL configuration."
        return
    }

    # Check WSL version
    $wslVersion = wsl --list --verbose 2>$null
    Write-Info "Current WSL distributions:"
    Write-Host $wslVersion

    # Create WSL configuration
    $wslConfig = @"
[automount]
enabled = true
options = "metadata,umask=077,fmask=077"
root = /mnt/
mountFsTab = true

[network]
generateResolvConf = true
generateHosts = true

[interop]
enabled = true
appendWindowsPath = false

[user]
default = runner
"@

    $wslConfigPath = "$env:USERPROFILE\.wslconfig"

    if ($DryRun) {
        Write-Info "Would create WSL config at: $wslConfigPath"
        Write-Host $wslConfig
    } else {
        $wslConfig | Out-File -FilePath $wslConfigPath -Encoding UTF8
        Write-Success "WSL configuration created at: $wslConfigPath"
    }

    # Set WSL 2 as default
    if (-not $DryRun) {
        wsl --set-default-version 2
        Write-Success "WSL 2 set as default version"
    }

    # Configure WSL memory limits for security
    $wslMemConfig = @"
[wsl2]
memory=4GB
processors=2
localhostForwarding=false
kernelCommandLine = "cgroup_enable=memory swapaccount=1"
swap=0
"@

    if ($DryRun) {
        Write-Info "Would update WSL memory configuration"
    } else {
        $wslMemConfig | Add-Content -Path $wslConfigPath
        Write-Success "WSL resource limits configured"
    }
}

# Enable Windows security features
function Enable-WindowsSecurity {
    Write-Info "Enabling Windows security features..."

    # Enable Windows Defender
    if (-not $DryRun) {
        Set-MpPreference -DisableRealtimeMonitoring $false
        Set-MpPreference -DisableBehaviorMonitoring $false
        Set-MpPreference -DisableBlockAtFirstSeen $false
        Set-MpPreference -DisableIOAVProtection $false
        Set-MpPreference -DisablePrivacyMode $false
        Set-MpPreference -DisableScriptScanning $false
        Write-Success "Windows Defender enabled with all protections"
    } else {
        Write-Info "Would enable Windows Defender protections"
    }

    # Enable Windows Firewall
    if (-not $DryRun) {
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
        Write-Success "Windows Firewall enabled for all profiles"
    } else {
        Write-Info "Would enable Windows Firewall"
    }

    # Configure audit policy
    $auditPolicies = @(
        "/set /category:'Logon/Logoff' /success:enable /failure:enable",
        "/set /category:'Account Logon' /success:enable /failure:enable",
        "/set /category:'Object Access' /success:enable /failure:enable",
        "/set /category:'Policy Change' /success:enable /failure:enable",
        "/set /category:'Privilege Use' /success:enable /failure:enable"
    )

    foreach ($policy in $auditPolicies) {
        if (-not $DryRun) {
            Start-Process -FilePath "auditpol" -ArgumentList $policy -Wait -NoNewWindow
        } else {
            Write-Info "Would set audit policy: $policy"
        }
    }

    if (-not $DryRun) {
        Write-Success "Audit policies configured"
    }
}

# Disable unnecessary network protocols
function Disable-UnnecessaryProtocols {
    Write-Info "Disabling unnecessary network protocols..."

    $protocols = @(
        "ms_netbios",
        "ms_lltdio",
        "ms_rspndr",
        "ms_lldp"
    )

    $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}

    foreach ($adapter in $adapters) {
        foreach ($protocol in $protocols) {
            try {
                if (-not $DryRun) {
                    Disable-NetAdapterBinding -Name $adapter.Name -ComponentID $protocol -ErrorAction SilentlyContinue
                    Write-Success "Disabled $protocol on $($adapter.Name)"
                } else {
                    Write-Info "Would disable $protocol on $($adapter.Name)"
                }
            } catch {
                Write-Warning "Could not disable $protocol on $($adapter.Name)"
            }
        }
    }
}

# Configure BitLocker
function Configure-BitLocker {
    Write-Info "Checking BitLocker configuration..."

    $bitlockerStatus = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue

    if ($bitlockerStatus) {
        if ($bitlockerStatus.ProtectionStatus -eq "On") {
            Write-Success "BitLocker is already enabled on C:"
        } else {
            Write-Warning "BitLocker is installed but not enabled"
            Write-Info "To enable: Enable-BitLocker -MountPoint 'C:' -EncryptionMethod Aes256"
        }
    } else {
        Write-Warning "BitLocker not available on this system"
    }
}

# Configure secure PowerShell
function Configure-PowerShellSecurity {
    Write-Info "Configuring PowerShell security..."

    # Enable PowerShell script block logging
    $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"

    if (-not $DryRun) {
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name "EnableScriptBlockLogging" -Value 1
        Write-Success "PowerShell script block logging enabled"
    } else {
        Write-Info "Would enable PowerShell script block logging"
    }

    # Enable module logging
    $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging"

    if (-not $DryRun) {
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name "EnableModuleLogging" -Value 1
        Write-Success "PowerShell module logging enabled"
    } else {
        Write-Info "Would enable PowerShell module logging"
    }

    # Set execution policy
    if (-not $DryRun) {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
        Write-Success "PowerShell execution policy set to RemoteSigned"
    } else {
        Write-Info "Would set execution policy to RemoteSigned"
    }
}

# Create security directories with proper permissions
function Initialize-SecurityDirectories {
    Write-Info "Initializing security directories..."

    $projectRoot = Split-Path $PSScriptRoot -Parent
    $directories = @(
        @{Path = "$projectRoot\.secrets"; Permissions = "ReadAndExecute"},
        @{Path = "$projectRoot\audit"; Permissions = "ReadAndExecute"},
        @{Path = "$projectRoot\logs"; Permissions = "Modify"},
        @{Path = "$projectRoot\reports"; Permissions = "Modify"},
        @{Path = "$projectRoot\.state"; Permissions = "Modify"}
    )

    foreach ($dir in $directories) {
        if (-not (Test-Path $dir.Path)) {
            if (-not $DryRun) {
                New-Item -ItemType Directory -Path $dir.Path -Force | Out-Null

                # Set NTFS permissions
                $acl = Get-Acl $dir.Path
                $permission = "$env:USERNAME", $dir.Permissions, "ContainerInherit,ObjectInherit", "None", "Allow"
                $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
                $acl.SetAccessRule($accessRule)
                Set-Acl -Path $dir.Path -AclObject $acl

                Write-Success "Created and secured: $($dir.Path)"
            } else {
                Write-Info "Would create directory: $($dir.Path)"
            }
        } else {
            Write-Info "Directory exists: $($dir.Path)"
        }
    }
}

# Configure Windows Credential Manager for secure storage
function Configure-CredentialManager {
    Write-Info "Configuring Windows Credential Manager..."

    # Example of storing credentials securely
    $credentialTarget = "GitHub_PAT"

    Write-Info "To store GitHub PAT securely:"
    Write-Host "  cmdkey /generic:$credentialTarget /user:pat /pass:<your-pat-here>"
    Write-Host ""
    Write-Info "To retrieve in scripts:"
    Write-Host '  $cred = Get-StoredCredential -Target "GitHub_PAT"'
    Write-Host '  $pat = $cred.GetNetworkCredential().Password'
}

# Configure GitHub CLI for Windows
function Configure-GitHubCLI {
    Write-Info "Checking GitHub CLI configuration..."

    $ghInstalled = Get-Command gh -ErrorAction SilentlyContinue

    if ($ghInstalled) {
        Write-Success "GitHub CLI is installed"

        # Check authentication status
        $authStatus = gh auth status 2>&1

        if ($authStatus -match "Logged in") {
            Write-Success "GitHub CLI is authenticated"
        } else {
            Write-Warning "GitHub CLI not authenticated"
            Write-Info "Run: gh auth login"
        }
    } else {
        Write-Warning "GitHub CLI not installed"
        Write-Info "Install from: https://cli.github.com/"
    }
}

# Security validation
function Test-SecurityConfiguration {
    Write-Info "Running security validation..."

    $validationResults = @()

    # Check Windows Defender
    $defenderStatus = Get-MpComputerStatus
    $validationResults += @{
        Check = "Windows Defender"
        Status = if ($defenderStatus.RealTimeProtectionEnabled) {"PASS"} else {"FAIL"}
        Details = "Real-time protection: $($defenderStatus.RealTimeProtectionEnabled)"
    }

    # Check Windows Firewall
    $firewallStatus = Get-NetFirewallProfile | Where-Object {$_.Enabled -eq $false}
    $validationResults += @{
        Check = "Windows Firewall"
        Status = if ($firewallStatus.Count -eq 0) {"PASS"} else {"FAIL"}
        Details = "All profiles enabled: $($firewallStatus.Count -eq 0)"
    }

    # Check WSL version
    $wslVersion = wsl --status 2>&1
    $validationResults += @{
        Check = "WSL Version"
        Status = if ($wslVersion -match "version 2") {"PASS"} else {"WARN"}
        Details = "WSL 2 recommended for isolation"
    }

    # Display results
    Write-Host ""
    Write-Host "Security Validation Results:"
    Write-Host "============================="

    foreach ($result in $validationResults) {
        $statusColor = switch ($result.Status) {
            "PASS" { $ColorGreen }
            "FAIL" { $ColorRed }
            "WARN" { $ColorYellow }
        }

        Write-Host "$statusColor[$($result.Status)]$ColorReset $($result.Check): $($result.Details)"
    }
}

# Generate security report
function Export-SecurityReport {
    Write-Info "Generating security report..."

    $reportPath = Join-Path $PSScriptRoot "..\reports\windows-security-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $reportDir = Split-Path $reportPath -Parent

    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }

    $report = @{
        Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        Computer = $env:COMPUTERNAME
        User = $env:USERNAME
        ScriptVersion = $ScriptVersion
        WindowsVersion = [System.Environment]::OSVersion.Version.ToString()
        SecurityFeatures = @{
            WindowsDefender = (Get-MpComputerStatus).RealTimeProtectionEnabled
            WindowsFirewall = (Get-NetFirewallProfile | Where-Object {$_.Enabled}).Count -eq 3
            BitLocker = (Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue).ProtectionStatus -eq "On"
            WSLInstalled = $null -ne (Get-Command wsl -ErrorAction SilentlyContinue)
        }
    }

    $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Success "Security report saved to: $reportPath"
}

# Main execution
function Main {
    Initialize-Logging

    if (-not (Test-Administrator)) {
        Write-Error "This script must be run as Administrator"
        Write-Host "Please run: Start-Process powershell -Verb RunAs"
        exit 1
    }

    Write-Info "DryRun mode: $DryRun"
    Write-Host ""

    if (-not $SkipWSL) {
        Configure-WSLSecurity
    }

    if (-not $SkipHardening) {
        Enable-WindowsSecurity
        Disable-UnnecessaryProtocols
        Configure-BitLocker
        Configure-PowerShellSecurity
    }

    Initialize-SecurityDirectories
    Configure-CredentialManager
    Configure-GitHubCLI

    Test-SecurityConfiguration
    Export-SecurityReport

    Write-Host ""
    Write-Success "Windows security setup complete!"
    Write-Host ""
    Write-Info "Next steps:"
    Write-Host "  1. Review the security report in reports\"
    Write-Host "  2. Run WSL and execute Linux security setup"
    Write-Host "  3. Configure GitHub PAT in Credential Manager"
    Write-Host "  4. Run validation: .\validate-security.sh"

    Stop-Transcript
}

# Execute
Main