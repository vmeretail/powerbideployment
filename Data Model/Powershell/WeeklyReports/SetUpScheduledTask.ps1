function DisplayInstructions
{
	Write-Host
	Write-Host "**************************************" -ForegroundColor yellow
	Write-Host
	Write-Host "SETUP SCHEDULED TASKS FOR Weekly Reporting" -ForegroundColor yellow
	Write-Host "--------------------------------------" -ForegroundColor yellow
	Write-Host
	Write-Host "This program will allow you to Create or Update a Scheduled Task to be ran nightly against a database." -ForegroundColor yellow
    Write-Host
	Write-Host "**************************************" -ForegroundColor yellow
	Write-Host
}

function GetTaskExists($TaskName)
{
    $TaskExists = Get-ScheduledTask | Where-Object {$_.TaskPath -eq $TaskPath -and $_.TaskName -eq $TaskName }
	if($TaskExists)
	{
		do{
			$Continue = $(Write-Host "" -NoNewLine) + $(Write-Host "Task Already Created For Organisation. Do You Want To Continue Setup ('y' to continue or 'n' to quit): " -ForegroundColor yellow -NoNewLine; Read-Host)
			
			Write-Host
		}
		while ($Continue -ne "y" -and $Continue -ne "n" )
		
		if ($Continue -eq "n")
		{
			exit
		}		 
	}
	return $TaskExists
}

function GetInput($PromptText)
{
	do{
		$InputText = $(Write-Host "" -NoNewLine) + $(Write-Host $PromptText ": " -ForegroundColor yellow -NoNewLine; Read-Host)
		Write-Host
	}
	while ($InputText -eq "")
	
	return $InputText
}

function GetMaskedInput($PromptText)
{
	do{
		$MaskedInputText = $(Write-Host "" -NoNewLine) + $(Write-Host $PromptText -ForegroundColor yellow -NoNewLine; Read-Host -AsSecureString)
		
		Write-Host
	}
	while ($MaskedInputText.Length -eq 0)
	
	# Decrypt the password and transform to plain text
	$PassPointer = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($MaskedInputText)
	$PasswordText = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($PassPointer)
	
	return $PasswordText
}

function GetFileAndVerifyExists($PromptText, $FileName)
{
	# Get the working directory
	[String] $CurrentDirectory = $pwd.ToString()
	
	# Prompt for script directory
	Write-Host $PromptText -ForegroundColor yellow
	$(Write-Host "Or To Use Default Path " -ForegroundColor yellow -NoNewLine) + $(Write-Host $CurrentDirectory  -ForegroundColor DarkGreen -NoNewLine) + $(Write-Host " Simply Press Enter" -ForegroundColor yellow)
	Write-Host
	
	do {
		$ScriptLocation = $(Write-Host "" -NoNewLine) + $(Write-Host "Enter Path: " -ForegroundColor yellow -NoNewLine; Read-Host)
		
		# Use default directory if no path was entered 
		if($ScriptLocation -eq "")
		{
			$ScriptLocation = $CurrentDirectory
		}
		
		$FilePath = Join-Path $ScriptLocation $FileName
		
		$FileExists = Test-Path -Path $FilePath -PathType Leaf
		
		if($FileExists)
		{
			Write-Host "File Located" $FilePath
		}
		else
		{
			Write-Host "File Not Located" $FilePath		
		}
	
		Write-Host		
	}
	while (-not $FileExists)
	
	return $FilePath
}

