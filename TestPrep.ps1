## This script restores all of the databases from their original backup
## This is before tests were run.

param([string]$stepNumber = "",
    [string]$action = ""
)


# $dbs = @(
#     "12922_0x0B02A"
#     , "12922_0x05015"
#     , "14103_0x0B02A"
#     , "14103_0x05015"
#     , "14203_0x0B42A"
#     , "14203_0x04815"
#     , "14306_0x0B42A"
#     , "14306_0x04815"
#     , "14501_0x0B42A"
#     , "14501_0x04815"
#     , "14602_0x4B62A"
#     , "14602_0x24915"
#     , "14602_0x10080"
#     , "14602_0x00040"
# )

$dbsStep1 = 
@("12922_0x0B02A", "JRHSGI"),
@("14103_0x0B02A", "AAAUPI"),
@("14203_0x0B42A", "YKSWYI"),
@("14306_0x0B42A", "BQCYVV"),
@("14501_0x0B42A", "VWZEYM"),
@("14602_0x4B62A", "TCUZKB")

$dbsStep2 = 
@("12922_0x05015", "JRHSGI"),
@("14103_0x05015", "AAAUPI"),
@("14203_0x04815", "YKSWYI"),
@("14306_0x04815", "BQCYVV"),
@("14501_0x04815", "VWZEYM"),
@("14602_0x24915", "TCUZKB")

# Powershell does not like an array of arrays with only 1 element
$dbsStep3 = New-Object string[][] (1, 1)
$dbsStep3[0] = @("14602_0x10080", "TCUZKB")

$dbsStep4 = New-Object string[][] (1, 1)
$dbsStep4[0] = @("14602_0x00040", "TCUZKB")

$icpUsers = New-Object string[][] (1, 1)
$icpUsers[0] = @("ICPAutomatedTest", "ICPAutomatedTest123", "Jane C Bush")

$recoveryInformation = 
@("User129", "JRHSGI", "User129Recovery"),
@("User141", "AAAUPI", "User141Recovery"),
@("User142", "YKSWYI", "User142Recovery"),
@("User143", "BQCYVV", "User143Recovery"),
@("User145", "VWZEYM", "User145Recovery"),
@("User146", "TCUZKB", "User146Recovery")


function RestoreDBs {
    param (
        [parameter(Mandatory = $true)]
        $dbs
    )
    foreach ($db in $dbs) {
        $subkey = $db.split("_")[0]
        $sqlCommand = 
        @"
USE [master]
ALTER DATABASE [PracData_$($subkey)] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
RESTORE DATABASE [PracData_$($subkey)] FROM  DISK = N'C:\data\Pracdata_$($db[0])' WITH  FILE = 1,  NOUNLOAD,  STATS = 5
ALTER DATABASE [PracData_$($subkey)] SET MULTI_USER

GO
"@
        Write-Host($sqlCommand)
        Invoke-Sqlcmd -Query $sqlCommand
    
    }
}

