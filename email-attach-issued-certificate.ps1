# // Copyright 2021 Keyfactor
# // Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
# // You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
# // Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
# // WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions
# // and limitations under the License.

## The Issued Alert PowerShell handler will hand us a $context variable which is a hashtable containing both system and user defined values
## When configuring the alert:
##    Create a "Special Text" (token) parameter "Thumbprint" mapped to the special "thumbprint" token
##    Create a ScriptName "script" parameter containing the full path to this PowerShell script
##    Specify the Recipients, Subject, and Message body for the email

# We are sending the email from within this script, tell Keyfactor not to also send an email when we return

$context["sendEMail"] = "false"

# Keyfactor REST call to query the issued certificate by thumbprint

$uri = 'https://kftrain.keyfactor.lab/KeyfactorApi/certificates?verbose=2&pq.querystring=(Thumbprint -eq "'+ $context["Thumbprint"] +'")'

# Email server configuration (These could potentially be passed in as parameters)

$FromAddress = "nothing@keyfactor.lab"
$SMTPServer = "kftrain.keyfactor.lab"

# Make the REST call to Keyfactor and get the result into "CER" file format

# For Windows Authentication use this:
#    Windows Auth must be an enabled authentication method for the KeyfactorAPI endpoint
#    The Keyfactor Service account must have rights to query certificates via the API
$response = Invoke-RestMethod -Uri $uri -Method GET -UseDefaultCredentials -ContentType 'application/json'

# For Basic Authntication use this:
#    Basic Auth must be an enabled authentication method for the KeyfactorAPI endpoint
#    Replace the XXXXX in the authorization header with a base64 encoded username and password in the form of domain\account:password
#    The account must have rights to query certificates via the API
#
# $headers=@{}
# $headers.Add("Authorization", "Basic XXXXX")
# $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -ContentType 'application/json'

$base64Cert = $response.ContentBytes
$cert = "-----BEGIN CERTIFICATE-----" + $base64Cert + "-----END CERTIFICATE-----"

# Create a unique temporary directory

$dirName = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
$dir = New-Item -ItemType Directory -Path $dirName

# Generate the cert file name baed on the CN and replacing invalid file name characters with underscores

$certFile = $response.IssuedCN -replace "[$([RegEx]::Escape([string][IO.Path]::GetInvalidFileNameChars()))]+","_"
$certFilePath = Join-Path -Path $dirName -ChildPath ($certFile + ".txt")

# Write the cert to our temp file

Write-Verbose "Placing certificate in temp file $($certFilePath)"
Set-Content -Path $certFilePath -Value $cert

# Send the Email
# Use the Recipient, Subject, and Message that was configured in the alert handler configuration

Send-MailMessage -From $FromAddress -To $context["Recipient"] -Subject $context["Subject"] -Body $context["Message"] -Attachments $certFilePath -Priority High -SmtpServer $SMTPServer

# Clean up the directory and file
Remove-Item $certFilePath
Remove-Item $dirName
