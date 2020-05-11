$FLOC = "$($env:USERPROFILE)\\Desktop\\"

# Connect to Exchange Online
Connect-ExchangeOnline

# Get list of all accounts with holds applied (LitigationHoldStatus is TRUE)
Write-Host "Retrieving mailboxes"
$true_holds = @()
$all_mbx = get-mailbox -resultsize unlimited | select Name,InPlaceHolds,LitigationHoldEnabled | foreach-object -process {if($_.LitigationHoldEnabled -eq "TRUE"){$true_holds += $_}}

# Export list of holds to CSV
Write-Host "Exporting CSV file: custodian_hold_list.csv"
$true_holds | export-csv "$($FLOC)custodian_hold_list.csv" -NoTypeInformation 

# Retrieve each unique lit hold GUID
Write-Host "Getting unique hold GUIDs"
$holds = @()
foreach ($custodian in $true_holds){
        foreach ($hold in $custodian.InPlaceHolds){
                $holds += $hold
        }
}

$holds = $holds | select -unique

# Divide each hold into an eDiscovery or In-Place hold
Write-Host "Dividing GUIDs into eDiscovery or In-Place"
$edisc_holds = @()
$inplace_holds = @()

foreach ($hold in $holds){
        if ($hold.contains("UniH")){
                $edisc_holds += $hold
        }
        elseif($hold.contains("cld")){
                $inplace_holds += $hold
        }
        elseif(($hold.contains("mbx")) -or ($hold.contains("skp"))){
                continue
        }
        else{
                $inplace_holds = $hold
        }
}

# Get eDiscovery hold names and custodians
Connect-Ediscovery

Write-Host "Getting case hold info"
$edisc_cases = @()
foreach ($guid in $edisc_holds){
        $guid = $guid.substring(4) # <-- removes the 'UniH' prefix from the GUID which is not necessary to search with
        $caseinfo = Get-CaseHoldPolicy $guid | select CaseId,Name,ExchangeLocation
        $edisc_cases += $caseinfo
}


# Get In-Place hold names and custodians
# TODO: Retrieve hold names and custodians, not number of holds

<#Write-Host "Getting In-Place hold info"
$inplace_hold_info = @()
foreach ($guid in $inplace_holds){
        $info = get-mailboxsearch -inplaceholdidentity $guid | select Name,SourceMailboxes
        $inplace_hold_info += $info
}#>

# Write hold info to CSV
Write-Host "Writing to CSV files"
$edisc_cases | export-csv "$($FLOC)ediscovery_hold_list.csv"
$inplace_holds | export-csv "$($FLOC)inplace_hold_list.csv"
Write-Host "Fin."