function CreateDataXML {
    param (
        [parameter(Mandatory = $true)]
        $dbs,
        [parameter(Mandatory = $false)]
        $users
    )

    $fileName = "DataDriven.xml"
    # Set The Formatting
    $xmlsettings = New-Object System.Xml.XmlWriterSettings
    $xmlsettings.Indent = $true
    $xmlsettings.IndentChars = "    "
    # Set the File Name Create The Document
    if (Test-Path $fileName) {
        Remove-Item $fileName
    }
    $XmlWriter = [System.XML.XmlWriter]::Create($fileName, $xmlsettings)
    # Write the XML Decleration and set the XSL
    $xmlWriter.WriteStartDocument()

    # Start the Root Element
    $xmlWriter.WriteStartElement("tests")
    foreach ($db in $dbs) {
        Write-Host $db
        $XmlWriter.WriteStartElement("credential"); # <-- Start <Object>
        $XmlWriter.WriteAttributeString("username", $db[0])
        $XmlWriter.WriteAttributeString("password", $db[0])
        $XmlWriter.WriteAttributeString("patientName", "Test Patient1")
        $XmlWriter.WriteAttributeString("demographicsReadOnly", ($stepNumber -eq 2))
        $xmlWriter.WriteEndElement() # <-- End <Object>

        $XmlWriter.WriteStartElement("registration"); # <-- Start <Object>
        $XmlWriter.WriteAttributeString("databaseTag", $db[0])
        $XmlWriter.WriteAttributeString("firstname", "Test");
        $XmlWriter.WriteAttributeString("lastname", "Patient1");
        $XmlWriter.WriteAttributeString("dateofbirth", "01011970");
        $XmlWriter.WriteAttributeString("zipcode", "11111");
        $XmlWriter.WriteAttributeString("practice", $db[1]);
        $XmlWriter.WriteAttributeString("securitycode", "453428798");
        $xmlWriter.WriteEndElement() # <-- End <Object>
    }
    if ($users) {
        foreach ($userPass in $users) {
            $XmlWriter.WriteStartElement("credential");
            $XmlWriter.WriteAttributeString("username", $userPass[0])
            $XmlWriter.WriteAttributeString("password", $userPass[1])
            $XmlWriter.WriteAttributeString("patientName", $userPass[2])
            $xmlWriter.WriteEndElement() # <-- End <Object>
        }
    }

    $XmlWriter.WriteStartElement("singleCredential"); # <-- Start <singleCredential>
    $XmlWriter.WriteAttributeString("username", "Automation_Test1.1")
    $XmlWriter.WriteAttributeString("password", "Password.1")
    $XmlWriter.WriteAttributeString("patientName", "OneTimeAutomationFirst Middle OneTimeAutomationLast")
    $xmlWriter.WriteEndElement() # <-- End <singleCredential>

    $XmlWriter.WriteStartElement("singleRegistration"); # <-- Start <singleRegistration>
    $XmlWriter.WriteAttributeString("firstname", "OneTimeAutomationFirst")
    $XmlWriter.WriteAttributeString("lastname", "OneTimeAutomationLast")
    $XmlWriter.WriteAttributeString("dateofbirth", "01011990")
    $XmlWriter.WriteAttributeString("zipcode", "33609")
    $XmlWriter.WriteAttributeString("practice", "NX-SELECT")
    $XmlWriter.WriteAttributeString("securitycode", "051103586")
    $xmlWriter.WriteEndElement() # <-- End <singleRegistration>

$XmlWriter.WriteStartElement("addPatient"); # <-- Start <addPatient>
    $XmlWriter.WriteAttributeString("username", "12922_0x0B02E")
    $XmlWriter.WriteAttributeString("password", "12922_0x0B02A")
    $XmlWriter.WriteAttributeString("databaseTag", "12922_0x05015")
    $XmlWriter.WriteAttributeString("practice", "JRHSGI")
    $XmlWriter.WriteAttributeString("firstnameA", "Test")
    $XmlWriter.WriteAttributeString("lastnameA", "Patient3")
    $XmlWriter.WriteAttributeString("dateofbirthA", "03031970")
    $XmlWriter.WriteAttributeString("zipcodeA", "33333")
    $XmlWriter.WriteAttributeString("securitycodeA", "655680751")
    $XmlWriter.WriteAttributeString("firstnameB", "Test")
    $XmlWriter.WriteAttributeString("lastnameB", "Patient1")
    $XmlWriter.WriteAttributeString("dateofbirthB", "01011970")
    $XmlWriter.WriteAttributeString("zipcodeB", "11111")
    $XmlWriter.WriteAttributeString("securitycodeB", "453428798")
    $xmlWriter.WriteEndElement() # <-- End <addPatient>
   
   $XmlWriter.WriteStartElement("PPlus/Select(iPad)"); # <-- Start <PPlus/Select(iPad)>
    $XmlWriter.WriteAttributeString("username", "PPlusSelect_Automation")
    $XmlWriter.WriteAttributeString("password", "Password.1")
    $XmlWriter.WriteAttributeString("databaseTag", "")
    $XmlWriter.WriteAttributeString("practice", "HMKNRZ")
    $XmlWriter.WriteAttributeString("firstname", "FirstNameHMKNRZ")
    $XmlWriter.WriteAttributeString("lastname", "LastNameHMKNRZ")
    $XmlWriter.WriteAttributeString("dateofbirth", "01011990")
    $XmlWriter.WriteAttributeString("zipcode", "33609")
    $xmlWriter.WriteEndElement() # <-- End <PPlus/Select(iPad)>

    $XmlWriter.WriteStartElement("Select/ICP"); # <-- Start <Select/ICP>
    $XmlWriter.WriteAttributeString("username", "NxICP_Automation")
    $XmlWriter.WriteAttributeString("password", "Password.1")
    $XmlWriter.WriteAttributeString("databaseTag", "")
    $XmlWriter.WriteAttributeString("practice", "nx-select")
    $XmlWriter.WriteAttributeString("firstname", "FirstNxICP")
    $XmlWriter.WriteAttributeString("lastname", "LastNxICP")
    $XmlWriter.WriteAttributeString("dateofbirth", "01011990")
    $XmlWriter.WriteAttributeString("zipcode", "33609")
    $xmlWriter.WriteEndElement() # <-- End <Select/ICP>

    $XmlWriter.WriteStartElement("PPlus/ICP"); # <-- Start <PPlus/ICP>
    $XmlWriter.WriteAttributeString("username", " ICPPP_Automation")
    $XmlWriter.WriteAttributeString("password", "Password.1")
    $XmlWriter.WriteAttributeString("databaseTag", "")
    $XmlWriter.WriteAttributeString("practice", "ICPPP")
    $XmlWriter.WriteAttributeString("firstname", "FirstICPPP")
    $XmlWriter.WriteAttributeString("lastname", "LastICPPP")
    $XmlWriter.WriteAttributeString("dateofbirth", "01011990")
    $XmlWriter.WriteAttributeString("zipcode", "33609")
    $xmlWriter.WriteEndElement() # <-- End <PPlus/ICP>
    
    if($stepNumber -eq 1) {
        foreach ($recovery in $recoveryInformation) {
            $XmlWriter.WriteStartElement("userRecovery"); # <-- Start <Object>
            $XmlWriter.WriteAttributeString("firstname", "Forgot");
            $XmlWriter.WriteAttributeString("lastname", $recovery[0]);
            $XmlWriter.WriteAttributeString("dateofbirth", "01011995");
            $XmlWriter.WriteAttributeString("zipcode", "33609");
            $XmlWriter.WriteAttributeString("practice", $recovery[1]);
            $XmlWriter.WriteAttributeString("userName", $recovery[2]);
            $xmlWriter.WriteEndElement() # <-- End <Object>
            }
        }
      Elseif($stepNumber -eq 2) {
        foreach ($recovery in $recoveryInformation) {
            $XmlWriter.WriteStartElement("userRecovery"); # <-- Start <Object>
            $XmlWriter.WriteAttributeString("firstname", "Forgot");
            $XmlWriter.WriteAttributeString("lastname", $recovery[0]);
            $XmlWriter.WriteAttributeString("dateofbirth", "01011995");
            $XmlWriter.WriteAttributeString("zipcode", "33609");
            $XmlWriter.WriteAttributeString("practice", $recovery[1]);
            $XmlWriter.WriteAttributeString("userName", $recovery[2]);
            $xmlWriter.WriteEndElement() # <-- End <Object>
            }
        }
      Elseif($stepNumber -eq 3) {
        foreach ($recovery in $recoveryInformation) {
            $XmlWriter.WriteStartElement("userRecovery"); # <-- Start <Object>
            $XmlWriter.WriteAttributeString("firstname", "Forgot");
            $XmlWriter.WriteAttributeString("lastname", $recovery[0]);
            $XmlWriter.WriteAttributeString("dateofbirth", "01011995");
            $XmlWriter.WriteAttributeString("zipcode", "33609");
            $XmlWriter.WriteAttributeString("practice", $recovery[1]);
            $XmlWriter.WriteAttributeString("userName", $recovery[2]);
            $xmlWriter.WriteEndElement() # <-- End <Object>
            }
        }
      Else { 
        foreach ($recovery in $recoveryInformation) {
            $XmlWriter.WriteStartElement("userRecovery"); # <-- Start <Object>
            $XmlWriter.WriteAttributeString("firstname", "Forgot");
            $XmlWriter.WriteAttributeString("lastname", $recovery[0]);
            $XmlWriter.WriteAttributeString("dateofbirth", "01011995");
            $XmlWriter.WriteAttributeString("zipcode", "33609");
            $XmlWriter.WriteAttributeString("practice", $recovery[1]);
            $XmlWriter.WriteAttributeString("userName", $recovery[2]);
            $xmlWriter.WriteEndElement() # <-- End <Object>
        }    
}


    $xmlWriter.WriteEndElement() # <-- End <Root> 
    # End, Finalize and close the XML Document
    $xmlWriter.WriteEndDocument()
    $xmlWriter.Flush()
    $xmlWriter.Close()

    Get-Content $fileName
    # This is done when in Azure pipeLine
    if(Test-Path d:\a\1\s\Host\Portal6\MyPatientVisit.FunctionalTest\MyPatientVisit.FunctionalTest\bin\Debug\Data\DataDriven.xml)
    {
        Write-Host("Found DataDriven.xml replacing")
        Copy-Item $fileName d:\a\1\s\Host\Portal6\MyPatientVisit.FunctionalTest\MyPatientVisit.FunctionalTest\bin\Debug\Data\DataDriven.xml -force
        Copy-Item $fileName d:\a\1\s\Host\Portal6\MyPatientVisit.FunctionalTest\MyPatientVisit.FunctionalTest\Data\DataDriven.xml -force
        Get-Content d:\a\1\s\Host\Portal6\MyPatientVisit.FunctionalTest\MyPatientVisit.FunctionalTest\bin\Debug\Data\DataDriven.xml
    }
}

$dbToProcess = $null;
switch ($stepNumber) {
    "1" { 
        $dbToProcess = $dbsStep1
    }
    "2" { 
        $dbToProcess = $dbsStep2
    }
    "3" { 
        $dbToProcess = $dbsStep3
    }
    "4" { 
        $dbToProcess = $dbsStep4
    }
    Default {
        $dbToProcess = $null;
        Write-Host "-stepNumber is required ie: -stepNumber 1"
        exit 400
    }
}

if ($action -eq "restoreDatabases") {
    RestoreDBs $dbToProcess
}
elseif ($action -eq "generateTestSettings") {
    if ($stepNumber -eq "1") {
        CreateDataXML $dbToProcess 
    }
    else {
        CreateDataXML $dbToProcess
    }
}
else {
    Write-Host("Unrecognized action")
    Write-Host("-action parameter required, ""restoreDatabases"" and ""generateTestSettings"" supported ")
    exit 400
}
