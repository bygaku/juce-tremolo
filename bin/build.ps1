param(
    [ValidateSet("Debug", "Release", "RelWithDebInfo", "MinSizeRel")]
    [string]$Config = "Debug",
    
    [switch]$Clean = $false,
    [switch]$Run = $false,
    [switch]$VST3Only = $false,
    [switch]$Verbose = $false,
    [switch]$OpenIDE = $false,
    [switch]$Help
)

# show help
if ($Help) {
    Write-Host ""
    Write-Host "JUCE Build Script" -ForegroundColor Cyan
    Write-Host "=================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\bin\build.ps1 [-Config <type>] [-Clean] [-Run] [-VST3Only] [-Verbose] [-OpenIDE]"
    Write-Host ""
    Write-Host "Parameters:" -ForegroundColor Yellow
    Write-Host "  -Config     : Build configuration (Debug/Release/RelWithDebInfo/MinSizeRel)"
    Write-Host "  -Clean      : Clean build (delete build directory first)"
    Write-Host "  -Run        : Run standalone after build"
    Write-Host "  -VST3Only   : Build VST3 plugin only (skip standalone)"
    Write-Host "  -Verbose    : Show detailed build output"
    Write-Host "  -OpenIDE    : Open in Visual Studio after configure"
    Write-Host "  -Help       : Show this help"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Green
    Write-Host "  .\bin\build.ps1                    # Debug build"
    Write-Host "  .\bin\build.ps1 -Config Release    # Release build"
    Write-Host "  .\bin\build.ps1 -Clean -Run        # Clean build and run"
    Write-Host ""
    exit 0
}

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

# get project and product names from CMakeLists.txt
function Get-ProjectInfo {
    $cmakePath = "$ProjectRoot\CMakeLists.txt"
    if (!(Test-Path $cmakePath)) {
        throw "CMakeLists.txt not found!"
    }
    
    $cmake = Get-Content $cmakePath -Raw
    
    # seeking PRODUCT_NAME
    if ($cmake -match 'set\(PROJECT_NAME\s+"([^"]+)"\)') {
        $projectName = $matches[1]
    } else {
        if ($cmake -match 'project\((\w+)') {
            $projectName = $matches[1]
        } else {
            $projectName = "UnknownProject"
        }
    }
    
    # seeking PRODUCT_NAME
    if ($cmake -match 'set\(PRODUCT_NAME\s+"([^"]+)"\)') {
        $productName = $matches[1]
    } elseif ($cmake -match 'PRODUCT_NAME\s+"([^"]+)"') {
        $productName = $matches[1]
    } else {
        $productName = $projectName
    }
    
    return @{
        ProjectName = $projectName
        ProductName = $productName
    }
}

Push-Location $ProjectRoot

