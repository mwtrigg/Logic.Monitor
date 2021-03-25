#Requires -Version 6.1.0
Function Import-LMLogicModule {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [String]$FilePath,

        [ValidateSet("datasource", "propertyrules", "eventsource", "topologysource", "configsource")]
        [String]$Type = "datasource",

        [Boolean]$ForceOverwrite = $false
    )

    #Check if we are logged in and have valid api creds
    Begin{}
    Process{
        If($global:LMAuth.Valid){

            If(!(Test-Path -Path $FilePath) -and ((!([IO.Path]::GetExtension($FilePath) -eq '.xml')) -or (!([IO.Path]::GetExtension($FilePath) -eq '.json')))){
                Write-Host "File not found or is not a valid xml/json file, check file path and try again" -ForegroundColor Yellow
                Return
            }

            #Build query params
            $QueryParams = "?type=$Type&forceOverwrite=$ForceOverwrite"

            #Build header and uri
            $ResourcePath = "/setting/logicmodules/importfile"

            #Get file content
            $File = Get-Content $FilePath -Raw

            Try{

                $Headers = New-LMHeader -Auth $global:LMAuth -Method "POST" -ResourcePath $ResourcePath -Data $File
                $Uri = "https://$($global:LMAuth.Portal).logicmonitor.com/santaba/rest" + $ResourcePath + $QueryParams

                #Issue request
                $Response = Invoke-RestMethod -Uri $Uri -Method "POST" -Headers $Headers -Form @{file = $File}
                Write-Host "Successfully imported $([IO.Path]::GetFileName($FilePath)) of type: $($Response.items.type)"

                Return

            }
            Catch [Exception] {
                $Exception = $PSItem
                Switch($PSItem.Exception.GetType().FullName){
                    {"System.Net.WebException" -or "Microsoft.PowerShell.Commands.HttpResponseException"} {
                        $HttpException = ($Exception.ErrorDetails.Message | ConvertFrom-Json).errorMessage
                        $HttpStatusCode = $Exception.Exception.Response.StatusCode.value__
                        Write-Error "Failed to execute web request($($HttpStatusCode)): $HttpException"
                    }
                    default {
                        $LMError = $Exception.ToString()
                        Write-Error "Failed to execute web request: $LMError"
                    }
                }
            }
        }
        Else{
            Write-Host "Please ensure you are logged in before running any comands, use Connect-LMAccount to login and try again." -ForegroundColor Yellow
        }
    }
    End {}
}