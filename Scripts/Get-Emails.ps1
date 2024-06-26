Function Get-Email {
<#
    .SYNOPSIS
    Get a specific email.

    .DESCRIPTION
    Get a specific email based on userId and Internet Message Id and saves the output to a eml or txt file.

	.PARAMETER OutputDir
	OutputDir is the parameter specifying the output directory.
	Default: Output\EmailExport

	.PARAMETER UserIds
    The unique identifier of the user.

    .PARAMETER internetMessageId
    The InternetMessageId parameter represents the Internet message identifier of an item.

    .PARAMETER output
    Output is the parameter specifying the eml or txt output type.
	Default: eml

    .PARAMETER inputFile
    The inputFile parameter specifies the .txt file containing multiple Internet Message Identifiers. You can include multiple Internet Message Identifiers in the file. Ensure each ID is placed on a new line.

    .PARAMETER attachment
    The attachment parameter specifies whether the attachment should be saved or not. 
    Default: False 
    
    .EXAMPLE
    Get-Email -userIds fortunahodan@bonacu.onmicrosoft.com -internetMessageId "<d6f15b97-e3e3-4871-adb2-e8d999d51f34@az.westeurope.microsoft.com>" 
    Retrieves an email from fortunahodan@bonacu.onmicrosoft.com with the internet message identifier <d6f15b97-e3e3-4871-adb2-e8d999d51f34@az.westeurope.microsoft.com> to a eml file.
	
    .EXAMPLE
	Get-Email -userIds fortunahodan@bonacu.onmicrosoft.com -internetMessageId "<d6f15b97-e3e3-4871-adb2-e8d999d51f34@az.westeurope.microsoft.com>" -attachment True
    Retrieves an email and the attachment from fortunahodan@bonacu.onmicrosoft.com with the internet message identifier <d6f15b97-e3e3-4871-adb2-e8d999d51f34@az.westeurope.microsoft.com> to a eml file.
		
	.EXAMPLE
	Get-Email -userIds fortunahodan@bonacu.onmicrosoft.com -internetMessageId "<d6f15b97-e3e3-4871-adb2-e8d999d51f34@az.westeurope.microsoft.com>" -OutputDir C:\Windows\Temp
	Retrieves an email and saves it to C:\Windows\Temp folder.
#>
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)]$userIds,
		[string]$internetMessageId,
        [string]$output,
		[string]$outputDir,
        [string]$attachment,
        [string]$inputFile
	)  

    Write-logFile -Message "[INFO] Running Get-Email" -Color "Green"

    if ($outputDir -eq "" ){
        $outputDir = "Output\EmailExport"
        if (!(test-path $outputDir)) {
            write-logFile -Message "[INFO] Creating the following directory: $outputDir"
            New-Item -ItemType Directory -Force -Name $outputDir | Out-Null
        }
    }

    else {
		if (Test-Path -Path $OutputDir) {
			write-LogFile -Message "[INFO] Custom directory set to: $OutputDir"
		}
	
		else {
			write-Error "[Error] Custom directory invalid: $OutputDir exiting script" -ErrorAction Stop
			write-LogFile -Message "[Error] Custom directory invalid: $OutputDir exiting script"
		}
	}


    if ($inputFile) {
        try {
            $internetMessageIds = Get-Content $inputFile
        }
        catch {
            Write-Error "[ERROR] Failed to read the input file. Ensure it is a text file with the message IDs on new lines: $_"
            return
        }
    
        # Loop through each internetMessageId in the inputFile
        $notCollected = @()
        foreach ($id in $internetMessageIds) {
            $id = $id.Trim()
            write-host "[INFO] Identified: $id"
            try {
                $getMessage = Get-MgUserMessage -UserId $userIds -Filter "internetMessageId eq '$id'"
                $messageId = $getMessage.Id

                $subject = $getMessage.Subject
                $subject = $subject -replace '[\\/:*?"<>|]', '_'

                $ReceivedDateTime = $getMessage.ReceivedDateTime.ToString("yyyyMMdd_HHmmss")
        
                if ($output -eq "txt") {
                    $filePath = "$outputDir\$ReceivedDateTime-$subject.txt"
                }
                
                else {
                    $filePath = "$outputDir\$ReceivedDateTime-$subject.eml"
                }
            
                Get-MgUserMessageContent -MessageId $messageId -UserId $userIds -OutFile $filePath
                Write-logFile -Message "[INFO] Output written to $filePath" -Color "Green"
            
                if ($attachment -eq "True"){
                    Get-Attachment -Userid $Userids -internetMessageId $id
                }
            }
            catch {
                Write-Warning "[WARNING] Failed to collect message with ID '$id': $_"
                $notCollected += $id  # Add the message ID to the list of not collected IDs
            }
        }
        # Check if there are any message IDs that were not collected and write them to the log file
        if ($notCollected.Count -gt 0) {
            Write-logFile -Message "[INFO] The following messages have not been collected:" -Color "Yellow"
            foreach ($notCollectedID in $notCollected) {
                Write-logFile -Message "  $notCollectedID" -Color "Yellow"
            }
        }
    }

    else {
        # Check if internetMessageId is provided
        if (-not $internetMessageId) {
            Write-Error "[ERROR] Either internetMessageId or inputFile must be provided."
            return
        }
    
        try {
            $areYouConnected = Get-MgUserMessage -UserId $userIds -Filter "internetMessageId eq '$internetMessageId'"
        }
        catch {
            Write-logFile -Message "[WARNING] You must call Connect-MgGraph -Scopes Mail.ReadBasic.All before running this script" -Color "Red"
            Write-logFile -Message "[WARNING] The 'Mail.ReadBasic.All' is an application-level permission, requiring an application-based connection through the 'Connect-MgGraph' command for its use." -Color "Red"
            return
        }
    
        $getMessage = Get-MgUserMessage -UserId $userIds -Filter "internetMessageId eq '$internetMessageId'"
        $messageId = $getMessage.Id
    
        $subject = $getMessage.Subject
        $subject = $subject -replace '[\\/:*?"<>|]', '_'
    
        $ReceivedDateTime = $getMessage.ReceivedDateTime.ToString("yyyyMMdd_HHmmss")
    
        if ($output -eq "txt") {
            $filePath = "$outputDir\$ReceivedDateTime-$subject.txt"
        }
        
        else {
            $filePath = "$outputDir\$ReceivedDateTime-$subject.eml"
        }
    
        Get-MgUserMessageContent -MessageId $messageId -UserId $userIds -OutFile $filePath
        Write-logFile -Message "[INFO] Output written to $filePath" -Color "Green"
    
        if ($attachment -eq "True"){
            Get-Attachment -Userid $Userids -internetMessageId $internetMessageId
        }
    }   
}


