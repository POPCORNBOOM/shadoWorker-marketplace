<#
.SYNOPSIS
Compare shadow and working directory structures.

.DESCRIPTION
Detects structural differences between shadow and working directories.
Identifies files that exist in shadow but not in working, and vice versa.

.PARAMETER MaxDisplay
Maximum files to display per directory (default: 16)

.PARAMETER Dir
Directory to compare (auto-detect shadow/working)

.PARAMETER NoCollapse
Disable collapsing, show all differences

.EXAMPLE
.\shadow-diff.ps1 -Dir ".\src"

.EXAMPLE
.\shadow-diff.ps1 -MaxDisplay 20 -NoCollapse
#>

param(
    [int]$MaxDisplay = 16,
    [string]$Dir = ".",
    [switch]$NoCollapse
)

# Hardcoded ignore list
$HardcodedIgnores = @(
    ".shadowignore",
    ".shadow",
    ".git"
)

# Detect shadow and working directory paths
function Detect-Paths {
    param([string]$InputPath)

    $shadowDir = ""
    $workingDir = ""

    if ($InputPath -like "*.shadow*") {
        # Input is a shadow directory
        $shadowDir = $InputPath
        $workingDir = $InputPath -replace "\.shadow\\", ""
    } else {
        # Input is a working directory
        $workingDir = $InputPath

        # Find project root by looking for .shadow directory
        $currentDir = $workingDir
        $projectRoot = ""

        while ($currentDir -and $currentDir -ne "") {
            if (Test-Path (Join-Path $currentDir ".shadow")) {
                $projectRoot = $currentDir
                break
            }
            $parent = Split-Path $currentDir -Parent
            if ($parent -eq $currentDir) {
                break
            }
            $currentDir = $parent
        }

        if (-not $projectRoot) {
            Write-Error "Error: Could not find .shadow directory in parent directories"
            exit 1
        }

        # Calculate relative path from project root
        $relPath = $workingDir.Substring($projectRoot.Length).TrimStart('\', '/')
        if ($relPath) {
            $shadowDir = Join-Path $projectRoot ".shadow\$relPath"
        } else {
            $shadowDir = Join-Path $projectRoot ".shadow"
        }
    }

    return @{
        Shadow = $shadowDir
        Working = $workingDir
    }
}

# Check if a path should be ignored
function Should-Ignore {
    param(
        [string]$Path,
        [string[]]$IgnorePatterns
    )

    $basename = Split-Path $Path -Leaf

    # Check hardcoded ignores
    foreach ($ignore in $HardcodedIgnores) {
        if ($basename -eq $ignore) {
            return $true
        }
    }

    # Check .shadowignore patterns
    foreach ($pattern in $IgnorePatterns) {
        # Simple pattern matching (supports * wildcards)
        if ($basename -like $pattern) {
            return $true
        }

        # Check if full path matches
        if ($Path -like "*$pattern*") {
            return $true
        }
    }

    return $false
}

# Read .shadowignore file
function Read-ShadowIgnore {
    param([string]$WorkingDir)

    $ignoreFile = Join-Path $WorkingDir ".shadowignore"
    $patterns = @()

    if (Test-Path $ignoreFile) {
        $lines = Get-Content $ignoreFile
        foreach ($line in $lines) {
            # Skip empty lines and comments
            $trimmed = $line.Trim()
            if ($trimmed -and -not $trimmed.StartsWith("#")) {
                $patterns += $trimmed
            }
        }
    }

    return $patterns
}

# Scan directory and collect files
function Scan-Directory {
    param(
        [string]$Dir,
        [string[]]$IgnorePatterns
    )

    $files = @()

    if (-not (Test-Path $Dir)) {
        return $files
    }

    $allFiles = Get-ChildItem -Path $Dir -File -Recurse -ErrorAction SilentlyContinue

    foreach ($file in $allFiles) {
        $relPath = $file.FullName.Substring($Dir.Length).TrimStart('\', '/')

        if (-not (Should-Ignore -Path $relPath -IgnorePatterns $IgnorePatterns)) {
            $files += $relPath
        }
    }

    return $files | Sort-Object
}

# Format output with collapsing
function Format-Output {
    param(
        [string]$Title,
        [string[]]$MissingFiles,
        [int]$MaxDisplay,
        [bool]$NoCollapse
    )

    if ($MissingFiles.Count -eq 0) {
        return
    }

    Write-Host ""
    Write-Host "=== $Title ==="

    # Group files by directory
    $dirFiles = @{}
    $totalDisplayed = 0
    $totalCollapsed = 0

    foreach ($file in $MissingFiles) {
        $dir = Split-Path $file -Parent
        if (-not $dir) {
            $dir = "."
        }

        if (-not $dirFiles.ContainsKey($dir)) {
            $dirFiles[$dir] = @()
        }
        $dirFiles[$dir] += $file
    }

    # Display files with collapsing
    $sortedDirs = $dirFiles.Keys | Sort-Object
    foreach ($dir in $sortedDirs) {
        $files = $dirFiles[$dir]
        $count = $files.Count

        if ($NoCollapse -or $count -le $MaxDisplay) {
            # Display all files
            foreach ($file in $files) {
                Write-Host "$file [MISSING]"
                $totalDisplayed++
            }
        } else {
            # Collapse directory
            Write-Host "$dir/ [$count files omitted, exceeds limit of $MaxDisplay]"
            $totalCollapsed += $count
        }
    }
}

# Main function
function Main {
    # Convert to absolute path
    $targetDir = Resolve-Path $Dir -ErrorAction SilentlyContinue
    if (-not $targetDir) {
        $targetDir = $Dir
    }

    # Detect paths
    $paths = Detect-Paths -InputPath $targetDir
    $shadowDir = $paths.Shadow
    $workingDir = $paths.Working

    # Read ignore patterns
    $ignorePatterns = Read-ShadowIgnore -WorkingDir $workingDir

    # Scan directories
    Write-Host "Scanning directories..."
    $shadowFiles = Scan-Directory -Dir $shadowDir -IgnorePatterns $ignorePatterns
    $workingFiles = Scan-Directory -Dir $workingDir -IgnorePatterns $ignorePatterns

    # Convert shadow files to expected working files
    $shadowMap = @{}
    $workingMap = @{}

    foreach ($file in $shadowFiles) {
        # Remove .shadow.md extension
        $workingFile = $file -replace "\.shadow\.md$", ""
        $shadowMap[$workingFile] = $true
    }

    foreach ($file in $workingFiles) {
        $workingMap[$file] = $true
    }

    # Find missing files
    $shadowMissing = @()
    $workingMissing = @()

    # Files in shadow but not in working
    foreach ($file in $shadowMap.Keys) {
        if (-not $workingMap.ContainsKey($file)) {
            $shadowMissing += $file
        }
    }

    # Files in working but not in shadow
    foreach ($file in $workingMap.Keys) {
        $shadowFile = "$file.shadow.md"
        $found = $false
        foreach ($sf in $shadowFiles) {
            if ($sf -eq $shadowFile) {
                $found = $true
                break
            }
        }
        if (-not $found) {
            $workingMissing += $file
        }
    }

    # Format and display output
    Format-Output -Title "Shadow → Working" -MissingFiles $shadowMissing -MaxDisplay $MaxDisplay -NoCollapse $NoCollapse
    Format-Output -Title "Working → Shadow" -MissingFiles $workingMissing -MaxDisplay $MaxDisplay -NoCollapse $NoCollapse

    # Summary
    $shadowCount = $shadowMissing.Count
    $workingCount = $workingMissing.Count
    $totalCollapsed = 0

    # Calculate collapsed count
    if (-not $NoCollapse) {
        $dirFiles = @{}
        foreach ($file in $workingMissing) {
            $dir = Split-Path $file -Parent
            if (-not $dir) {
                $dir = "."
            }

            if (-not $dirFiles.ContainsKey($dir)) {
                $dirFiles[$dir] = 0
            }
            $dirFiles[$dir]++
        }

        foreach ($dir in $dirFiles.Keys) {
            $count = $dirFiles[$dir]
            if ($count -gt $MaxDisplay) {
                $totalCollapsed += $count
            }
        }
    }

    Write-Host ""
    if ($totalCollapsed -gt 0) {
        Write-Host "Total: $shadowCount shadow missing, $workingCount working missing ($totalCollapsed collapsed)"
    } else {
        Write-Host "Total: $shadowCount shadow missing, $workingCount working missing"
    }
}

# Run main function
Main

