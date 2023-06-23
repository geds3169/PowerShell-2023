# Spécifie l'encodage
# -*- coding: utf-8 -*-
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

<#
.NOTES
===========================================================================
Version      : 1
Date: 23/06/2023
Organization : Guilhem SCHLOSSER
Auteur: Guilhem SCHLOSSER
Nom de l'outil: List_All_AD_GPO

===========================================================================
.DESCRIPTION
Usage: Exporter l'ensemble des informations relatives aux GPO du domaine
Prérequis: Modification des variables ligne: 24 / 25 / 26
Exporte les information au format HTML et affiche la page Web

.EXPLICATION

#>

# Variables pouvant être modifiées
$Domain = 'sales.contoso.com'
$Server = 'DC1'
$ExportPath = 'C:\Temp\GPOReportsAll.html'

# Obtient tous les rapports HTML pour les GPO du domaine spécifié
$AllGPOs = Get-GPO -All -Domain $Domain -Server $Server
$GPOReports = foreach ($GPO in $AllGPOs) {
    Get-GPOReport -Name $GPO.DisplayName -ReportType HTML
}

# Fusionne tous les rapports HTML en un seul
$CombinedReport = $GPOReports | ForEach-Object { $_.Content }

# Exporte le rapport combiné au format HTML
$CombinedReport | Out-File -FilePath $ExportPath

# Tri des résultats par utilisateur et ordinateur
$InfoGPOs = $GPOReports | ForEach-Object {
    $GPO = $_
    [PSCustomObject]@{
        "Name"            = $GPO.GPOName
        "User"            = $GPO.GPO.User
        "Computer"        = $GPO.GPO.Computer
        "Computer-Status" = $GPO.GPO.Computer.Enabled
        "User-Status"     = $GPO.GPO.User.Enabled
    }
} | Sort-Object User, Computer

# Affichage des résultats triés
$InfoGPOs | Format-Table -AutoSize -Wrap

# Affiche la page HTML dans le navigateur
Invoke-Item $ExportPath
