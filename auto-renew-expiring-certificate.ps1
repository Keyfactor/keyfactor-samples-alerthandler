# // Copyright 2021 Keyfactor
# // Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
# // You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
# // Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
# // WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions
# // and limitations under the License.

[hashtable]$context
$DN = $context["dn"]
$CA = $context["ca"]
$Thumb = $context["thumb"]

# script variables
#############################################################
$apiUrl = "https://keyfactor01.mykeyfactorinstance.com/KeyfactorAPI" # update to be Keyfactor API endpoint
$pfxUrl = "https://keyfactor01.mykeyfactorinstance.com/KeyfactorAPI/Enrollment/PFX"
$ApiKey = "ABCmybase64key=="
$Template = "MyCertificateTemplate"
$username = "domain\api-user" #To Do: Change to your API User
$password = "api-user-password" | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $password)
$PFXPwd = "Password1234" # password for the private keys being entered into Keyfactor for the PFX certificates
$CA = "MyCA.domain.local\\MyCA-CA" # change to your issuing CA - might require format of: <CA Host Name>\\<CA Logical Name>
$LogDest = "C:\Scripts\RequestNoSansCert_Sectigo\Logs\log.log" # the location for the error log file, the script will create this file
#############################################################

Function LogWrite($LogString)
{
    Add-Content $LogDest -value $LogString
}

Function ReplaceCert ($OldID, $NewID)
{
    try
    {
        $replaceURL = $pfxUrl + "/Replace"
        $timeStamp = (Get-Date).ToUniversalTime()

        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $headers.Add('content-type', 'application/json')
        $headers.Add("X-Keyfactor-Requested-With", "APIClient")

        $Body = @"
{
    "ExistingCertificateId": $OldID,
    "CertificateId": $NewID,
    "Password": "$PFXPwd",
    "JobTime" : "$timeStamp"
}
"@  

        $certificateResponse = Invoke-RestMethod `
        -Method Post `
        -Uri $replaceUrl `
        -Credential $credential `
        -Headers $headers `
        -Body $Body `
        -ContentType "application/json"

    }
    catch
    {
        LogWrite "An error occurred replacing the bindings of the cert in the store"
        LogWrite $_
        return "REPLACE_ERROR" 
    }
}

Function GetId
{
    try
    {
        $searchURL = $apiUrl + "/certificates/?verbose=1&maxResults=50&page=1&query=Thumbprint%20-eq%20`""+$Thumb+"`""

        $certificateResponse = Invoke-RestMethod `
        -Method Get `
        -Uri $searchUrl `
        -Credential $credential `
        -ContentType "application/json"

        Return $certificateResponse.Id
    }
    catch
    {
        LogWrite "An error occurred looking up the certificate in keyfactor"
        LogWrite $_
        return "SEARCH_ERROR"        
    }
}

Function BuildCertRequest($ID)
{
    #Build Request
    $timeStamp = (Get-Date).ToUniversalTime()
    $Body = @"
{
    "timestamp" : "$timeStamp", 
    "IncludeChain": true,
    "CertificateAuthority": "$CA",
    "Template": "$Template",
    "RenewalCertificateId": "$ID",
    "Subject": "$DN",
    "Password": "$PFXPwd"
}
"@
    return $Body
}


Function MakeRequest($Body,$name,$API)
{
    #create secure headers
    # ===== Construct Headers
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add('content-type', 'application/json')
	$headers.Add("X-Keyfactor-AppKey", $API)
    $headers.Add("X-CertificateFormat", "STORE")
    $headers.Add("X-Keyfactor-Requested-With", "APIClient")

    try
    {
        #make certificate request
        $certificateResponse = Invoke-RestMethod `
	        -Method POST `
	        -Uri $pfxUrl `
	        -Headers $headers `
	        -Body $Body `
	        -ContentType "application/json" `
	        -Credential $credential

        return $certificateResponse.CertificateInformation.KeyfactorId
    }

    catch
    {
        LogWrite "An error occurred requesting the certificate from keyfactor"
        LogWrite $_
        return "REQUEST_ERROR"
    }
}

try
{
    LogWrite (Get-Date).ToUniversalTime().ToString()
    LogWrite $DN
    LogWrite $Thumb
}
catch
{
    LogWrite "An error occurred reading info into the logs"
    LogWrite $_
    return "INFO_ERROR"
}

try
{
    #get CertID
    $CertID = GetId        
    #generate a pfx request
    $Request = BuildCertRequest $CertID
    #make API request and store new CertID
    $NewID = MakeRequest $Request $PFXName $ApiKey
    #Replace the Bindings on the new cert
    ReplaceCert $CertID $NewID
}
catch
{
    LogWrite (Get-Date).ToUniversalTime().ToString()
    LogWrite "Script Failed Gracefully"
}