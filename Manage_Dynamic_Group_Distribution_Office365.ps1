<#
===========================================================================
Version      : 1
Date         : 23/06/2023
Organization : Guilhem SCHLOSSER
Auteur       : Guilhem SCHLOSSER
Nom de l'outil: Manage_Dynamic_Group_Distribution_Office365
===========================================================================
.DESCRIPTION
Usage: Gestion des groupes de distribution par PowerShell sous Office 365
       Intéractif
       gère l'authentification MFA
Prérequis: Nécessite l'installation de modules
           Un compte remote PowerShell (administrateur) sur le tenant:
           Set-User -Identity david@contoso.onmicrosoft.com -RemotePowerShellEnabled $true

.EXPLICATION

Les groupes dynamiques, sont actualisés automatiquement en fonction de critères tels que l'âge ou la civilité.
Tous utilisateurs répondant au critère d'un groupe dynamique sera automatiquement ajouté au groupe.

.NOTE
L'authentification MFA nécessite possiblement une mise à jour du module ExchangeOnline afin de bénéficier des dernières fonctionnalités
#>

# ===========================================================================

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

# Affiche les membres du groupe de distribution dynamique
function MembersOfDynamciGroupDistribution {
    $groupMembers = Get-Recipient -RecipientPreviewFilter $groupName
    Write-Host "Voici les membres du groupe de distribution dynamique :"
    foreach ($member in $groupMembers) {
        Write-Host "- $($member.DisplayName) ($($member.PrimarySmtpAddress))"
    }
}

# ===========================================================================

# Script
# Appel des différentes fonctions et installation préalable des modules requis
InstallModule
ExchangeConnect

# Demander les informations du groupe de distribution dynamique à créer
$groupName = Read-Host "Entrez le nom du groupe de distribution dynamique"
$emailAddress = Read-Host "Entrez l'adresse de courriel du groupe"

# Demander les informations de filtrage du groupe de distribution dynamique
$displayName = Read-Host "Entrez le nom d'affichage du groupe"
$alias = Read-Host "Entrez l'alias du groupe"
$filterRecipient = Read-Host "Entrez le filtre destinataire du groupe"

# Afficher les informations saisies par l'utilisateur et demander confirmation
Write-Host ""
Write-Host "Vérifiez les informations saisies :"
Write-Host "Nom du groupe : $groupName"
Write-Host "Adresse de courriel : $emailAddress"
Write-Host "Nom d'affichage : $displayName"
Write-Host "Alias : $alias"
Write-Host "Filtre destinataire : $filterRecipient"
Write-Host ""

$confirm = Read-Host "Les informations sont-elles correctes ? (Oui/Non)"
if ($confirm.ToLower() -ne "oui") {
    # Proposer de modifier les informations
    Write-Host "Veuillez saisir à nouveau les informations :"
    $groupName = Read-Host "Entrez le nom du groupe de distribution dynamique"
    $emailAddress = Read-Host "Entrez l'adresse de courriel du groupe"
    $displayName = Read-Host "Entrez le nom d'affichage du groupe"
    $alias = Read-Host "Entrez l'alias du groupe"
    $filterRecipient = Read-Host 'Entrez le filtre destinataire du groupe (exemple: "((RecipientType -eq 'UserMailbox') -and (Company -eq 'Contoso') -and (Office -eq 'North Building'))")'
}

# Vérifier si le groupe de distribution dynamique existe déjà
$existingGroup = Get-DynamicDistributionGroup -Filter {Name -eq $groupName} -ErrorAction SilentlyContinue
if ($existingGroup -ne $null) {
    Write-Host "Un groupe de distribution dynamique avec le même nom existe déjà. Veuillez choisir un autre nom."
    exit
}

# Demander confirmation avant de créer le groupe de distribution dynamique
$confirmCreate = Read-Host "Êtes-vous sûr de vouloir créer le groupe de distribution dynamique ? (Oui/Non)"
if ($confirmCreate.ToLower() -ne "oui") {
    Write-Host "Création du groupe de distribution dynamique annulée."
    exit
}

# Créer le groupe de distribution dynamique
New-DynamicDistributionGroup -Name $groupName -Alias $alias -DisplayName $displayName -RecipientFilter $filterRecipient -PrimarySmtpAddress $emailAddress

# Afficher le groupe de distribution dynamique et ses membres
$createdGroup = Get-DynamicDistributionGroup -Identity $groupName
Write-Host ""
Write-Host "Le groupe de distribution dynamique a été créé avec succès :"
Write-Host "Nom du groupe : $($createdGroup.Name)"
Write-Host "Alias : $($createdGroup.Alias)"
Write-Host "Adresse de courriel : $($createdGroup.PrimarySmtpAddress)"
Write-Host "Filtre destinataire : $($createdGroup.RecipientFilter)"
# Affiche les propriétés du nouveau groupe de distribution dynamique
$Info = Get-DynamicDistributionGroup -Identity "Contoso Finance" | Format-List Recipient*,Included*
Write-Host "Voici les propriétés du groupe créé`n$info"
MembersOfDynamciGroupDistribution | Format-Table -AutoSize