try {
    $projectInfo = Get-ProjectInfo
    $ProjectName = $projectInfo.ProjectName
    $ProductName = $projectInfo.ProductName
    
    Write-Host ""
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host " Building: $ProductName" -ForegroundColor Cyan
    Write-Host " Configuration: $Config" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host ""
    
    # clean build
    if ($Clean) {
        Write-Host "Cleaning build directory..." -ForegroundColor Yellow
        if (Test-Path "$ProjectRoot\build") {
            Remove-Item -Recurse -Force "$ProjectRoot\build"
            Write-Host "Clean complete" -ForegroundColor Green
        }
        Write-Host ""
    }
    
    # CMake configure
    $BuildDir = "$ProjectRoot\build"
    
    if (!(Test-Path $BuildDir)) {
        Write-Host "Configuring CMake..." -ForegroundColor Yellow
        
        $generator = "Visual Studio 17 2022"
        
        $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
        if (Test-Path $vsWhere) {
            $vsVersion = & $vsWhere -latest -property catalog_productLineVersion
            
            $generatorMap = @{
                "2022" = "Visual Studio 17 2022"
                "2019" = "Visual Studio 16 2019"
                "2017" = "Visual Studio 15 2017"
            }
            
            if ($generatorMap.ContainsKey($vsVersion)) {
                $generator = $generatorMap[$vsVersion]
            }
        }
        
        Write-Host "   Generator: $generator" -ForegroundColor Gray
        
        $cmakeArgs = @(
            "-G", $generator,
            "-A", "x64",
            "-S", $ProjectRoot,
            "-B", $BuildDir
        )
        
        & cmake $cmakeArgs
        
        if ($LASTEXITCODE -ne 0) {
            throw "CMake configuration failed!"
        }
        
        Write-Host "CMake configuration complete" -ForegroundColor Green
        Write-Host ""
    }
    
    # open Visual Studio
    if ($OpenIDE) {
        $slnFile = Get-ChildItem "$BuildDir\*.sln" | Select-Object -First 1
        if ($slnFile) {
            Write-Host "Opening in Visual Studio..." -ForegroundColor Cyan
            Start-Process $slnFile.FullName
            Write-Host "Visual Studio opened. You can close this window." -ForegroundColor Gray
            exit 0
        }
    }
    
    # execute build
    Write-Host "Building $Config configuration..." -ForegroundColor Cyan

    # select target
    $target = if ($VST3Only) { 
        "${ProjectName}_VST3" 
    } else { 
        "ALL_BUILD" 
    }
    
    # get CPU count for parallel build
    $cpuCount = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
    
    $buildArgs = @(
        "--build", $BuildDir,
        "--config", $Config,
        "--parallel", $cpuCount,
        "--target", $target
    )
    
    if ($Verbose) {
        $buildArgs += "--verbose"
    }
    
    # show build time
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    if (!$Verbose) {
        Write-Host "Using $cpuCount parallel jobs" -ForegroundColor Gray
        Write-Host "This may take a while on first build..." -ForegroundColor Gray
        Write-Host ""
    }
    
    & cmake $buildArgs
    
    $stopwatch.Stop()
    $buildTime = [math]::Round($stopwatch.Elapsed.TotalSeconds, 1)
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Build successful! (Time: ${buildTime}s)" -ForegroundColor Green
        
        # check outputs
        Write-Host ""
        Write-Host "Output locations:" -ForegroundColor Yellow
        
        $outputs = @()
        
        # standalone
        $standalonePath = "$BuildDir\${ProjectName}_artefacts\$Config\Standalone\$ProductName.exe"
        if (Test-Path $standalonePath) {
            Write-Host "Standalone: $standalonePath" -ForegroundColor Green
            $outputs += @{Type="Standalone"; Path=$standalonePath}
        }
        
        # VST3
        $vst3Path = "$BuildDir\${ProjectName}_artefacts\$Config\VST3\${ProjectName}.vst3"
        if (Test-Path $vst3Path) {
            Write-Host "VST3: $vst3Path" -ForegroundColor Green
            $outputs += @{Type="VST3"; Path=$vst3Path}
        }
        
        # Run standalone
        if ($Run) {
            $standalone = $outputs | Where-Object { $_.Type -eq "Standalone" } | Select-Object -First 1
            if ($standalone) {
                Write-Host ""
                Write-Host "Starting $ProductName..." -ForegroundColor Cyan
                Start-Process $standalone.Path
            } else {
                Write-Host ""
                Write-Host "No standalone executable found to run" -ForegroundColor Yellow
            }
        }
        
        Write-Host ""
        Write-Host "=====================================" -ForegroundColor Green
        Write-Host " Build Complete!" -ForegroundColor Green
        Write-Host "=====================================" -ForegroundColor Green
        
    } else {
        throw "Build failed! (Exit code: $LASTEXITCODE)"
    }
    
} catch {
    Write-Host ""
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Try clean build: .\bin\build.ps1 -Clean" -ForegroundColor Gray
    Write-Host "  2. Check if JUCE submodule is initialized:" -ForegroundColor Gray
    Write-Host "     git submodule update --init --recursive" -ForegroundColor Gray
    Write-Host "  3. Ensure Visual Studio 2022 is installed with C++ support" -ForegroundColor Gray
    Write-Host "  4. Run with -Verbose for detailed output" -ForegroundColor Gray
    Write-Host ""
    exit 1
} finally {
    Pop-Location
}