##Classes
class NuGetPackageInfo
{
    [string]$Id
    [string]$Version
    [Boolean]$ReleaseStageMatch

    # Constructor to initialize the properties
    NuGetPackageInfo([string]$id, [string]$version, [Boolean]$ReleaseStageMatch)
    {
        $this.Id = $id
        $this.Version = $version
        $this.ReleaseStageMatch = $ReleaseStageMatch
    }
}

##Functions
function Get-NuGetPackageVersion
{
    param ([string]$nupkgFilePath, [string]$releaseStage)
    # Extract .nuspec file from .nupkg

    $tempDir = "./artifacts/temp"
    Expand-Archive -Path $nupkgFilePath -DestinationPath $tempDir -Force

    # Find the .nuspec file in the extracted content
    $nuspecFile = Get-ChildItem -Path $tempDir -Filter "*.nuspec" | Select-Object -First 1

    # Parse .nuspec file to get the version
    [xml]$nuspecXml = Get-Content -Path $nuspecFile.FullName
    $version = $nuspecXml.package.metadata.version
    $id = $nuspecXml.package.metadata.id

    if ($releaseStage.Length -eq $null -or $releaseStage -eq "")
    {
        $matchReleaseStage = $true        
    }
    else
    {
        $matchReleaseStage = $version.ToLower().Contains($releaseStage.ToLower())        
    }
    
    # Clean up the temporary files
    Remove-Item $tempDir -Recurse -Force

    # Return an instance of the class
    return [NuGetPackageInfo]::new($id, $version, $matchReleaseStage)
}

function Test-NuGetPackage
{
    param ([string]$PackageName, [string]$Version)
    #NuGet.org API requires lowercase naming of packages when calling the API
    $PackageName = $PackageName.ToLower()

    # Set the URL for the NuGet API
    $nugetUrl = "https://api.nuget.org/v3-flatcontainer/$PackageName/index.json"

    try
    {
        # Query the NuGet API
        $response = Invoke-RestMethod -Uri $nugetUrl -ErrorAction Stop

        if ($response.versions -contains $Version)
        {
            Write-Host "Package '$PackageName' version '$Version' exists on NuGet.org."
            return $true
        }
        else
        {
            Write-Host "Package '$PackageName' version '$Version' does NOT exist on NuGet.org."
            return $false
        }
    }
    catch
    {
        if ($_.Exception.Response.StatusCode -eq 404)
        {
            # Handle 404 error
            Write-Host "Package: " -NoNewline
            Write-Host $PackageName -ForegroundColor Yellow -NoNewline
            Write-Host " not found on NuGet.org."
            return $false
        }
        else
        {
            Write-Host "Something went wrong when testing package" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Yellow
            throw
        }
    }
}

############# Actual script #######################################
#debug the powershell used version
Write-Host "################## Writing out the powershell version #######################"
Write-Host $PSVersionTable

#Ensure path starting point is where we want it to be
cd C:\Projects\CoreBrew\github-actions-workflows\

#set artifacts folder
$artifactFolder = "./artifacts"

## pack all packable projects in solution
dotnet pack --configuration Release --output $artifactFolder

Write-Host ""
Write-Host "Print out all nupkg files in $artifactFolder"
ls $artifactFolder -Filter *.nupkg

Write-Host ""
Write-Host "########## Now loop packages #########"
$packages = Get-ChildItem $artifactFolder -Filter *.nupkg
foreach ($p in $packages)
{
    [NuGetPackageInfo]$result = Get-NuGetPackageVersion -nupkgFilePath $p.FullName -releaseStage 'alpha'
    Write-Host "NuGet package id is: " -NoNewline
    Write-Host $result.Id -ForegroundColor Yellow
    Write-Host "NuGet package version is: " -NoNewline
    Write-Host $result.Version -ForegroundColor Yellow
    Write-Host "NuGet pacakge matches release stage: " -NoNewline
    Write-Host $result.ReleaseStageMatch -ForegroundColor Yellow
    
    $exists = Test-NuGetPackage -PackageName $result.Id -Version $result.Version
    if ($exists -eq $false -and $result.ReleaseStageMatch -eq $true)
    {
        dotnet nuget push $p.FullName -k "ReplaceWithCorrectKey" -s https://api.nuget.org/v3/index.json
    }
    else
    {
        Write-Host "Package does not require upload, delete file"
        Remove-Item $p.FullName
    }
    Write-Host ""
}
