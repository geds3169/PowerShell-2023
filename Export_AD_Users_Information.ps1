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
Nom de l'outil: Export_AD_Users_Information

===========================================================================
.DESCRIPTION
Usage: Exporter l'ensemble des informations de chaque utilisateurs d'un contrôleur de domaine
Prérequis: Ne nécessite pas de module
Fichier CSV d'export à l'attention des services RH qui sera complété et qui sera retourné au service IT

.EXPLICATION
Export au format CSV, afin de pouvoir compléter les information
#>


# Importer le module Active Directory
Import-Module ActiveDirectory

# Variables pouvant être modifiés
$CsvUsersInfo = "C:\Temp\Informations_Utilisateurs.csv"

# Récupérer tous les utilisateurs du domaine
$users = Get-ADUser -Filter * -Properties *

# Récupérer toutes les propriétés disponibles pour les utilisateurs
$userProperties = $users[0].PSObject.Properties.Name

# Créer un tableau pour stocker les informations des utilisateurs
$userInfo = @()

# Parcourir chaque utilisateur et récupérer toutes les propriétés
foreach ($user in $users) {
    $userValues = @{}
    
    foreach ($propertyName in $userProperties) {
        $propertyValue = $user.$propertyName
        $userValues[$propertyName] = $propertyValue
    }
    
    $userInfo += [PSCustomObject]$userValues
}

# Exporter les informations des utilisateurs vers un fichier CSV
$userInfo | Export-Csv -Path $CsvUsersInfo -NoTypeInformation

# Afficher un message de confirmation
Write-Host "Les informations des utilisateurs ont été exportées avec succès vers $CsvUsersInfo."
