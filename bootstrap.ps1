#
# Sync dotfiles from this repo into home dir (~).
#

function Get-Dirname ($path) { Split-Path -parent $path }

$rootFolder = Get-Dirname "$PSCommandPath"
$buildFolder = Join-Path $rootFolder "build"

# files to build with platform dependent sections
$filesToBuild = @(".hgrc", ".hgignore", ".gitconfig", ".gitignore")
$otherFiles = ".editorconfig .gitattributes .npmrc"

cd "$rootFolder"

git pull origin master

function build($files) {
  Foreach ($file in $files)
  {
    # Concatenate base and windows-platform specific files
    cat "$file (Base)", "$file (Windows)" | Out-File -Encoding UTF8 $(Join-Path $buildFolder $file)
  }
}

function doIt() {

  build $filesToBuild

  # sync the files
  $files = $filesToBuild -join " "
  sync $buildFolder $files "robocopyLog1.txt"

  # sync other files
  sync $rootFolder $otherFiles "robocopyLog2.txt"
}

function sync($sourceFolder, $files, $logfile) {
  $destinationFolder = $home
  # We do not use /PURGE (or /MIR) because then robocopy
  # takes too long to proceed, and we don't want to delete
  # anything in ~ that doesn't exist in this dotfiles repo.
  $program="robocopy"
  # /COPYALL: Copy all file info (timestamp, owner, ACL's etc)
  # /LEV:1: Do not any copy subfolders (only first level)
  # Note: We could use /PURGE instead of /MIR
  $options="/COPYALL /LEV:1"
  $loggingOptions="/V /TEE /NC /NS /NDL /LOG:$logfile"
  $retryOptions="/R:0 /W:0"
  $excludedFiles="README.md", "bootstrap.sh", "bootstrap.ps1", "LICENSE-MIT.txt"
  $excludedFilesOptions = "/XF $($excludedFiles -join ' /XF ')"
  $excludedDirectories = ".git", ".vim", "bin", "init", "scripts"
  $excludedDirectoriesOptions = "/XD $($excludedDirectories -join ' /XD ')"

  # Note: You can insert /L option to debug any pronlems
  # /L: List only, doesn't copy anything (-WhatIf in powershell)

  # Perform sync with robocopy tool
  Invoke-Expression "$program $sourceFolder $destinationFolder $files $options $loggingOptions $retryOptions"

  # Move logfile to ~
  Invoke-Expression "mv -Force $(Join-Path $rootFolder $logfile) $destinationFolder"
}

if ( $args[0] -eq "--build" -or $args[0] -eq "-b" ) {
  build
}
elseif ( $args[0] -eq "--force" -or $args[0] -eq "-f" ) {
  doIt
}
else {
  $reply = Read-Host -Prompt "This may overwrite existing files in your home directory. Are you sure? (y/n) "
  if ( $reply -match "^[Yy]$" ) {
    doIt
  }
}
