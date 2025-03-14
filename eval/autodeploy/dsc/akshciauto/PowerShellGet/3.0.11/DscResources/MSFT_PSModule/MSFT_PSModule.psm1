#
# Copyright (c) Microsoft Corporation.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

$resourceModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent

# Import localization helper functions.
$helperName = 'PowerShellGet.LocalizationHelper'
$dscResourcesFolderFilePath = Join-Path -Path $resourceModuleRoot -ChildPath "Modules\$helperName\$helperName.psm1"
Import-Module -Name $dscResourcesFolderFilePath

$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_PSModule' -ScriptRoot $PSScriptRoot

# Import resource helper functions.
$helperName = 'PowerShellGet.ResourceHelper'
$dscResourcesFolderFilePath = Join-Path -Path $resourceModuleRoot -ChildPath "Modules\$helperName\$helperName.psm1"
Import-Module -Name $dscResourcesFolderFilePath -Force

<#
    .SYNOPSIS
        This DSC resource provides a mechanism to download PowerShell modules from the PowerShell
        Gallery and install it on your computer.

        Get-TargetResource returns the current state of the resource.

    .PARAMETER Name
        Specifies the name of the PowerShell module to be installed or uninstalled.

    .PARAMETER Repository
        Specifies the name of the module source repository where the module can be found.

    .PARAMETER Version
        Provides the version of the module you want to install or uninstall.

    .PARAMETER NoClobber
        Does not allow the installation of modules if other existing module on the computer have cmdlets
        of the same name.

    .PARAMETER SkipPublisherCheck
        Allows the installation of modules that have not been catalog signed.
#>
function Get-TargetResource {
    <#
        These suppressions are added because this repository have other Visual Studio Code workspace
        settings than those in DscResource.Tests DSC test framework.
        Only those suppression that contradict this repository guideline is added here.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('DscResource.AnalyzerRules\Measure-ForEachStatement', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('DscResource.AnalyzerRules\Measure-FunctionBlockBraces', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('DscResource.AnalyzerRules\Measure-IfStatement', '')]
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Repository = 'PSGallery',

        [Parameter()]
        [System.String]
        $Version,

        [Parameter()]
        [System.Boolean]
        $NoClobber,

        [Parameter()]
        [System.Boolean]
        $SkipPublisherCheck
    )

    $returnValue = @{
        Ensure             = 'Absent'
        Name               = $Name
        Repository         = $Repository
        Priority           = $null
        Description        = $null
        Guid               = $null
        ModuleBase         = $null
        ModuleType         = $null
        Author             = $null
        InstalledVersion   = $null
        Version            = $Version
        NoClobber          = $NoClobber
        SkipPublisherCheck = $SkipPublisherCheck
        InstallationPolicy = $null
        Trusted            = $false
    }

    Write-Verbose -Message ($localizedData.GetTargetResourceMessage -f $Name)
    Write-Verbose("Name:")

    Write-Verbose("Name: $Name")
    Write-Verbose("Repository: $Repository")
    Write-Verbose("Version: $Version")

    $extractedArguments = New-SplatParameterHashTable -FunctionBoundParameters $PSBoundParameters `
    -ArgumentNames ('Name', 'Repository', 'Version')

    # Get the module with the right version and repository properties.
    $modules = Get-RightModule @extractedArguments -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

    # If the module is found, the count > 0
    if ($modules.Count -gt 0) {
        Write-Verbose -Message ($localizedData.ModuleFound -f $Name)

        # Find a module with the latest version and return its properties.
        $latestModule = $modules[0]

        foreach ($module in $modules) {
            if ($module.Version -gt $latestModule.Version) {
                $latestModule = $module
            }
        }

        # Check if the repository matches.
        $repositoryName = Get-ModuleRepositoryName -Module $latestModule -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

        ##if ($repositoryName) {
          ## $installationPolicy = Get-InstallationPolicy -RepositoryName $repositoryName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        ##}

        ##if ($installationPolicy) {
        ##    $installationPolicyReturnValue = 'Trusted'
        ##    $Trusted = $true
        ##}
        ##else {
            ##$installationPolicyReturnValue = 'Untrusted'
            ##$Trusted = $false
        ##}

        Write-Verbose("returning value")
        $returnValue.Ensure = 'Present'
        $returnValue.Repository = $repositoryName
        $returnValue.Description = $latestModule.Description
        $returnValue.Guid = $latestModule.Guid
        $returnValue.ModuleBase = $latestModule.ModuleBase
        $returnValue.ModuleType = $latestModule.ModuleType
        $returnValue.Author = $latestModule.Author
        $returnValue.InstalledVersion = $latestModule.Version
        $returnValue.InstallationPolicy = $installationPolicyReturnValue
        $returnValue.Trusted = $trusted
    }
    else {
        Write-Verbose -Message ($localizedData.ModuleNotFound -f $Name)
    }

    return $returnValue
}

<#
    .SYNOPSIS
        This DSC resource provides a mechanism to download PowerShell modules from the PowerShell
        Gallery and install it on your computer.

        Test-TargetResource validates whether the resource is currently in the desired state.

    .PARAMETER Ensure
        Determines whether the module to be installed or uninstalled.

    .PARAMETER Name
        Specifies the name of the PowerShell module to be installed or uninstalled.

    .PARAMETER Repository
        Specifies the name of the module source repository where the module can be found.

    .PARAMETER InstallationPolicy
        Determines whether you trust the source repository where the module resides.

    .PARAMETER Trusted
        Determines whether you trust the source repository where the module resides.

    .PARAMETER Version
        Provides the version of the module you want to install or uninstall.

    .PARAMETER NoClobber
        Does not allow the installation of modules if other existing module on the computer have cmdlets
        of the same name.

    .PARAMETER SkipPublisherCheck
        Allows the installation of modules that have not been catalog signed.
#>
function Test-TargetResource {
    <#
        These suppressions are added because this repository have other Visual Studio Code workspace
        settings than those in DscResource.Tests DSC test framework.
        Only those suppression that contradict this repository guideline is added here.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('DscResource.AnalyzerRules\Measure-FunctionBlockBraces', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('DscResource.AnalyzerRules\Measure-IfStatement', '')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Repository = 'PSGallery',

        [Parameter()]
        [ValidateSet('Trusted', 'Untrusted')]
        [System.String]
        $InstallationPolicy = 'Untrusted',

        [Parameter()]
        [System.Boolean]
        $Trusted = $false,

        [Parameter()]
        [System.String]
        $Version,

        [Parameter()]
        [System.Boolean]
        $NoClobber,

        [Parameter()]
        [System.Boolean]
        $SkipPublisherCheck
    )

    Write-Verbose -Message ($localizedData.TestTargetResourceMessage -f $Name)

    $extractedArguments = New-SplatParameterHashTable -FunctionBoundParameters $PSBoundParameters `
    -ArgumentNames ('Name', 'Repository', 'Version')

    $status = Get-TargetResource @extractedArguments

    # The ensure returned from Get-TargetResource is not equal to the desired $Ensure.
    if ($status.Ensure -ieq $Ensure) {
        Write-Verbose -Message ($localizedData.InDesiredState -f $Name)
        return $true
    }
    else {
        Write-Verbose -Message ($localizedData.NotInDesiredState -f $Name)
        return $false
    }
}

