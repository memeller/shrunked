$listFile = "..\xpi.list"
#could not get compress-7zip to pack only files from dist folder, so had to use this workaround
$targetDir = "..\dist"
$sourceDir = Split-Path -Parent $PSScriptRoot
Write-Warning $sourceDir
#when script is launched from vscode the scripts folder is not the current working directory, so we need to change it to scripts folder
Set-Location (Join-Path $sourceDir -ChildPath "scripts")
Write-Warning "[START] Compressing files to dist folder"
If ((Test-Path "..\dist") -eq "True") {
Remove-Item -Recurse -Force ..\dist
}
mkdir -p ..\dist | Out-Null
Write-Host "[Copy] Copying files specified in $listFile to dist folder"
Get-Content $listFile | Where-Object { $_ -match '\S' } | ForEach-Object {
    # Clean up the string and normalize slashes for Windows paths
    $relativePath = $_.Trim().Replace('/', '\')
    $sourcePath = Join-Path $sourceDir $relativePath
    # wildcards - _locales\*
    if ($relativePath -match '\*$') {
        $parentRelative = Split-Path $relativePath -Parent
        $destPath = Join-Path $targetDir $parentRelative        
        if (-not (Test-Path $destPath)) {
            New-Item -ItemType Directory -Path $destPath -Force | Out-Null
        }
        Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force
        Write-Host "[Copy] Copied wildcard: $relativePath"
    }
    # 2. directories
    elseif (Test-Path $sourcePath -PathType Container) {
        $destPath = Join-Path $targetDir $relativePath
        if (-not (Test-Path $destPath)) {
            New-Item -ItemType Directory -Path $destPath -Force | Out-Null
            Write-Host "[Copy] Created directory: $relativePath"
        }
    }
    # single files
    elseif (Test-Path $sourcePath -PathType Leaf) {
        $parentRelative = Split-Path $relativePath -Parent
        $destDir = Join-Path $targetDir $parentRelative
        $destFile = Join-Path $targetDir $relativePath
        
        # Ensure the file's parent directory exists inside \dist
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        
        # Copy the file
        Copy-Item -Path $sourcePath -Destination $destFile -Force
        Write-Host "[Copy] Copied file: $relativePath"
    }
    else {
        Write-Warning "[ERROR] Source not found, skipping: $relativePath"
    }
}
if(Get-Location | Select-String -Pattern "scripts") {
        Set-Location (Join-Path -Path (Split-Path $PWD -Parent) -ChildPath "dist")
}
else {
    Set-Location (Join-Path -Path $PWD -ChildPath "dist")<# Action when all if and elseif conditions are false #>
}
#get version from manifest.json
$manifest = Get-Content -Raw "..\manifest.json" | ConvertFrom-Json
$version = $manifest.version.replace('\.','_')
#cleanup old xpi folder and create new one
If ((Test-Path "..\xpi") -eq "True") {
    Remove-Item -Recurse -Force ..\xpi
}
mkdir -p ..\xpi | Out-Null
if (Get-Command "Compress-7Zip" -ErrorAction SilentlyContinue) {
    Write-Output "[7Zip] Compressing files to ..\xpi\shrunked_image_resizer-$version.xpi"
    Compress-7Zip -FullName "." -OutputFile "..\xpi\shrunked_image_resizer-$version.xpi" -ArchiveType Zip | Out-Null
    Write-Output "[7Zip] Compressing done"
}
else {
    Write-Output "[ERROR] 7Zip4Powershell module is not installed or not found in PATH."
}
Set-Location $sourceDir
Write-Output "[MAIN] Cleaning up..."
If ((Test-Path ".\dist") -eq "True") {
    Remove-Item -Recurse -Force .\dist
}
else
{
    Write-Output "[MAIN] No dist folder found to clean up."
}
Write-Output "[STOP] Script finished"