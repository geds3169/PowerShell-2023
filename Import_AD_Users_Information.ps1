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
Nom de l'outil: Import_AD_Users_Information

===========================================================================
.DESCRIPTION
Usage: Importe l'ensemble des informations de chaque utilisateurs d'un contrôleur de domaine
Prérequis: Ne nécessite pas de module
Fichier CSV d'export à l'attention des services RH qui sera complété et qui sera retourné au service IT

.EXPLICATION
Export au format CSV, afin de pouvoir compléter les information
#>

# Importer le module Active Directory
Import-Module ActiveDirectory

# Spécifier le chemin vers le fichier CSV contenant les données à importer
$csvPath = "C:\Temp\Informations_Utilisateurs.csv"

# Importer les données à partir du fichier CSV
$userData = Import-Csv -Path $csvPath

# Parcourir chaque ligne du fichier CSV
foreach ($userRow in $userData) {
    # Récupérer l'utilisateur correspondant au nom d'utilisateur
    $user = Get-ADUser -Identity $userRow.NomUtilisateur

    # Mettre à jour les propriétés manquantes pour l'utilisateur
    foreach ($property in $userRow.PSObject.Properties) {
        $propertyName = $property.Name
        $propertyValue = $property.Value

        # Vérifier si la propriété est manquante ou vide pour l'utilisateur
        if ([string]::IsNullOrEmpty($user.$propertyName)) {
            # Mettre à jour la propriété pour l'utilisateur
            Set-ADUser -Identity $user.SamAccountName -Replace @{ $propertyName = $propertyValue }
            Write-Host "La propriété '$propertyName' a été mise à jour pour l'utilisateur '$($user.SamAccountName)'."
        }
    }
}

# Afficher un message de confirmation
Write-Host "Les informations utilisateur ont été importées avec succès depuis le fichier CSV $csvPath."
