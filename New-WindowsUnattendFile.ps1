[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$AdministratorPassword,

    [Parameter(Mandatory=$true)]
    [ValidateSet('Server2016Datacenter','Server2016Standard','Windows10Enterprise','Windows10Professional')]
    [string]$Version,

    [string]$ComputerName,

    [string]$FilePath,

    [string]$Locale
)

$ErrorActionPreference = 'Stop'

$template = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <ProductKey></ProductKey>
            <ComputerName></ComputerName>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>en-US</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UserLocale>en-US</UserLocale>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
            </OOBE>
            <UserAccounts>
                <AdministratorPassword>
                    <Value></Value>
                    <PlainText>false</PlainText>
                </AdministratorPassword>
            </UserAccounts>
        </component>
    </settings>
</unattend>
'@

$xml = [xml]$template

if (-not $FilePath) {
    $FilePath = Join-Path $env:TEMP 'unattend.xml'
}

if ($ComputerName) {
    $xml.unattend.settings[0].component.ComputerName = $ComputerName
}

if ($Locale) {
    $xml.unattend.settings[1].component[0].InputLocale = $Locale
    $xml.unattend.settings[1].component[0].SystemLocale = $Locale
    $xml.unattend.settings[1].component[0].UserLocale = $Locale
}

# Source: https://technet.microsoft.com/en-us/library/jj612867(v=ws.11).aspx
$key = switch ($Version){ 
    'Server2016Datacenter'  {'CB7KF-BWN84-R7R2Y-793K2-8XDDG'}
    'Server2016Standard'    {'WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY'}
    'Windows10Enterprise'   {'NPPR9-FWDCX-D2C8J-H872K-2YT43'}
    'Windows10Professional' {'W269N-WFGWX-YVC9B-4J6C9-T83GX'}
}
$xml.unattend.settings[0].component.ProductKey = $key

$encodedPassword = [System.Text.Encoding]::Unicode.GetBytes($AdministratorPassword + 'AdministratorPassword')
$xml.unattend.settings[1].component[1].UserAccounts.AdministratorPassword.Value = [Convert]::ToBase64String($encodedPassword)

$writer = New-Object System.XMl.XmlTextWriter($FilePath, [System.Text.Encoding]::UTF8)
$writer.Formatting = [System.Xml.Formatting]::Indented
$xml.Save($writer)
$writer.Dispose()

$FilePath