Function Get-Attachment {
<#
    .SYNOPSIS
    Get a specific attachment.

    .DESCRIPTION
    Get a specific attachment based on userId and Internet Message Id and saves the output.

	.PARAMETER OutputDir
	OutputDir is the parameter specifying the output directory.
	Default: Output\Emails

	.PARAMETER UserIds
    The unique identifier of the user.

    .PARAMETER internetMessageId
    The InternetMessageId parameter represents the Internet message identifier of an item.

    .EXAMPLE
    Get-Attachment -userIds fortunahodan@bonacu.onmicrosoft.com -internetMessageId "<d6f15b97-e3e3-4871-adb2-e8d999d51f34@az.westeurope.microsoft.com>" 
    Retrieves the attachment from fortunahodan@bonacu.onmicrosoft.com with the internet message identifier <d6f15b97-e3e3-4871-adb2-e8d999d51f34@az.westeurope.microsoft.com>.
	
	.EXAMPLE
	Get-Attachment -userIds fortunahodan@bonacu.onmicrosoft.com -internetMessageId "<d6f15b97-e3e3-4871-adb2-e8d999d51f34@az.westeurope.microsoft.com>" -OutputDir C:\Windows\Temp
	Retrieves an attachment and saves it to C:\Windows\Temp folder.
#>
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)]$userIds,
		[Parameter(Mandatory=$true)]$internetMessageId,
		[string]$outputDir
	)

    write-host $internetMessageId
    write-host $userIds

    Write-logFile -Message "[INFO] Running Get-Attachment" -Color "Green"

    try {
        $areYouConnected = Get-MgUserMessage -Filter "internetMessageId eq '$internetMessageId'" -UserId $userIds -ErrorAction stop
    }
    catch {
        Write-logFile -Message "[WARNING] You must call Connect-MgGraph -Scopes Mail.Read, Mail.ReadBasic, Mail.ReadBasic.All before running this script" -Color "Red"
        Write-logFile -Message "[WARNING] The 'Mail.ReadBasic.All' is an application-level permission, requiring an application-based connection through the 'Connect-MgGraph' command for its use." -Color "Red"
        break
    }

    if ($outputDir -eq "" ){
        $outputDir = "Output\EmailExport"
        if (!(test-path $outputDir)) {
            New-Item -ItemType Directory -Force -Name $outputDir | Out-Null
            write-logFile -Message "[INFO] Creating the following directory: $outputDir"
        }
    }

    else {
		if (Test-Path -Path $OutputDir) {
			write-LogFile -Message "[INFO] Custom directory set to: $OutputDir"
		}
	
		else {
			write-Error "[Error] Custom directory invalid: $OutputDir exiting script" -ErrorAction Stop
			write-LogFile -Message "[Error] Custom directory invalid: $OutputDir exiting script"
		}
	}

    #$getMessage = Get-MgUserMessage -Filter "internetMessageId eq '$internetMessageId'" -UserId $userIds
    $getMessage = Get-MgUserMessage -UserId $userIds -Filter "internetMessageId eq '$internetMessageId'"
    $messageId = $getMessage.Id
    $messageId = $messageId.Trim()
    $hasAttachment = $getMessage.HasAttachments
    $ReceivedDateTime = $getMessage.ReceivedDateTime.ToString("yyyyMMdd_HHmmss")
    $subject = $getMessage.Subject
    $subject = $subject -replace '[\\/:*?"<>|]', '_'

    if ($hasAttachment -eq "True"){
        $attachments = Get-MgUserMessageAttachment -UserId $userIds -MessageId $messageId

        foreach ($attachment in $attachments){
            $filename = $attachment.Name
        
            Write-logFile -Message "[INFO] Found attachment named $filename"
            Write-logFile -Message "[INFO] Downloading attachment"
            Write-host "[INFO] Name: $filename"
            write-host "[INFO] Size: $($attachment.Size)"
        
            $base64B = ($attachment).AdditionalProperties.contentBytes
            $decoded = [System.Convert]::FromBase64String($base64B)

            $filename = $filename -replace '[\\/:*?"<>|]', '_'
            $filePath = Join-Path -Path $outputDir -ChildPath "$ReceivedDateTime-$subject-$filename"
            Set-Content -Path $filePath -Value $decoded -Encoding Byte
        
            Write-logFile -Message "[INFO] Output written to '$subject-$filename'" -Color "Green"
        }
    }

    else {
        Write-logFile -Message "[WARNING] No attachment found for: $subject" -Color "Red"
    }
}


Function Show-Email {
<#
    .SYNOPSIS
    Show a specific email in the PowerShell Window.

    .DESCRIPTION
    Show a specific email in the PowerShell Window based on userId and Internet Message Id.

    .EXAMPLE
    Show-Email -userIds {userId} -internetMessageId {InternetMessageId}
    Show a specific email in the PowerShell Window.
	
#>
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)]$userIds,
		[Parameter(Mandatory=$true)]$internetMessageId
	)

    Write-logFile -Message "[INFO] Running Show-Email" -Color "Green"

    try {
        $areYouConnected = Get-MgUserMessage -Filter "internetMessageId eq '$internetMessageId'" -UserId $userIds -ErrorAction stop
    }
    catch {
        Write-logFile -Message "[WARNING] You must call Connect-MgGraph -Scopes Mail.Read, Mail.ReadBasic, Mail.ReadBasic.All, Mail.ReadWrite before running this script" -Color "Red"
        Write-logFile -Message "[WARNING] The 'Mail.ReadBasic.All' is an application-level permission, requiring an application-based connection through the 'Connect-MgGraph' command for its use." -Color "Red"
        break
    }

    Get-MgUserMessage -Filter "internetMessageId eq '$internetMessageId'" -UserId $userIds | fl *
}