function CreateScheduledTask($ScriptPath, $DBInstance, $DBName, $DBUserName, $DBPassword, $runType){
    
    Write-Host $runType
    # Set the parameters for the Scheduled Task
	$Argument = " -file " + $ScriptPath + " -instance " + $DBInstance + " -db " + $DBName + " -username " + $DBUserName + " -password " + $DBPassword + " -runType " + $runType
	$TaskName = "";
	# Set the trigger for the Scheduled Task
	if ($runType -eq 0 )
    {
        # Daily Scheduled task
        # Build the task name using the Organisation Name 
	    $TaskName = "WeeklyReports-Daily" + $Organisation
        $Trigger= New-ScheduledTaskTrigger -At $DailyTaskRunTime -Daily
    }
    elseif($runType -eq 1) {
        # Every 15 mins
        $TaskName = "WeeklyReports-Every15Mins" + $Organisation
        $Trigger= New-ScheduledTaskTrigger -Once -At 01:00 ` -RepetitionInterval (New-TimeSpan -Minutes 15) `
    }
    Write-Host $TaskName
    # Check if we already have a task for this organisation
	$TaskExists = GetTaskExists $TaskName

	# Set the action for the Scheduled Task
	$Action= New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument $Argument
	
	# If Scheduled Task already exists update it
	# Otherwise Create and Register the Scheduled Task
	if($TaskExists) 
	{
		Set-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -Trigger $Trigger -Action $Action -User $User -Password $STPassword
		
		$(Write-Host "" -NoNewLine) + $(Write-Host "Task Updated Successfully, Press Enter to Complete: " -ForegroundColor yellow -NoNewLine; Read-Host)
		
		Write-Host
	}
	else
	{
		Register-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Trigger $Trigger -User $User -Password $STPassword -Action $Action -RunLevel Highest -Force
				
		$(Write-Host "" -NoNewLine) + $(Write-Host "Task Created Successfully, Press Enter to Complete: " -ForegroundColor yellow -NoNewLine; Read-Host)
		
		Write-Host
	}

}

try {
	# Check if we have SqlServer Module Installed
	$SqlServerModuleExists = Get-Module -ListAvailable -Name SqlServer
	
	# Install SqlServer Module
	if (-not $SqlServerModuleExists)
	{
		Install-Module -Name SqlServer
	}
	
	$ErrorActionPreference = "Stop"; #Make all errors terminating
	
	# Path to be used for Scheduled Task
	$TaskPath = "\eposity\"
	
	# Display Onscreen Instructions
	DisplayInstructions

	# Get the working directory
	[String] $CurrentDirectory = $pwd.ToString()
	
	# Prompt User for Organisation Name
	$Organisation = GetInput "Please Enter Organisation Name"
				
	# Prompt for Task User
	$User = GetInput "Please Enter User Id That The Task will Run Under"
		
	# Prompt for Task User Password
	$STPassword = GetMaskedInput "Please Enter User Password That The Task will Run Under: "
	
	# Prompt for powershell script directory	
	Write-Host "Please Enter Path To Powershell Script: " -ForegroundColor yellow
	
	Write-Host
	
	$(Write-Host "Or To Use Default Path " -ForegroundColor yellow -NoNewLine) + $(Write-Host $CurrentDirectory  -ForegroundColor DarkGreen -NoNewLine) + $(Write-Host " Simply Press Enter: " -ForegroundColor yellow)

	Write-Host		
		
	do {
		$ScriptLocation = $(Write-Host "" -NoNewLine) + $(Write-Host "Enter Path: " -ForegroundColor yellow -NoNewLine; Read-Host)
		
		Write-Host
	
		# Use default directory if no path was entered 
		if($ScriptLocation -eq "")
		{
			$ScriptLocation = $CurrentDirectory
		}
	
		# Append file name to path
		$ScriptPath = Join-Path $ScriptLocation "WeeklyReports.ps1"
		
		$ScriptFileExists = Test-Path -Path $ScriptPath -PathType Leaf	
		
		if($ScriptFileExists)
		{
			Write-Host "File Located" $ScriptPath
		
			Write-Host
		}
		else
		{
			Write-Host "File Not Located" $ScriptPath
		
			Write-Host		
		}
	}
	while (-not $ScriptFileExists)

    $DailyTaskRunTime = "11:59PM"
			
	# Prompt for Database Instance
	$DBInstance = GetInput "Please Enter Database Server (Instance)"
	
	# Prompt for Database Name
	$DBName = GetInput "Please Enter Database Name"
	
	# Prompt for Database User
	$DBUserName = GetInput "Please Enter Database User"
	
	# Prompt for Database User Password
	$DBPassword = GetMaskedInput "Please Enter Database Password: "	
			
    CreateScheduledTask $ScriptPath $DBInstance $DBName $DBUserName $DBPassword 0 # Daily Task
    CreateScheduledTask $ScriptPath $DBInstance $DBName $DBUserName $DBPassword 1 # Every 15 mins Task
		
} catch {
   Write-Host $_ -ForegroundColor red -BackgroundColor black;
} finally {
   $ErrorActionPreference = "Continue"; #Reset the error action pref to default
}