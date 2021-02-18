Function Remove-LMDashboard
{

    [CmdletBinding(DefaultParameterSetName = 'Id')]
    Param (
        [Parameter(Mandatory,ParameterSetName = 'Id')]
        [Int]$Id,

        [Parameter(Mandatory,ParameterSetName = 'Name')]
        [String]$Name

    )
    #Check if we are logged in and have valid api creds
    If($global:LMAuth.Valid){

        #Lookup Id if supplying username
        If($Name){
            If($Name -Match "\*"){
                Write-Host "Wildcard values not supported for dashboard name." -ForegroundColor Yellow
                return
            }
            $Id = (Get-LMDashboard -Name $Name | Select-Object -First 1 ).Id
            If(!$Id){
                Write-Host "Unable to find dashboard: $Name, please check spelling and try again." -ForegroundColor Yellow
                return
            }
        }

        #Build header and uri
        $ResourcePath = "/dashboard/dashboards/$Id"

        #Loop through requests 
        Try{
            $Headers = New-LMHeader -Auth $global:LMAuth -Method "DELETE" -ResourcePath $ResourcePath
            $Uri = "https://$($global:LMAuth.Portal).logicmonitor.com/santaba/rest" + $ResourcePath

            #Issue request
            $Response = Invoke-RestMethod -Uri $Uri -Method "DELETE" -Headers $Headers
            Write-Host "Successfully removed id ($Id)" -ForegroundColor Green
        }
        Catch [Exception] {
            $Exception = $PSItem
            Switch ($PSItem.Exception.GetType().FullName) {
                { "System.Net.WebException" -or "Microsoft.PowerShell.Commands.HttpResponseException" } {
                    $HttpException = ($Exception.ErrorDetails.Message | ConvertFrom-Json).errorMessage
                    $HttpStatusCode = $Exception.Exception.Response.StatusCode.value__
                    Write-Error "Failed to execute web request($($HttpStatusCode)): $HttpException"
                }
                default {
                    $LMError = $Exception.ToString()
                    Write-Error "Failed to execute web request: $LMError"
                }
            }
            Return
        }
    }
    Else{
        Write-Host "Please ensure you are logged in before running any comands, use Connect-LMAccount to login and try again." -ForegroundColor Yellow
    }
}