# MrNetTek
# eddiejackson.net
# 7/14/2022
# free for public use
# free to claim as your own
 
#SET AUTOSCALE
function Set-Scaling {    
    # $scaling = 0 : 100% (default)
    # $scaling = 1 : 125% 
    # $scaling = 2 : 150% 
    # $scaling = 3 : 175% 
    param($scaling)
$source = @'
    [DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]
    public static extern bool SystemParametersInfo(
                      uint uiAction,
                      uint uiParam,
                      uint pvParam,
                      uint fWinIni);
'@
    $apicall = Add-Type -MemberDefinition $source -Name WinAPICall -Namespace SystemParamInfo -PassThru
    $apicall::SystemParametersInfo(0x009F, $scaling, $null, 1) | Out-Null
}
Set-Scaling -scaling 1