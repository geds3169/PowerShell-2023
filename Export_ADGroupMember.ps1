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
Nom de l'outil: Export_ADGroupMember

===========================================================================
.DESCRIPTION
Usage: Exporter les membres d'un groupe défini depuis un contrôleur de domaine
Prérequis: Ne nécessite pas de module

.EXPLICATION
Explication: Les membres peuvent également être d’autres groupes ou objets ordinateur, pas seulement des utilisateurs
#>

# Variables
$CsvFile = "" # Chemin d'export du CSV contenant les membres du groupe
$GroupName = "" # Renseigner le nom du groupe à rechercher

# Vérification préalable de l'existence du groupe
$GroupExists = Get-ADGroup -Filter "name -like '$GroupName'" | Sort-Object name

# Si le groupe existe, exporte les membres du groupe qu'ils soient utilisateurs, groupes imbriqués, ordinateurs
if ($GroupExists) {
    Get-ADGroupMember -Identity $GroupName -Recursive |
        Where-Object { $_.objectClass -eq 'user' -or $_.objectClass -eq 'group' -or $_.objectclass -eq 'computer' } |
        Get-ADUser |
        Select-Object SamAccountName, GivenName |
        Export-Csv -Path $CsvFile -NoTypeInformation -Delimiter ";" -Encoding UTF8
}
else {
  Write-Hoste "Le groupe $GroupName n'existe pas" -foregroundcolor Yellow
}
