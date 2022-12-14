# ___ ___ _____ ___
#| _ \ _ \_   _/ __|
#|  _/   / | || (_ |
#|_| |_|_\ |_| \___|
#    NETWORK MONITOR
#-------------------
# Description: This notification script will send to your Discord Channel  
# Parameters:
#    [string]$sensor        - the name of the sensor
#    [string]$sensorid      - the id of the sensor
#    [string]$status        - the status 
#    [string]$message       - the message of the sensor 
#    [string]$since         - the time since the state is like this
#    [string]$lastup        - the time the sensor was up last
#    [string]$device        - the device of the sensor
#    [string]$sensorURL     - the sensor URL so you can access it directly
#    [string]$deviceURL     - the device URL 
#    [string]$serviceURL    - the service URL
#    [string]$webhookURI    - the Discord webhook URI
# 
# Requirements
# ------------------
# - [IMPORTANT] PRTG Sample powershell scripts must work - Guide for installing PowerShell based sensors: https://kb.paessler.com/users/my_answers/71356
# - A webhook for your channel (see https://support.discordapp.com/hc/en-us/articles/228383668-Intro-to-Webhooks)
# - This script located in <PRTG Home directory>\Notifications\EXE\ eg C:\Program Files (x86)\PRTG Network Monitor\Notifications\EXE
# 
# Modification Resources
# The script I adapted this from (MSTeams Notifications) Full installation guide can be found here: https://kb.paessler.com/en/topic/72306#
# Webhook documentation: https://discordapp.com/developers/docs/resources/webhook#execute-webhook
# Example used to create sample payload: https://birdie0.github.io/discord-webhooks-guide/discord_webhook.html
# Other inputs this script can recieve: https://kb.paessler.com/en/topic/373-what-placeholders-can-i-use-with-prtg
# Note, In order for the script to function you will need to replace all instances of: REPLACE ME
#
# TIP - create a new PRTG Notification Template
# Execute Program = enabled
# Executable File = name of this script from drop down list
# Parameters to paste
# -sensor '%sensor' -sensorID '%sensorid' -status '%status' -message '%message' -since '%since' -lastup '%lastup' -device '%device' -sensorURL '%linksensor' -deviceURL '%linkdevice' -serviceURL '%serviceurl' -uri 'https://discord.com/api/webhooks/your_webhook_uri_here'

# Version History 
# ------------------
# Version  Date        Notes
# 1.0      9/06/2019  Initial Release
# 2.0      12/12/2022 JJW Version fork with fixes and new features, e.g. TLS and logos
# ------------------
# (c) 2019 Michael Metully

param(
    [string]$sensor = "Ping",
    [string]$sensorid = 0,
    [string]$status = "Down",
    [string]$message = "Script launched without parameters (DEBUG)",
    [string]$device = "myWorkstationName",
    [string]$since = "falsetime",
    [string]$lastup = "falsetime",
    [string]$sensorURL = "http://www.google.com",
    [string]$deviceURL = "http://www.google.com",
    [string]$serviceURL = "http://www.google.com",
    [string]$uri = "https://www.google.com"
)

################
# Configuration 
################

#PRTG Server
#defaults for new install below, update to match your environment
$PRTGUsername = "prtgadmin"
$PRTGPasshash  = "prtgadmin"
#logo URLs, test these in a browser to ensure are still valid
$prtglogo = "https://is5-ssl.mzstatic.com/image/thumb/Purple125/v4/27/e3/5a/27e35a98-a778-a0fb-d70c-a92ad601e423/source/60x60bb.jpg"
#Status logos are from this page
# https://www.paessler.com/manuals/prtg/sensor_states
$downlogo = "https://manuals.paessler.com/i_status_red.png"
$uplogo = "https://manuals.paessler.com/i_status_green_zoom90.png"
$warninglogo = "https://manuals.paessler.com/i_status_yellow.png"
$unknownlogo = "https://manuals.paessler.com/i_status_grey.png"
$msglogo = $unknownlogo

#Acknowledgement Message for alerts ack'd via Discord
$ackmessage = "Problem has been acknowledged via Discord"

#Directory for logging
$logDirectory = "C:\ProgramData\Paessler\PRTG Network Monitor\Logs\custom_exe\discord_webhook.log"

# the acknowledgement URL 
$ackURL = [string]::Format("{0}/api/acknowledgealarm.htm?id={1}&ackmsg={2}&username={3}&passhash={4}",$serviceURL,$sensorID,[uri]::EscapeDataString($ackmessage),$PRTGUsername,$PRTGPasshash);

# the title of your message, different templates for not up, up and acknowledged
if($status -ne "Up")
{ $title = [string]::Format("{0} on {1} is in a state: {2}", $sensor, $device, $status) }
elseif($status -eq "Up")
{ $title = [string]::Format("{0} on {1} is: UP", $sensor, $device); $ackURL = ""; }
elseif($status -eq "Acknowledged")
{ $title = [string]::Format("The problem with {0} on {1} has been acknowledged.", $sensor, $device); $ackURL = ""; }

if($status -eq "Down")
{ $msglogo = $downlogo }
elseif($status -eq "Down ended (now: Up)")
{ $msglogo = $uplogo }
elseif($status -eq "Down ended (now: Warning)")
{ $msglogo = $warninglogo }
#elseif($status -eq "Acknowledged")
#{ $msglogo = $uplogo }


# accept all HTTPS certificates, necessary for the webhook 
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

########################
#Help found here
# https://birdie0.github.io/discord-webhooks-guide/discord_webhook.html
$body = ConvertTo-Json -Depth 6 @{
    content = $($title)
    avatar_url = $($prtglogo)
    embeds = @(
        @{
            title = 'Details'
            description = "[Sensor Page]($sensorURL) - [Device Page]($deviceURL) - [Acknowledge Alert]($ackURL)"
            thumbnail = @{
                url =  $($msglogo)
            }
            fields = @(
                @{
                name = 'Current State'
                value = $($status)
                },
                @{
                name = 'Message'
                value = $($message)
                },
                @{
                name = 'Since'
                value = $($since)
                },
                @{
                name = 'Last up'
                value = $($lastup)
                }
            )
        }
    )
}

# We need to encode the body with UTF8, otherwise the send might
# fail if the messages contain any characters that cannot be converted
$enc = [system.Text.Encoding]::UTF8
$encodedBody = $enc.GetBytes($body)

[Net.ServicePointManager]::SecurityProtocol = "Tls, Tls11, Tls12, Ssl3"
try 
{ Invoke-RestMethod -uri $uri -Method Post -body $encodedBody -ContentType 'application/json'; exit 0; }
Catch
{
    $ErrorMessage = $_.Exception.Message
    (Get-Date).ToString() +" - "+ $ErrorMessage | Out-File -FilePath $LogDirectory -Append
    exit 2;
}