<#
    .SYNOPSIS
        This DSC resource provides a mechanism to download PowerShell modules from the PowerShell
        Gallery and install it on your computer.

        Set-TargetResource sets the resource to the desired state. "Make it so".

    .PARAMETER Ensure
        Determines whether the module to be installed or uninstalled.

    .PARAMETER Name
        Specifies the name of the PowerShell module to be installed or uninstalled.

    .PARAMETER Repository
        Specifies the name of the module source repository where the module can be found.

    .PARAMETER InstallationPolicy
        Determines whether you trust the source repository where the module resides.

    .PARAMETER Trusted
        Determines whether you trust the source repository where the module resides.

    .PARAMETER Version
        Provides the version of the module you want to install or uninstall.

    .PARAMETER NoClobber
        Does not allow the installation of modules if other existing module on the computer have cmdlets
        of the same name.

    .PARAMETER SkipPublisherCheck
        Allows the installation of modules that have not been catalog signed.
#>
function Set-TargetResource {
    <#
        These suppressions are added because this repository have other Visual Studio Code workspace
        settings than those in DscResource.Tests DSC test framework.
        Only those suppression that contradict this repository guideline is added here.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('DscResource.AnalyzerRules\Measure-ForEachStatement', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('DscResource.AnalyzerRules\Measure-FunctionBlockBraces', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('DscResource.AnalyzerRules\Measure-IfStatement', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('DscResource.AnalyzerRules\Measure-TryStatement', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('DscResource.AnalyzerRules\Measure-CatchClause', '')]
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Repository = 'PSGallery',

        [Parameter()]
        [ValidateSet('Trusted', 'Untrusted')]
        [System.String]
        $InstallationPolicy = 'Untrusted',

        [Parameter()]
        [System.Boolean]
        $Trusted = $false,

        [Parameter()]
        [System.String]
        $Version,

        [Parameter()]
        [System.Boolean]
        $NoClobber,

        [Parameter()]
        [System.Boolean]
        $SkipPublisherCheck
    )

    # Validate the repository argument
    if ($PSBoundParameters.ContainsKey('Repository')) {
        #Test-ParameterValue -Value $Repository -Type 'PackageSource' -Verbose
    }

    if ($Ensure -ieq 'Present') {
        # Version check
        $extractedArguments = New-SplatParameterHashTable -FunctionBoundParameters $PSBoundParameters `
        -ArgumentNames ('Version')

       # $null = Test-VersionParameter @extractedArguments

       $trusted = $null
       $moduleFound = $null

        try {
            $extractedArguments = New-SplatParameterHashTable -FunctionBoundParameters $PSBoundParameters `
            -ArgumentNames ('Name', 'Repository', 'Version')

            Write-Verbose -Message ($localizedData.StartFindModule -f $Name)
            Write-verbose ("Name is: $name")
            Write-verbose ("Repository is: $repository")
            Write-verbose ("Version is: $Version")
            
            $modules = Find-PSResource @extractedArguments -ErrorVariable ev -ErrorAction SilentlyContinue

            Write-verbose ("modules is: $modules")
            $moduleFound = $modules[0]
        }
        catch {
            $errorMessage = $script:localizedData.ModuleNotFoundInRepository -f $Name
            New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
        }


        foreach ($m in $modules) {
            # Check for the installation policy.
            #$trusted = Get-InstallationPolicy -RepositoryName $m.Repository -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

            # Stop the loop if found a trusted repository.
            #if ($trusted) {
               # $moduleFound = $m
               # break;
            #}
        }

        try {
            # The repository is trusted, so we install it.
            #if ($trusted) {
            #    Write-Verbose -Message ($localizedData.StartInstallModule -f $Name, $moduleFound.Version.toString(), $moduleFound.Repository)

                # Extract the installation options.
                ## $extractedSwitches = New-SplatParameterHashTable -FunctionBoundParameters $PSBoundParameters -ArgumentNames ('Force', 'AllowClobber', 'SkipPublisherCheck')

                ## $moduleFound | Install-Module @extractedSwitches 2>&1 | out-string | Write-Verbose
            Install-PSResource -name $moduleFound.Name -Repository $moduleFound.Repository -version $moduleFound.Version -TrustRepository:$true -NoClobber:$NoClobber -Verbose #$SkipPublisherCheck,

            ##}
            # The repository is untrusted but user's installation policy is trusted, so we install it with a warning.
            ##elseif ($InstallationPolicy -ieq $true) {
            ##    Write-Warning -Message ($localizedData.InstallationPolicyWarning -f $Name, $modules[0].Repository, $InstallationPolicy)

                # Extract installation options (Force implied by InstallationPolicy).
                ## $extractedSwitches = New-SplatParameterHashTable -FunctionBoundParameters $PSBoundParameters -ArgumentNames ('AllowClobber', 'SkipPublisherCheck')

                # If all the repositories are untrusted, we choose the first one.
                ## $modules[0] | Install-Module @extractedSwitches -Force 2>&1 | out-string | Write-Verbose
           ## }
            # Both user and repository is untrusted
            ##else {
            ##    $errorMessage = $script:localizedData.InstallationPolicyFailed -f $InstallationPolicy, 'Untrusted'
            ##    New-InvalidOperationException -Message $errorMessage
            ##}

            Write-Verbose -Message ($localizedData.InstalledSuccess -f $Name)
        }
        catch {
            $errorMessage = $script:localizedData.FailToInstall -f $Name
            New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
        }
    }
    # Ensure=Absent
    else {

        $extractedArguments = New-SplatParameterHashTable -FunctionBoundParameters $PSBoundParameters `
        -ArgumentNames ('Name', 'Repository', 'Version')

        # Get the module with the right version and repository properties.
        $modules = Get-RightModule @extractedArguments

        if (-not $modules) {
            $errorMessage = $script:localizedData.ModuleWithRightPropertyNotFound -f $Name
            New-InvalidOperationException -Message $errorMessage
        }

        foreach ($module in $modules) {
            # Get the path where the module is installed.
            $path = $module.ModuleBase

            Write-Verbose -Message ($localizedData.StartUnInstallModule -f $Name)

            try {
                <#
                    There is no Uninstall-Module cmdlet for Windows PowerShell 4.0,
                    so we will remove the ModuleBase folder as an uninstall operation.
                #>
                Microsoft.PowerShell.Management\Remove-Item -Path $path -Force -Recurse

                Write-Verbose -Message ($localizedData.UnInstalledSuccess -f $module.Name)
            }
            catch {
                $errorMessage = $script:localizedData.FailToUninstall -f $module.Name
                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
            }
        } # foreach
    } # Ensure=Absent
}

<#
    .SYNOPSIS
        This is a helper function. It returns the modules that meet the specified versions and the repository requirements.

    .PARAMETER Name
        Specifies the name of the PowerShell module.

    .PARAMETER Version
        Provides the version of the module you want to install or uninstall.

    .PARAMETER Repository
        Specifies the name of the module source repository where the module can be found.
#>
function Get-RightModule {
    <#
        These suppressions are added because this repository have other Visual Studio Code workspace
        settings than those in DscResource.Tests DSC test framework.
        Only those suppression that contradict this repository guideline is added here.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('DscResource.AnalyzerRules\Measure-ForEachStatement', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('DscResource.AnalyzerRules\Measure-FunctionBlockBraces', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('DscResource.AnalyzerRules\Measure-IfStatement', '')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Version,

        [Parameter()]
        [System.String]
        $Repository
    )

    Write-Verbose -Message ($localizedData.StartGetModule -f $($Name))

    $modules = Microsoft.PowerShell.Core\Get-Module -Name $Name -ListAvailable -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

    if (-not $modules) {
        return $null
    }

    <#
        As Get-Module does not take RequiredVersion, MinimumVersion, MaximumVersion, or Repository,
        below we need to check whether the modules are containing the right version and repository
        location.
    #>

    $extractedArguments = New-SplatParameterHashTable -FunctionBoundParameters $PSBoundParameters `
    -ArgumentNames ('Version')
    $returnVal = @()

    foreach ($m in $modules) {
        $versionMatch = $false
        $installedVersion = $m.Version

        # Case 1 - a user provides none of RequiredVersion, MinimumVersion, MaximumVersion
        if ($extractedArguments.Count -eq 0) {
            $versionMatch = $true
        }

        ########### COME BACK HERE
        # Case 2 - a user provides RequiredVersion
        elseif ($extractedArguments.ContainsKey('Version')) {
            # Check if it matches with the installed version
            $versionMatch = ($installedVersion -eq [System.Version] $RequiredVersion)
        }
        <#
        else {

            # Case 3 - a user provides MinimumVersion
            if ($extractedArguments.ContainsKey('MinimumVersion')) {
                $versionMatch = ($installedVersion -ge [System.Version] $extractedArguments['MinimumVersion'])
            }

            # Case 4 - a user provides MaximumVersion
            if ($extractedArguments.ContainsKey('MaximumVersion')) {
                $isLessThanMax = ($installedVersion -le [System.Version] $extractedArguments['MaximumVersion'])

                if ($extractedArguments.ContainsKey('MinimumVersion')) {
                    $versionMatch = $versionMatch -and $isLessThanMax
                }
                else {
                    $versionMatch = $isLessThanMax
                }
            }

            # Case 5 - Both MinimumVersion and MaximumVersion are provided. It's covered by the above.
            # Do not return $false yet to allow the foreach to continue
            if (-not $versionMatch) {
                Write-Verbose -Message ($localizedData.VersionMismatch -f $Name, $installedVersion)
                $versionMatch = $false
            }
        }
        #>

        # Case 6 - Version matches but need to check if the module is from the right repository.
        if ($versionMatch) {
            # A user does not provide Repository, we are good
            if (-not $PSBoundParameters.ContainsKey('Repository')) {
                Write-Verbose -Message ($localizedData.ModuleFound -f "$Name $installedVersion")
                $returnVal += $m
            }
            else {
                # Check if the Repository matches
                $sourceName = Get-ModuleRepositoryName -Module $m

                if ($Repository -ieq $sourceName) {
                    Write-Verbose -Message ($localizedData.ModuleFound -f "$Name $installedVersion")
                    $returnVal += $m
                }
                else {
                    Write-Verbose -Message ($localizedData.RepositoryMismatch -f $($Name), $($sourceName))
                }
            }
        }
    } # foreach

    return $returnVal
}

<#
    .SYNOPSIS
        This is a helper function that returns the module's repository name.

    .PARAMETER Module
        Specifies the name of the PowerShell module.
#>
function Get-ModuleRepositoryName {
    <#
        These suppressions are added because this repository have other Visual Studio Code workspace
        settings than those in DscResource.Tests DSC test framework.
        Only those suppression that contradict this repository guideline is added here.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('DscResource.AnalyzerRules\Measure-FunctionBlockBraces', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('DscResource.AnalyzerRules\Measure-IfStatement', '')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        $Module
    )

    <#
        RepositorySourceLocation property is supported in PS V5 only. To work with the earlier
        PowerShell version, we need to do a different way. PSGetModuleInfo.xml exists for any
        PowerShell modules downloaded through PSModule provider.
    #>
    $psGetModuleInfoFileName = 'PSGetModuleInfo.xml'
    $psGetModuleInfoPath = Microsoft.PowerShell.Management\Join-Path -Path $Module.ModuleBase -ChildPath $psGetModuleInfoFileName

    Write-Verbose -Message ($localizedData.FoundModulePath -f $psGetModuleInfoPath)

    if (Microsoft.PowerShell.Management\Test-path -Path $psGetModuleInfoPath) {
        $psGetModuleInfo = Microsoft.PowerShell.Utility\Import-Clixml -Path $psGetModuleInfoPath

        return $psGetModuleInfo.Repository
    }
}

# SIG # Begin signature block
# MIIjhgYJKoZIhvcNAQcCoIIjdzCCI3MCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAFPhCGAw23QPvi
# PlKMXDhmBrsN+PdRj/TQtSsgtRmzF6CCDYEwggX/MIID56ADAgECAhMzAAAB32vw
# LpKnSrTQAAAAAAHfMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjAxMjE1MjEzMTQ1WhcNMjExMjAyMjEzMTQ1WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQC2uxlZEACjqfHkuFyoCwfL25ofI9DZWKt4wEj3JBQ48GPt1UsDv834CcoUUPMn
# s/6CtPoaQ4Thy/kbOOg/zJAnrJeiMQqRe2Lsdb/NSI2gXXX9lad1/yPUDOXo4GNw
# PjXq1JZi+HZV91bUr6ZjzePj1g+bepsqd/HC1XScj0fT3aAxLRykJSzExEBmU9eS
# yuOwUuq+CriudQtWGMdJU650v/KmzfM46Y6lo/MCnnpvz3zEL7PMdUdwqj/nYhGG
# 3UVILxX7tAdMbz7LN+6WOIpT1A41rwaoOVnv+8Ua94HwhjZmu1S73yeV7RZZNxoh
# EegJi9YYssXa7UZUUkCCA+KnAgMBAAGjggF+MIIBejAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUOPbML8IdkNGtCfMmVPtvI6VZ8+Mw
# UAYDVR0RBEkwR6RFMEMxKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1
# ZXJ0byBSaWNvMRYwFAYDVQQFEw0yMzAwMTIrNDYzMDA5MB8GA1UdIwQYMBaAFEhu
# ZOVQBdOCqhc3NyK1bajKdQKVMFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0w
# Ny0wOC5jcmwwYQYIKwYBBQUHAQEEVTBTMFEGCCsGAQUFBzAChkVodHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY0NvZFNpZ1BDQTIwMTFfMjAx
# MS0wNy0wOC5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAgEAnnqH
# tDyYUFaVAkvAK0eqq6nhoL95SZQu3RnpZ7tdQ89QR3++7A+4hrr7V4xxmkB5BObS
# 0YK+MALE02atjwWgPdpYQ68WdLGroJZHkbZdgERG+7tETFl3aKF4KpoSaGOskZXp
# TPnCaMo2PXoAMVMGpsQEQswimZq3IQ3nRQfBlJ0PoMMcN/+Pks8ZTL1BoPYsJpok
# t6cql59q6CypZYIwgyJ892HpttybHKg1ZtQLUlSXccRMlugPgEcNZJagPEgPYni4
# b11snjRAgf0dyQ0zI9aLXqTxWUU5pCIFiPT0b2wsxzRqCtyGqpkGM8P9GazO8eao
# mVItCYBcJSByBx/pS0cSYwBBHAZxJODUqxSXoSGDvmTfqUJXntnWkL4okok1FiCD
# Z4jpyXOQunb6egIXvkgQ7jb2uO26Ow0m8RwleDvhOMrnHsupiOPbozKroSa6paFt
# VSh89abUSooR8QdZciemmoFhcWkEwFg4spzvYNP4nIs193261WyTaRMZoceGun7G
# CT2Rl653uUj+F+g94c63AhzSq4khdL4HlFIP2ePv29smfUnHtGq6yYFDLnT0q/Y+
# Di3jwloF8EWkkHRtSuXlFUbTmwr/lDDgbpZiKhLS7CBTDj32I0L5i532+uHczw82
# oZDmYmYmIUSMbZOgS65h797rj5JJ6OkeEUJoAVwwggd6MIIFYqADAgECAgphDpDS
# AAAAAAADMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0
# ZSBBdXRob3JpdHkgMjAxMTAeFw0xMTA3MDgyMDU5MDlaFw0yNjA3MDgyMTA5MDla
# MH4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
# ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMT
# H01pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTEwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQCr8PpyEBwurdhuqoIQTTS68rZYIZ9CGypr6VpQqrgG
# OBoESbp/wwwe3TdrxhLYC/A4wpkGsMg51QEUMULTiQ15ZId+lGAkbK+eSZzpaF7S
# 35tTsgosw6/ZqSuuegmv15ZZymAaBelmdugyUiYSL+erCFDPs0S3XdjELgN1q2jz
# y23zOlyhFvRGuuA4ZKxuZDV4pqBjDy3TQJP4494HDdVceaVJKecNvqATd76UPe/7
# 4ytaEB9NViiienLgEjq3SV7Y7e1DkYPZe7J7hhvZPrGMXeiJT4Qa8qEvWeSQOy2u
# M1jFtz7+MtOzAz2xsq+SOH7SnYAs9U5WkSE1JcM5bmR/U7qcD60ZI4TL9LoDho33
# X/DQUr+MlIe8wCF0JV8YKLbMJyg4JZg5SjbPfLGSrhwjp6lm7GEfauEoSZ1fiOIl
# XdMhSz5SxLVXPyQD8NF6Wy/VI+NwXQ9RRnez+ADhvKwCgl/bwBWzvRvUVUvnOaEP
# 6SNJvBi4RHxF5MHDcnrgcuck379GmcXvwhxX24ON7E1JMKerjt/sW5+v/N2wZuLB
# l4F77dbtS+dJKacTKKanfWeA5opieF+yL4TXV5xcv3coKPHtbcMojyyPQDdPweGF
# RInECUzF1KVDL3SV9274eCBYLBNdYJWaPk8zhNqwiBfenk70lrC8RqBsmNLg1oiM
# CwIDAQABo4IB7TCCAekwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYEFEhuZOVQ
# BdOCqhc3NyK1bajKdQKVMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1Ud
# DwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFHItOgIxkEO5FAVO
# 4eqnxzHRI4k0MFoGA1UdHwRTMFEwT6BNoEuGSWh0dHA6Ly9jcmwubWljcm9zb2Z0
# LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dDIwMTFfMjAxMV8wM18y
# Mi5jcmwwXgYIKwYBBQUHAQEEUjBQME4GCCsGAQUFBzAChkJodHRwOi8vd3d3Lm1p
# Y3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dDIwMTFfMjAxMV8wM18y
# Mi5jcnQwgZ8GA1UdIASBlzCBlDCBkQYJKwYBBAGCNy4DMIGDMD8GCCsGAQUFBwIB
# FjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2RvY3MvcHJpbWFyeWNw
# cy5odG0wQAYIKwYBBQUHAgIwNB4yIB0ATABlAGcAYQBsAF8AcABvAGwAaQBjAHkA
# XwBzAHQAYQB0AGUAbQBlAG4AdAAuIB0wDQYJKoZIhvcNAQELBQADggIBAGfyhqWY
# 4FR5Gi7T2HRnIpsLlhHhY5KZQpZ90nkMkMFlXy4sPvjDctFtg/6+P+gKyju/R6mj
# 82nbY78iNaWXXWWEkH2LRlBV2AySfNIaSxzzPEKLUtCw/WvjPgcuKZvmPRul1LUd
# d5Q54ulkyUQ9eHoj8xN9ppB0g430yyYCRirCihC7pKkFDJvtaPpoLpWgKj8qa1hJ
# Yx8JaW5amJbkg/TAj/NGK978O9C9Ne9uJa7lryft0N3zDq+ZKJeYTQ49C/IIidYf
# wzIY4vDFLc5bnrRJOQrGCsLGra7lstnbFYhRRVg4MnEnGn+x9Cf43iw6IGmYslmJ
# aG5vp7d0w0AFBqYBKig+gj8TTWYLwLNN9eGPfxxvFX1Fp3blQCplo8NdUmKGwx1j
# NpeG39rz+PIWoZon4c2ll9DuXWNB41sHnIc+BncG0QaxdR8UvmFhtfDcxhsEvt9B
# xw4o7t5lL+yX9qFcltgA1qFGvVnzl6UJS0gQmYAf0AApxbGbpT9Fdx41xtKiop96
# eiL6SJUfq/tHI4D1nvi/a7dLl+LrdXga7Oo3mXkYS//WsyNodeav+vyL6wuA6mk7
# r/ww7QRMjt/fdW1jkT3RnVZOT7+AVyKheBEyIXrvQQqxP/uozKRdwaGIm1dxVk5I
# RcBCyZt2WwqASGv9eZ/BvW1taslScxMNelDNMYIVWzCCFVcCAQEwgZUwfjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMQITMwAAAd9r8C6Sp0q00AAAAAAB3zAN
# BglghkgBZQMEAgEFAKCBrjAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgff+8aEoo
# Lry86XOBbGD9UXxy7wMZUizEE/mNV5jy3lswQgYKKwYBBAGCNwIBDDE0MDKgFIAS
# AE0AaQBjAHIAbwBzAG8AZgB0oRqAGGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbTAN
# BgkqhkiG9w0BAQEFAASCAQAmIUy/6o+Dh9JhwcAoRtw8khaYzUgrHVRIfMc77PLi
# XisURvVDmVwTUVQxCcDhu99ivtXFAbtp/kQQXne+GmUp1JyHU3v/G1vf5IGyngmX
# VL7g0e51sZ4vwjh3K0/8GCFVYd804FKm8U34wi/zmO36+zlbDMyZmsSELn82w9VX
# x8LJkVwqG2hSGXF2WZs2Qt1yWn3uefO2tXtGDMQzdQdq5a890GlC9dCS3A/aQvZK
# oQ34IQBgJSWoWDfpXwwhIN48AZs1zBOpiSRkN1gd24xJoC385TIfo9SuGJGfppda
# +pi7Fye6NiSPdzRYFnF9Pa6Y26cFlvOf1taKvuRQ5KAPoYIS5TCCEuEGCisGAQQB
# gjcDAwExghLRMIISzQYJKoZIhvcNAQcCoIISvjCCEroCAQMxDzANBglghkgBZQME
# AgEFADCCAVEGCyqGSIb3DQEJEAEEoIIBQASCATwwggE4AgEBBgorBgEEAYRZCgMB
# MDEwDQYJYIZIAWUDBAIBBQAEINgdo0RXMrNVp2CA1IS9AVY41jqOQRMdQyqZ2PSa
# oLiqAgZg+YTRzskYEzIwMjEwODA5MjEwMjM4LjAwM1owBIACAfSggdCkgc0wgcox
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1p
# Y3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJjAkBgNVBAsTHVRoYWxlcyBUU1Mg
# RVNOOkFFMkMtRTMyQi0xQUZDMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFt
# cCBTZXJ2aWNloIIOPDCCBPEwggPZoAMCAQICEzMAAAFIoohFVrwvgL8AAAAAAUgw
# DQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
# b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
# dGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcN
# MjAxMTEyMTgyNTU2WhcNMjIwMjExMTgyNTU2WjCByjELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2Eg
# T3BlcmF0aW9uczEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046QUUyQy1FMzJCLTFB
# RkMxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggEiMA0G
# CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD3/3ivFYSK0dGtcXaZ8pNLEARbraJe
# wryi/JgbaKlq7hhFIU1EkY0HMiFRm2/Wsukt62k25zvDxW16fphg5876+l1wYnCl
# ge/rFlrR2Uu1WwtFmc1xGpy4+uxobCEMeIFDGhL5DNTbbOisLrBUYbyXr7fPzxbV
# kEwJDP5FG2n0ro1qOjegIkLIjXU6qahduQxTfsPOEp8jgqMKn++fpH6fvXKlewWz
# dsfvhiZ4H4Iq1CTOn+fkxqcDwTHYkYZYgqm+1X1x7458rp69qjFeVP3GbAvJbY3b
# Flq5uyxriPcZxDZrB6f1wALXrO2/IdfVEdwTWqJIDZBJjTycQhhxS3i1AgMBAAGj
# ggEbMIIBFzAdBgNVHQ4EFgQUhzLwaZ8OBLRJH0s9E63pIcWJokcwHwYDVR0jBBgw
# FoAU1WM6XIoxkPNDe3xGG8UzaFqFbVUwVgYDVR0fBE8wTTBLoEmgR4ZFaHR0cDov
# L2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljVGltU3RhUENB
# XzIwMTAtMDctMDEuY3JsMFoGCCsGAQUFBwEBBE4wTDBKBggrBgEFBQcwAoY+aHR0
# cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNUaW1TdGFQQ0FfMjAx
# MC0wNy0wMS5jcnQwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcDCDAN
# BgkqhkiG9w0BAQsFAAOCAQEAZhKWwbMnC9Qywcrlgs0qX9bhxiZGve+8JED27hOi
# yGa8R9nqzHg4+q6NKfYXfS62uMUJp2u+J7tINUTf/1ugL+K4RwsPVehDasSJJj+7
# boIxZP8AU/xQdVY7qgmQGmd4F+c5hkJJtl6NReYE908Q698qj1mDpr0Mx+4LhP/t
# TqL6HpZEURlhFOddnyLStVCFdfNI1yGHP9n0yN1KfhGEV3s7MBzpFJXwOflwgyE9
# cwQ8jjOTVpNRdCqL/P5ViCAo2dciHjd1u1i1Q4QZ6xb0+B1HdZFRELOiFwf0sh3Z
# 1xOeSFcHg0rLE+rseHz4QhvoEj7h9bD8VN7/HnCDwWpBJTCCBnEwggRZoAMCAQIC
# CmEJgSoAAAAAAAIwDQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRp
# ZmljYXRlIEF1dGhvcml0eSAyMDEwMB4XDTEwMDcwMTIxMzY1NVoXDTI1MDcwMTIx
# NDY1NVowfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQG
# A1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwggEiMA0GCSqGSIb3
# DQEBAQUAA4IBDwAwggEKAoIBAQCpHQ28dxGKOiDs/BOX9fp/aZRrdFQQ1aUKAIKF
# ++18aEssX8XD5WHCdrc+Zitb8BVTJwQxH0EbGpUdzgkTjnxhMFmxMEQP8WCIhFRD
# DNdNuDgIs0Ldk6zWczBXJoKjRQ3Q6vVHgc2/JGAyWGBG8lhHhjKEHnRhZ5FfgVSx
# z5NMksHEpl3RYRNuKMYa+YaAu99h/EbBJx0kZxJyGiGKr0tkiVBisV39dx898Fd1
# rL2KQk1AUdEPnAY+Z3/1ZsADlkR+79BL/W7lmsqxqPJ6Kgox8NpOBpG2iAg16Hgc
# sOmZzTznL0S6p/TcZL2kAcEgCZN4zfy8wMlEXV4WnAEFTyJNAgMBAAGjggHmMIIB
# 4jAQBgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQU1WM6XIoxkPNDe3xGG8UzaFqF
# bVUwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMA8GA1Ud
# EwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAU1fZWy4/oolxiaNE9lJBb186aGMQwVgYD
# VR0fBE8wTTBLoEmgR4ZFaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwv
# cHJvZHVjdHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3JsMFoGCCsGAQUFBwEB
# BE4wTDBKBggrBgEFBQcwAoY+aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9j
# ZXJ0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5jcnQwgaAGA1UdIAEB/wSBlTCB
# kjCBjwYJKwYBBAGCNy4DMIGBMD0GCCsGAQUFBwIBFjFodHRwOi8vd3d3Lm1pY3Jv
# c29mdC5jb20vUEtJL2RvY3MvQ1BTL2RlZmF1bHQuaHRtMEAGCCsGAQUFBwICMDQe
# MiAdAEwAZQBnAGEAbABfAFAAbwBsAGkAYwB5AF8AUwB0AGEAdABlAG0AZQBuAHQA
# LiAdMA0GCSqGSIb3DQEBCwUAA4ICAQAH5ohRDeLG4Jg/gXEDPZ2joSFvs+umzPUx
# vs8F4qn++ldtGTCzwsVmyWrf9efweL3HqJ4l4/m87WtUVwgrUYJEEvu5U4zM9GAS
# inbMQEBBm9xcF/9c+V4XNZgkVkt070IQyK+/f8Z/8jd9Wj8c8pl5SpFSAK84Dxf1
# L3mBZdmptWvkx872ynoAb0swRCQiPM/tA6WWj1kpvLb9BOFwnzJKJ/1Vry/+tuWO
# M7tiX5rbV0Dp8c6ZZpCM/2pif93FSguRJuI57BlKcWOdeyFtw5yjojz6f32WapB4
# pm3S4Zz5Hfw42JT0xqUKloakvZ4argRCg7i1gJsiOCC1JeVk7Pf0v35jWSUPei45
# V3aicaoGig+JFrphpxHLmtgOR5qAxdDNp9DvfYPw4TtxCd9ddJgiCGHasFAeb73x
# 4QDf5zEHpJM692VHeOj4qEir995yfmFrb3epgcunCaw5u+zGy9iCtHLNHfS4hQEe
# gPsbiSpUObJb2sgNVZl6h3M7COaYLeqN4DMuEin1wC9UJyH3yKxO2ii4sanblrKn
# QqLJzxlBTeCG+SqaoxFmMNO7dDJL32N79ZmKLxvHIa9Zta7cRDyXUHHXodLFVeNp
# 3lfB0d4wwP3M5k37Db9dT+mdHhk4L7zPWAUu7w2gUDXa7wknHNWzfjUeCLraNtvT
# X4/edIhJEqGCAs4wggI3AgEBMIH4oYHQpIHNMIHKMQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBP
# cGVyYXRpb25zMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjpBRTJDLUUzMkItMUFG
# QzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcG
# BSsOAwIaAxUAhyuClrocWf4SIcRafAEX1Rhs6zmggYMwgYCkfjB8MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQg
# VGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQUFAAIFAOS7vc0wIhgPMjAy
# MTA4MDkyMjQ0MjlaGA8yMDIxMDgxMDIyNDQyOVowdzA9BgorBgEEAYRZCgQBMS8w
# LTAKAgUA5Lu9zQIBADAKAgEAAgII+AIB/zAHAgEAAgIRPTAKAgUA5L0PTQIBADA2
# BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIB
# AAIDAYagMA0GCSqGSIb3DQEBBQUAA4GBABx3r2hf+l69/BwiMx5Q6xmYH8gp6lYu
# 69AHecJGredzTXeTzyPOa0DlbtiK/LibE3PzqeN+TQWYnlOnPwjbl6o9wV7PZmmV
# lAVERtTm/SGHCevB9tAY6uDx05ZT3kIiA8F0N7erykm4heh31BqyPeGubwJ05UDG
# dVVtJ9t6q6RkMYIDDTCCAwkCAQEwgZMwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
# Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29m
# dCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENB
# IDIwMTACEzMAAAFIoohFVrwvgL8AAAAAAUgwDQYJYIZIAWUDBAIBBQCgggFKMBoG
# CSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQgR2LqQfGx
# gilNz3Ry7rU8NrgJWdA9C4Nv+fnFzZAx6FwwgfoGCyqGSIb3DQEJEAIvMYHqMIHn
# MIHkMIG9BCCpkBrqjHmhvyYf5tTcTvD5Y4a+V79TwVV6T1aAwdto2DCBmDCBgKR+
# MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
# ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMT
# HU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAABSKKIRVa8L4C/AAAA
# AAFIMCIEINv2MuRcbpPNYKOZNq2JRdz20RU89zw1Kd36F6+JuPIZMA0GCSqGSIb3
# DQEBCwUABIIBABwk+5ffW6YesGL1d6DAhdpwVoar9hjT2kb6eadZY+mHfxR6CyEy
# XkyIFVSlZiizjpul1hHVmpTOGiu8NDeecphtCV4cVgQvCG1iYHgRcbz1LpAUoXxT
# WS+8tWSgVTv3X74DRGeHSv2oyUrTS7K5GtLc4eiPd5N9CnzurGr0fr5rSSlTq0Tl
# TNNDbkH78lnGH+8f6xlfKJquiGPBIMFH7jJx1SajVCK/fB2bhjeDwBiF3AfdMuTG
# xoM6cP8dWXuUlcyPW23C660TijLHxV76RSi17mR/6n971oKRF3pml6aRHp52FQu0
# nfbZeMH9vgE4BALfvqWcWV/HMZFzkrl6QFI=
# SIG # End signature block
