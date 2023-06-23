<#
===========================================================================
Version      : 1
Date         : 23/06/2023
Organization : Guilhem SCHLOSSER
Auteur       : Guilhem SCHLOSSER
Nom de l'outil: Manage_Dynamic_Group_Distribution_Office365_From_CSV
===========================================================================
.DESCRIPTION
Usage: Gestion des groupes de distribution par PowerShell sous Office 365
       Import d'un fichier de données
       Gère l'authentification MFA, authentification interactive
Prérequis: Nécessite l'installation de modules
           Un compte remote PowerShell (administrateur) sur le tenant:
           Set-User -Identity david@contoso.onmicrosoft.com -RemotePowerShellEnabled $true

           Entête et contenu du fichier CSV, modèle dans le repository:
                $groupName = Nom du groupe
                $emailAddress = "Adresse de courriel du groupe de diffusion dynamique"
                $displayName = "Nom qui sera affiché pour le groupe de diffusion dynamique"
                $alias = "Permet d'avoir plusieurs adresses E-mail redirigeant vers une seule boite mail, la redirection permet d'avoir une adresse E-mail renvoyant vers une ou/plusieurs boites mail (internes et/ou externes)"
                $filterRecipient = "((((((RecipientType -eq 'UserMailbox'))) -and (-not(UserAccountControl -eq 'AccountDisabled, NormalAccount')))) -and (-not(Name -like 'SystemMailbox{*')) -and (-not(Name -like 'CAS_{*')) -and (-not(RecipientTypeDetailsValue -eq 'MailboxPlan'))) -and (-not(RecipientTypeDetailsValue -eq 'DiscoveryMailbox'))) -and (-not(RecipientTypeDetailsValue -eq 'PublicFolderMailbox'))) -and (-not(RecipientTypeDetailsValue -eq 'ArbitrationMailbox'))) -and (-not(RecipientTypeDetails -eq 'SharedMailbox')) -and (-not(RecipientTypeDetailsValue -eq 'AuditLogMailbox'))) -and (-not(RecipientTypeDetailsValue -eq 'AuxAuditLogMailbox'))) -and (-not(RecipientTypeDetailsValue -eq 'SupervisoryReviewPolicyMailbox'))) -and (StreetAddress -eq 'sterling')"



.EXPLICATION

Les groupes dynamiques sont actualisés automatiquement en fonction de critères tels que l'âge ou la civilité.
Tous les utilisateurs répondant au critère d'un groupe dynamique seront automatiquement ajoutés au groupe.

.NOTE
L'authentification MFA nécessite éventuellement une mise à jour du module ExchangeOnline afin de bénéficier des dernières fonctionnalités
#>

# ===========================================================================
# Variables modifiables

$CSV = Import-Csv "C:\Temp\mydb.csv" -Delimiter ";" -Encoding UTF8


# ===========================================================================

# Installation du module
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
function MembersOfDynamicGroupDistribution {
    param (
        [string]$groupName
    )
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

foreach ($group in $CSV) {

    # Vérifier si le groupe de distribution dynamique existe déjà
    $existingGroup = Get-DynamicDistributionGroup -Filter {Name -eq $group.groupName} -ErrorAction SilentlyContinue
    if ($existingGroup -ne $null) {
        Write-Host "Un groupe de distribution dynamique avec le nom $($group.groupName) existe déjà. Veuillez choisir un autre nom."
        exit
    }

    # Demander confirmation avant de créer le groupe de distribution dynamique
    $confirmCreate = Read-Host "Êtes-vous sûr de vouloir créer le groupe de distribution dynamique $($group.groupName) ? (Oui/Non)"
    if ($confirmCreate.ToLower() -ne "oui") {
        Write-Host "Création du groupe de distribution dynamique $($group.groupName) annulée."
        exit
    }

    # Créer le groupe de distribution dynamique
    New-DynamicDistributionGroup -Name $group.groupName -Alias $group.alias -DisplayName $group.displayName -RecipientFilter $group.filterRecipient -PrimarySmtpAddress $group.emailAddress

    # Afficher les membres du groupe de distribution dynamique
    MembersOfDynamicGroupDistribution -groupName $group.groupName | Format-Table -AutoSize
    Get-DynamicDistributionGroup -Identity $group.groupName | Format-List Recipient*,Included* | Sort-Object Name

}
