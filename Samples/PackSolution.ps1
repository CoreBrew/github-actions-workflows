##Functions
function Test-NuGetPackage
{
    param ([string]$PackageName, [string]$Version = "")
    #NuGet.org API requires lowercase naming of packages when calling the API
    $PackageName = $PackageName.ToLower()

    # Set the URL for the NuGet API
    $nugetUrl = "https://api.nuget.org/v3-flatcontainer/$PackageName/index.json"

    try
    {
        # Query the NuGet API
        $response = Invoke-RestMethod -Uri $nugetUrl -ErrorAction Stop

        # If a specific version is provided, check for it
        if ($Version -ne "")
        {
            if ($response.versions -contains $Version)
            {
                Write-Host "Package '$PackageName' version '$Version' exists on NuGet.org."
                return 1
            }
            else
            {
                Write-Host "Package '$PackageName' version '$Version' does NOT exist on NuGet.org."
                return 0
            }
        }
        else
        {
            throw "Version number must be defined"
        }
    }
    catch
    {
        Write-Host "Something went wrong when testing package" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        throw
    }
}


#Ensure path starting point is where we want it to be
cd C:\Projects\CoreBrew\github-actions-workflows\
dotnet pack --configuration Release --output ./artifacts
$packages = Get-ChildItem ./artifacts -Filter *.nupkg
Write-Host $packages
Write-Host `n #newline for clean looks
foreach ($p in $packages)
{
    $name = $p.BaseName
    Write-Host "Nuget package name is: $name, now lets test if it exists on NuGet.Org"
    
}

# Example usage
Test-NuGetPackage -PackageName "CoreBrew.AppStarter" -Version "0.0.5"


$packageFileName = "NuGetPackProject1.1.0.0"

# Use regex to capture the package name and version
if ($packageFileName -match "^(.+?)(\d+\.\d+\.\d+\.\d+)$") {
    $packageName = $matches[1]
    $version = $matches[2]

    # Trim any trailing periods in the package name if they exist
    $packageName = $packageName.TrimEnd('.')

    Write-Host "Package Name: $packageName"
    Write-Host "Version: $version"
} else {
    Write-Host "Could not extract package name and version."
}






