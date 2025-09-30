param(
    [Parameter(Mandatory=$true, HelpMessage="Enter your project name")]
    [string]$ProjectName,
    
    [Parameter(HelpMessage="Enter your company name")]
    [string]$CompanyName = "MyCompany",
    
    [switch]$SkipGit = $false,
    
    [switch]$Help
)

# ヘルプ表示
if ($Help) {
    Write-Host ""
    Write-Host "JUCE Project Setup Script" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\bin\setup.ps1 -ProjectName <name> [-CompanyName <name>] [-SkipGit] [-Help]"
    Write-Host ""
    Write-Host "Parameters:" -ForegroundColor Yellow
    Write-Host "  -ProjectName   : Your project name (required)"
    Write-Host "  -CompanyName   : Your company name (default: MyCompany)"
    Write-Host "  -SkipGit       : Skip Git operations"
    Write-Host "  -Help          : Show this help"
    Write-Host ""
    Write-Host "Example:" -ForegroundColor Green
    Write-Host "  .\bin\setup.ps1 -ProjectName 'SuperDelay' -CompanyName 'My Audio Labs'"
    Write-Host ""
    exit 0
}

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host " JUCE Project Setup" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Project Name: $ProjectName" -ForegroundColor White
Write-Host "Company Name: $CompanyName" -ForegroundColor White
Write-Host "Location: $ProjectRoot" -ForegroundColor Gray
Write-Host ""

# 入力確認
$confirm = Read-Host "Continue with these settings? (y/n)"
if ($confirm -ne 'y') {
    Write-Host "Setup cancelled." -ForegroundColor Yellow
    exit 0
}

try {
    # CMakeLists.txt の更新
    Write-Host "`nUpdating CMakeLists.txt..." -ForegroundColor Yellow
    
    $cmakePath = "$ProjectRoot\CMakeLists.txt"
    if (!(Test-Path $cmakePath)) {
        throw "CMakeLists.txt not found!"
    }
    
    $cmake = Get-Content $cmakePath -Raw
    
    # プラグインコードを生成（最初の4文字）
    $PluginCode = ($ProjectName -replace '[^a-zA-Z]', '').Substring(0, [Math]::Min(4, $ProjectName.Length)).ToUpper()
    if ($PluginCode.Length -lt 4) {
        $PluginCode = $PluginCode.PadRight(4, 'X')
    }
    
    $CompanyCode = ($CompanyName -replace '[^a-zA-Z]', '').Substring(0, [Math]::Min(4, $CompanyName.Length))
    if ($CompanyCode.Length -lt 4) {
        $CompanyCode = $CompanyCode.PadRight(4, 'X')
    }
    
    # CMake変数を更新
    $cmake = $cmake -replace 'set\(PROJECT_NAME ".*?"\)', "set(PROJECT_NAME `"$ProjectName`")"
    $cmake = $cmake -replace 'set\(PRODUCT_NAME ".*?"\)', "set(PRODUCT_NAME `"$ProjectName`")"
    $cmake = $cmake -replace 'set\(COMPANY_NAME ".*?"\)', "set(COMPANY_NAME `"$CompanyName`")"
    $cmake = $cmake -replace 'set\(COMPANY_CODE ".*?"\)', "set(COMPANY_CODE `"$CompanyCode`")"
    $cmake = $cmake -replace 'set\(PLUGIN_CODE ".*?"\)', "set(PLUGIN_CODE `"$PluginCode`")"
    $cmake = $cmake -replace 'set\(BUNDLE_ID ".*?"\)', "set(BUNDLE_ID `"com.$($CompanyName -replace ' ','').$ProjectName`")"
    
    $cmake | Out-File $cmakePath -Encoding UTF8 -NoNewline
    Write-Host "CMakeLists.txt updated" -ForegroundColor Green
    
    # README.md の更新
    Write-Host "`nUpdating README.md..." -ForegroundColor Yellow
    
    $readmePath = "$ProjectRoot\README.md"
    if (Test-Path $readmePath) {
        $readme = Get-Content $readmePath -Raw
        $readme = $readme -replace 'JUCE-CMake-Template', $ProjectName
        $readme = $readme -replace 'Template project.*', "$ProjectName - Audio Plugin"
        $readme | Out-File $readmePath -Encoding UTF8 -NoNewline
        Write-Host "README.md updated" -ForegroundColor Green
    }
    
    # Git操作
    if (!$SkipGit) {
        # JUCEサブモジュール追加
        Write-Host "`nAdding JUCE submodule..." -ForegroundColor Yellow
        
        Push-Location $ProjectRoot
        
        # 既存のJUCEディレクトリをチェック
        if (Test-Path "lib/JUCE/.git") {
            Write-Host "JUCE submodule already exists, updating..." -ForegroundColor Gray
            git submodule update --init --recursive
        } else {
            git submodule add https://github.com/juce-framework/JUCE.git lib/JUCE
            git submodule update --init --recursive
        }
        
        Pop-Location
        Write-Host "JUCE submodule ready" -ForegroundColor Green
        
        # 変更をコミット
        Write-Host "`nCommitting changes..." -ForegroundColor Yellow
        Push-Location $ProjectRoot
        git add -A
        git commit -m "Setup project: $ProjectName" -ErrorAction SilentlyContinue
        Pop-Location
        Write-Host "Changes committed" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "=====================================" -ForegroundColor Green
    Write-Host "Setup Complete!" -ForegroundColor Green
    Write-Host "=====================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Build the project:" -ForegroundColor White
    Write-Host "     .\bin\build.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2. Open in your IDE:" -ForegroundColor White
    Write-Host "     code ." -ForegroundColor Gray
    Write-Host "     or" -ForegroundColor Gray
    Write-Host "     Open build\$ProjectName.sln in Visual Studio" -ForegroundColor Gray
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  - Check if you're in the project root directory" -ForegroundColor Gray
    Write-Host "  - Ensure CMakeLists.txt exists" -ForegroundColor Gray
    Write-Host "  - Try running with -SkipGit if Git issues occur" -ForegroundColor Gray
    exit 1
}