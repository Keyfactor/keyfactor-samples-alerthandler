# // Copyright 2021 Keyfactor
# // Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
# // You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
# // Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
# // WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions
# // and limitations under the License.

[hashtable]$context
$pendingWindow = $context["timeframe"] # hardcoded parameter
$requestDate = $context["requestDate"] # Submission Date variable

# calculate timespan since request date
$currentDate = Get-Date
$dateDiff = New-TimeSpan -Start $requestDate -End $currentDate

if ($dateDiff.days -gt $pendingWindow) {
    # send a priority email
    $smtp = New-Object Net.Mail.SmtpClient("mykeyfactorinstance.com")
    $mail = New-Object System.Net.Mail.MailMessage

    $mail.From = "from@mykeyfactorinstance.com"
    $mail.To.Add($context["Recipient"])
    $mail.Subject = "PRIORITY - Pending Certificate - " + $context["Subject"]
    $mail.Body = $context["Body"]

    $mail.Priority = [System.Net.Mail.MailPriority]::High
    $smtp.Send($mail)

    # tell Keyfactor Platform not to send its own email
    $context["SendEmail"] = "false"
}