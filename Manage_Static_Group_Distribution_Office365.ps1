# Spécifie l'encodage
# -*- coding: utf-8 -*-
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

<#
.NOTES
===========================================================================
Version      : 2
Date         : 23/06/2023
Organization : Guilhem SCHLOSSER
Auteur       : Guilhem SCHLOSSER
Nom de l'outil: Manage_Static_Group_Distribution_Office365
===========================================================================
.DESCRIPTION
Usage: Gestion des groupes de distribution par PowerShell sous Office 365
       Intéractif
       gère l'authentification MFA
Prérequis: Nécessite l'installation de modules
           Un compte remote PowerShell (administrateur) sur le tenant:
           Set-User -Identity david@contoso.onmicrosoft.com -RemotePowerShellEnabled $true

.EXPLICATION
Les groupes de distribution contiennent un ensemble défini de membres contrairement à des groupes de distribution dynamiques.
Les groupes statiques permettent de sauvegarder un certain nombre de destinataires qui ne changeront pas.
Les groupes dynamiques, au contraire, sont actualisés automatiquement en fonction de critères tels que l'âge ou la civilité.
Tous utilisateurs répondant au critère d'un groupe dynamique sera automatiquement ajouté au groupe.

.NOTE
L'authentification MFA nécessite possiblement une mise à jour du module ExchangeOnline afin de bénéficier des dernières fonctionnalités
#>

# ===========================================================================
# Fonctions

# Installation de module
function InstallModule {
    # Vérifie si le module requis Exchange est déjà installé, sinon on l'installe
    $requiredModule = "ExchangeOnlineManagement"  # Remplacez "NomDuModule" par le nom réel du module requis
    if (-not (Get-Module -Name $requiredModule -ListAvailable)) {
        Write-Host "Le module $requiredModule n'est pas installé. Tentative d'installation..." -ForegroundColor Cyan
        try {
            Install-Module -Name $requiredModule -Force -Scope CurrentUser
            Write-Host "Le module $requiredModule a été installé avec succès." -ForegroundColor Green
        }
        catch {
            Write-Host "Impossible d'installer le module $requiredModule. Veuillez l'installer manuellement." -ForegroundColor Red
            exit
        }
    }
    else {
        Import-Module -Name $requiredModule
    }
}

# Authentification de l'utilisateur
function ExchangeConnect {
    # Demander les informations d'identification à l'utilisateur
    $credential = Get-Credential

    # Tenter une connexion avec l'authentification simple
    try {
        Connect-ExchangeOnline -Credential $credential -ErrorAction Stop
        Write-Host "Connexion réussie avec l'authentification simple"
    }
    catch {
        Write-Host "Impossible de se connecter avec l'authentification simple. Tentative d'authentification MFA déléguée..."
    
        # Tente une connexion avec l'authentification MFA déléguée
        try {
            Connect-ExchangeOnline -UserPrincipalName $credential.UserName -DelegatedOrganization $OrganizationName -ErrorAction Stop
            Write-Host "Connexion réussie avec l'authentification MFA déléguée"
        }
        catch {
            Write-Host "Impossible de se connecter avec l'authentification MFA déléguée. Vérifiez vos informations d'identification et réessayez."
        }
    }
}


function createGroupDistribution {

    # Demande des informations relatives à la création du groupe à l'utilisateur
    $Name = Read-Host "Veuillez renseigner le nom du nouveau groupe de distribution"
    $DisplayName = Read-Host "Veuillez renseigner le nom qui sera affiché"
    $PrimarySmtpAddress = Read-Host "Veuillez renseigner l'adresse de courriel de ce groupe"

    # Variable ne devant pas être modifiée
    $done = $false

    while (-not $done) {

        # Affiche les informations entrées par l'utilisateur pour validation
        Write-Host "Voici les informations saisies" -ForegroundColor Cyan
        Write-Host "Nom du groupe de distribution : $Name" -ForegroundColor Yellow
        Write-Host "Nom qui sera affiché : $DisplayName" -ForegroundColor Yellow
        Write-Host "Adresse de courriel du groupe : $PrimarySmtpAddress" -ForegroundColor Yellow

        # Demande à l'utilisateur de confirmer les informations
        $confirmation = Read-Host "Confirmez-vous les informations ? ( Entrez [O]/[N])" -ForegroundColor Cyan

        if ($confirmation -eq "Oui" -or $confirmation -eq "O") {
            # Vérifie l'existence préalable d'un groupe nommé $Name
            $existingGroup = Get-DistributionGroup -Identity $Name -ErrorAction 'SilentlyContinue'

            if (-not $existingGroup) {
                # Création du groupe de distribution
                $done = $true
                New-DistributionGroup -DisplayName $DisplayName -Name $Name -PrimarySmtpAddress $PrimarySmtpAddress
            } else {
                Write-Host "Le groupe existe déjà." -ForegroundColor Red
            }
        } elseif ($confirmation -eq "Non" -or $confirmation -eq "N") {
            Write-Host "Opération annulée." -ForegroundColor Red
            $done = $true
        } else {
            Write-Host "Entrée invalide. Veuillez répondre par 'Oui' ou 'Non'." -ForegroundColor Red
        }
    }
    Get-DistributionGroup -Identity $Name | Format-List
}

# ===========================================================================

# Script
# Appel des différentes fonctions et installation préalable des modules requis

InstallModule
$OrganizationName = Read-Host "Veuillez entrer le tenant (exmple: XXXXXXXXXX.onmicrosoft.com) "
ExchangeConnect
createGroupDistribution
Disconnect-ExchangeOnline -Confirm:$false # Ferme la session à ExchangeOnline
