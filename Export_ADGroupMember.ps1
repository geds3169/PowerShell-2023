# Spécifie l'encodage
# -*- coding: utf-8 -*-
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

<#
Date: 23/08/2023

Auteur: Guilhem SCHLOSSER

Usage: Exporter les membres d'un groupe défini

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
