param ([String] $username, [String] $password, [String] $instance, [String] $db)

$startdate = "";
# Every X Mins
$startdate = Get-Date -Format "yyyy-MM-dd"

try {
	# Check if we have SqlServer Module Installed
	$SqlServerModuleExists = Get-Module -ListAvailable -Name SqlServer
	
	# Install SqlServer Module
	if (-not $SqlServerModuleExists)
	{
		Install-Module -Name SqlServer -Force -AllowClobber
	}
	
    $ErrorActionPreference = "Stop"; 
	$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	$SqlConnection.ConnectionString = "Server = $instance; Database = $db; User ID = $username; Password = $password" 
	$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	$SqlCmd.CommandText = "EXEC spBuildDepartmentCashRecReport @reportStartDate = '" + $startdate + "'"
	$SqlCmd.Connection = $SqlConnection 
    $SqlCmd.CommandTimeout = 60
    $SqlConnection.Open()
    $SqlCmd.ExecuteNonQuery() | Out-Null
	$SqlConnection.Close() 
}
catch {
   Write-Host $_ -ForegroundColor red -BackgroundColor black;
} finally {
   $ErrorActionPreference = "Continue"; 
}
