# // Copyright 2021 Keyfactor
# // Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
# // You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
# // Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
# // WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions
# // and limitations under the License.

### Create a new Service Now Incident

### DIRECTIONS:
### 1) See sample call at bottom of file with additional notes below that.

Function CreateSNIncident {
    [cmdletBinding()]

    param(
        $BaseUrl,
        $SN_ID,
        $SN_Password,
        $SN_ShortDescription,
        $SN_Priority,
        $SN_Urgency,
        $SN_Impact,
        $SN_AssignmentGroup
    )
    Add-Content -Path c:\psscripts\messages.txt $BaseUrl
    $uri = "$BaseUrl/api/now/table/incident"
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $SN_ID, $SN_Password)))

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add('authorization', 'Basic {0}' -f $base64AuthInfo)
    $headers.Add('content-type', 'application/json')
    $headers.Add('accept', 'application/json')

    $body = @{
        short_description = $SN_ShortDescription
        urgency = $SN_Urgency
        impact=$SN_Impact
        assignment_group = $SN_AssignmentGroup
    }

    $jsonBody = ConvertTo-Json $body -Depth 4

    #$jsonBody

    Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $jsonBody
}

### Parameters for the function call below ($content[*]) will be supplied by Keyfactor Command workflow
CreateSNIncident -BaseUrl $context["BaseUrl"] -SN_ID $context["SN_ID"] -SN_Password $context["SN_Password"] `
    -SN_ShortDescription $context["SN_ShortDescription"] -SN_Urgency $context["SN_Urgency"] `
    -SN_Impact $context["SN_Impact"] -SN_AssignmentGroup $context["SN_AssignmentGroup"]


#$context["BaseUrl"] - Base URL of the Service Now instance needing to be accessed
#$context["SN_ID"] - Login ID of Service Now instance
#$context["SN_Password"] - Login password of Service Now instance

### Below are Service Now incident table fields.  There are more fields available than what is used in this example.  More information can be found
###   by reviewing the Service Now Rest API Reference Guide => https://instance.service-now.com/incident_list.do?sysparm_query=active%3Dtrue%5Enumber%3DINC00100001&JSONv2 
#$context["SN_ShortDescription"] - Short description of incident 
#$context["SN_Urgency"] - Allowed values: 1, 2, or 3 - 1 = High, 2 = Medium, 3 = Low
#$context["SN_Impact"] - Allowed values: 1, 2, or 3 - 1 = High, 2 = Medium, 3 = Low
#$context["SN_AssignmentGroup"]- The unique ID of the user group this incident ticket will be assigned to

