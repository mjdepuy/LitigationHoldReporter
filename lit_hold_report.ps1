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
# SIG # Begin signature block
# MIIadAYJKoZIhvcNAQcCoIIaZTCCGmECAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUjs3fs2owZ6kiSvs4vrs7lFV2
# ZH+gghW6MIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggSjMIIDi6ADAgECAhAOz/Q4yP6/NW4E2GqYGxpQMA0GCSqGSIb3
# DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1OVowYjELMAkGA1UE
# BhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTQwMgYDVQQDEytT
# eW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25lciAtIEc0MIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAomMLOUS4uyOnREm7Dv+h8GEKU5Ow
# mNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBDSyKV7sIrQ8Gf2Gi0
# jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh3WPVF4kyW7BemVqonShQDhfu
# ltthO0VRHc8SVguSR/yrrvZmPUescHLnkudfzRC5xINklBm9JYDh6NIipdC6Anqh
# d5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsyi1aLM73ZY8hJnTrFxeoz
# C9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdwxb5OgyYI+wu9qU+ZCOEQKHKqzQIDAQAB
# o4IBVzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
# BgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUHAQEEZzBlMCoGCCsGAQUFBzABhh5odHRw
# Oi8vdHMtb2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUHMAKGK2h0dHA6Ly90
# cy1haWEud3Muc3ltYW50ZWMuY29tL3Rzcy1jYS1nMi5jZXIwPAYDVR0fBDUwMzAx
# oC+gLYYraHR0cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20vdHNzLWNhLWcyLmNy
# bDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMjAdBgNV
# HQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgwFoAUX5r1blzMzHSa
# 1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEBAHg7tJEqAEzwj2IwN3ijhCcH
# bxiy3iXcoNSUA6qGTiWfmkADHN3O43nLIWgG2rYytG2/9CwmYzPkSWRtDebDZw73
# BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1zSgEIKOq8UvEiCmRDoDR
# EfzdXHZuT14ORUZBbg2w6jiasTraCXEQ/Bx5tIB7rGn0/Zy2DBYr8X9bCT2bW+IW
# yhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4axgohd8D20UaF5Mysu
# e7ncIAkTcetqGVvP6KUwVyyJST+5z3/Jvz4iaGNTmr1pdKzFHTx/kuDDvBzYBHUw
# ggZDMIIFK6ADAgECAhNtAAAAA/tXuU0daU7/AAAAAAADMA0GCSqGSIb3DQEBCwUA
# MCYxJDAiBgNVBAMTG1ByZWNpc2lvbiBDYXN0cGFydHMgUm9vdCBDQTAeFw0xNzEw
# MDQyMjUwNDBaFw0yNzEwMDQyMzAwNDBaMF0xEzARBgoJkiaJk/IsZAEZFgNjb20x
# GzAZBgoJkiaJk/IsZAEZFgtwcmVjYXN0Y29ycDEpMCcGA1UEAxMgUHJlY2lzaW9u
# IENhc3RwYXJ0cyBJbnRlcm5hbCBDQTEwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw
# ggEKAoIBAQDbGEo1RaJHA4ff612c7kB8YwK+W+1FKYzqyEz48qbPt0sRtESXp+HH
# 614HUQqxdr/o5YoJnST+yzsC6pHO36QijMVxf0AwmIzyEPCilzbaA8N5oStqH5ZK
# x6pnUeRy2fmRPXa6D24nuErMxQdM5i4ciWoaLQnDPUpv2IvwRZaYAW2QAcRQOqq1
# FDyEN1YgByLUI67QcLGdhz7hm6SEr8iPO49BUtQwIsbE8nV0xO8MkVJSxjKYcdqg
# /bY74VcR3TtxSAgpAnyh50UtUZ3DVCkAjUBAoKB1wkDWLbjlIeVBKwSSIb1YahXM
# oKCKzEkRAX0goGex/SGRnqEUb6+Y5c/DAgMBAAGjggMxMIIDLTAQBgkrBgEEAYI3
# FQEEAwIBADAdBgNVHQ4EFgQUJ8R3wdeR77NBoUUPQVuCAtYh+0MwGQYJKwYBBAGC
# NxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8w
# HwYDVR0jBBgwFoAUMWQ764KwTGwvTW5b+gi2bnfBehIwggFJBgNVHR8EggFAMIIB
# PDCCATigggE0oIIBMIaBwWxkYXA6Ly8vQ049UHJlY2lzaW9uJTIwQ2FzdHBhcnRz
# JTIwUm9vdCUyMENBLENOPUNEUCxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxD
# Tj1TZXJ2aWNlcyxDTj1jb25maWd1cmF0aW9uLERDPXByZWNhc3Rjb3JwLERDPWNv
# bT9jZXJ0aWZpY2F0ZVJldm9jYXRpb25MaXN0P2Jhc2U/b2JqZWN0Q2xhc3M9Y1JM
# RGlzdHJpYnV0aW9uUG9pbnSGamh0dHA6Ly9jcmwucHJlY2FzdC5jb20uczMtd2Vi
# c2l0ZS11cy13ZXN0LTEuYW1hem9uYXdzLmNvbS9DZXJ0RW5yb2xsL1ByZWNpc2lv
# biUyMENhc3RwYXJ0cyUyMFJvb3QlMjBDQS5jcmwwggFRBggrBgEFBQcBAQSCAUMw
# ggE/MIHEBggrBgEFBQcwAoaBt2xkYXA6Ly8vQ049UHJlY2lzaW9uJTIwQ2FzdHBh
# cnRzJTIwUm9vdCUyMENBLENOPUFJQSxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNl
# cyxDTj1TZXJ2aWNlcyxDTj1jb25maWd1cmF0aW9uLERDPXByZWNhc3Rjb3JwLERD
# PWNvbT9jQUNlcnRpZmljYXRlP2Jhc2U/b2JqZWN0Q2xhc3M9Y2VydGlmaWNhdGlv
# bkF1dGhvcml0eTB2BggrBgEFBQcwAoZqaHR0cDovL2NybC5wcmVjYXN0LmNvbS5z
# My13ZWJzaXRlLXVzLXdlc3QtMS5hbWF6b25hd3MuY29tL0NlcnRFbnJvbGwvUHJl
# Y2lzaW9uJTIwQ2FzdHBhcnRzJTIwUm9vdCUyMENBLmNydDANBgkqhkiG9w0BAQsF
# AAOCAQEAW7lf2ybqVDU+Ws2l+88lzho/0qEyMjfycOhRfLIilAIQo0cFYVMKsHM3
# S6PlU/4DZZu62QN+WD0TS1i5/truxKN+iSoNtQVMwIW8M6Bp3A7g7IL+xwjqDuan
# PTCpWeJVS/ajfNGsO1lv0bUOC0Xy0FHmDnuSYOzpmOzJ6C8/RvFog25Bvt5jfeu/
# 6Z7CQerpk4mjs46c4Kt65uaw9RGB2M6ONtD4cUWQmOziZtLtSmLniTONLQt1dAD1
# X2EOHVPvFfqEvAdw4Prp1x2dsIFVWiLY2MOPasASfm3WNYC/E251zwXgyXGsfQUP
# 7pLqSrD4FTYNNM+6CpaO7dlP9cFZUTCCBtYwggW+oAMCAQICE38AOG84CaTdsb2t
# D+cAAAA4bzgwDQYJKoZIhvcNAQELBQAwXTETMBEGCgmSJomT8ixkARkWA2NvbTEb
# MBkGCgmSJomT8ixkARkWC3ByZWNhc3Rjb3JwMSkwJwYDVQQDEyBQcmVjaXNpb24g
# Q2FzdHBhcnRzIEludGVybmFsIENBMTAeFw0xOTA3MTAyMDQ1MjJaFw0yMjA3MTAy
# MDU1MjJaMEAxFzAVBgNVBAMTDkRlcHV5LCBNaWNoYWVsMSUwIwYJKoZIhvcNAQkB
# FhZtZGVwdXlAcHJlY2FzdGNvcnAuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
# MIIBCgKCAQEAyL4LrG+2tvofqIuX8WnjtKTJqz0hzPjORb9AuI2C1YC6PUuYBh7k
# VEQ93tlE4NxwJMfHcUGMJ7s5vaBLwxWb5MPmpEM3S9qg3t4fL5eq1zVZV3kvQofD
# eoRy31bRJb9LnUd4l/6YYOWQ4KdeLASMKoD/iqIs3LvQAPveU3SzJvlzG/TdPJ7o
# eSA1+nxodeOE660rtNeIVCSqJLVGmYz3Icgo2Fnz+Io43IJsGyuImkJChf2PiNet
# aiBxv4Nyxb5GOiygq0GAb+7CZYSQMe+n0LcAMRoY+xj9o2+LltARdcc7EVJYwEWk
# XSQC54sS7BF4D7ECZ00YHPIz889i0911zwIDAQABo4IDqjCCA6YwPAYJKwYBBAGC
# NxUHBC8wLQYlKwYBBAGCNxUIh6LlPK/gW4e1nTLhjy+Dr4JugQuGkbghhpvQdgIB
# ZAIBKDATBgNVHSUEDDAKBggrBgEFBQcDAzALBgNVHQ8EBAMCB4AwGwYJKwYBBAGC
# NxUKBA4wDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQU3+PJZVwp8j5kZ1TQmXNTzaw/
# AEYwHwYDVR0jBBgwFoAUJ8R3wdeR77NBoUUPQVuCAtYh+0MwggFTBgNVHR8EggFK
# MIIBRjCCAUKgggE+oIIBOoaBxmxkYXA6Ly8vQ049UHJlY2lzaW9uJTIwQ2FzdHBh
# cnRzJTIwSW50ZXJuYWwlMjBDQTEsQ049Q0RQLENOPVB1YmxpYyUyMEtleSUyMFNl
# cnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZpZ3VyYXRpb24sREM9cHJlY2FzdGNv
# cnAsREM9Y29tP2NlcnRpZmljYXRlUmV2b2NhdGlvbkxpc3Q/YmFzZT9vYmplY3RD
# bGFzcz1jUkxEaXN0cmlidXRpb25Qb2ludIZvaHR0cDovL2NybC5wcmVjYXN0LmNv
# bS5zMy13ZWJzaXRlLXVzLXdlc3QtMS5hbWF6b25hd3MuY29tL0NlcnRFbnJvbGwv
# UHJlY2lzaW9uJTIwQ2FzdHBhcnRzJTIwSW50ZXJuYWwlMjBDQTEuY3JsMIIBWwYI
# KwYBBQUHAQEEggFNMIIBSTCByQYIKwYBBQUHMAKGgbxsZGFwOi8vL0NOPVByZWNp
# c2lvbiUyMENhc3RwYXJ0cyUyMEludGVybmFsJTIwQ0ExLENOPUFJQSxDTj1QdWJs
# aWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9u
# LERDPXByZWNhc3Rjb3JwLERDPWNvbT9jQUNlcnRpZmljYXRlP2Jhc2U/b2JqZWN0
# Q2xhc3M9Y2VydGlmaWNhdGlvbkF1dGhvcml0eTB7BggrBgEFBQcwAoZvaHR0cDov
# L2NybC5wcmVjYXN0LmNvbS5zMy13ZWJzaXRlLXVzLXdlc3QtMS5hbWF6b25hd3Mu
# Y29tL0NlcnRFbnJvbGwvUHJlY2lzaW9uJTIwQ2FzdHBhcnRzJTIwSW50ZXJuYWwl
# MjBDQTEuY3J0MDEGA1UdEQQqMCigJgYKKwYBBAGCNxQCA6AYDBZtZGVwdXlAcHJl
# Y2FzdGNvcnAuY29tMA0GCSqGSIb3DQEBCwUAA4IBAQByiHvEVOuAWoCReMGpwo5J
# kr5vgbyYiwTGKERPsc7+aKE3D00g5Gzg3mWH5kglTEZtiXvsNfy1gr9RrWk6vyzO
# if12zTpnA2jlUOVeS6lAHxJe+yo+HWV9iGweztniz8CSLX7Gnbs+fNvlc+NnJm0q
# LMAq2A9yMbXUhmiBA+agW4urO2N7RAP3eYoYyKwQofF4K53Oz2dD7e2TocW/OG+K
# 1zN8DQ41eSb1U3VZtNwMbGaid+74QOvIEgtupASR+ZFW5PV1pLPvP5aLvl9FZ3fX
# uuWiJbZUhtH7/jWjRdyOJp53jMbQFnwwENSVnPpURXrwLhOaQd/sTGFRznYJ/aBg
# MYIEJDCCBCACAQEwdDBdMRMwEQYKCZImiZPyLGQBGRYDY29tMRswGQYKCZImiZPy
# LGQBGRYLcHJlY2FzdGNvcnAxKTAnBgNVBAMTIFByZWNpc2lvbiBDYXN0cGFydHMg
# SW50ZXJuYWwgQ0ExAhN/ADhvOAmk3bG9rQ/nAAAAOG84MAkGBSsOAwIaBQCgeDAY
# BgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3
# AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEW
# BBRdBrh9bNgrZPG4eX4cSOiB6ZUH/zANBgkqhkiG9w0BAQEFAASCAQBn0RGBh3dR
# o2UpQGDGid4Nsj2GYy5BPPC29C1UiCDvmvRkdGm337km2mKnDtoZ3ITUHNXkafvE
# n4BCa9p2/ljAtyavr3NlJFHeY0So53FpDqZYJQTKjAcBG1ANTN48slFws/3f8wwW
# pqQPN2t2q/ED1AGQs7d8iGK5quyIaZKZ2fn9pmEVrTxM126bkXiF5ZP9OrQlshNF
# JysZU9uL1Lkjo2WYvmIEMYzelWe4g8ybwregwjbLnp9kCDoOZMkpuy4kggkvJyG7
# r3ZhJLOfEeAdDK2ulL3i3rDes5lJHRn6DcIj4VmI+H7bQW9bt6M8nNh4ycfsJVC1
# vQW7ZSTYZZVVoYICCzCCAgcGCSqGSIb3DQEJBjGCAfgwggH0AgEBMHIwXjELMAkG
# A1UEBhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTAwLgYDVQQD
# EydTeW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIENBIC0gRzICEA7P9DjI
# /r81bgTYapgbGlAwCQYFKw4DAhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0B
# BwEwHAYJKoZIhvcNAQkFMQ8XDTIwMDUwNjE3MzcxNVowIwYJKoZIhvcNAQkEMRYE
# FMq+zdEOt/XsfBTE9ITrfXQot/0ZMA0GCSqGSIb3DQEBAQUABIIBAAznF7vMAESj
# MjO2W+CeORPWVeJ+QzcKR3uDZfNIG7GgchRW29j6ANl0jhWTEJIESPwtatslimgK
# 5vig1J40aU9vbVXbDEyPGH7IgQ3+A9hUxHrEU9cVrABHOLJX7emapcakfY4JvAHj
# Vn3jkyV2T5MboflXjGBkfnrP3N0mWA7tgPVFBdC3geLAuciE/0X/ry7Cb0Q+mpne
# 12tpW2sai8ey4/R9F1QMxHxBpDVFNIS73TLZo/AQzuo8/OFGUJtwECp/Kqg7Kuuc
# UI2/VKISIfj9Da5V7Xbx8ZUVXbuc+dkRUFVkQ57xd7XYoSCtrZEoYZ4QdVAb4p6H
# jnyecWc+OPQ=
# SIG # End signature block
