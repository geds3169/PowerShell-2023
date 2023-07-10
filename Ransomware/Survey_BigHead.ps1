<#
Auteur: Guilhem SCHLOSSER
Date: 10/07/2023
Nom du script: Survey_BigHead.ps1
Source: https://www.it-connect.fr/le-ransomware-big-head-se-fait-passer-pour-une-mise-a-jour-windows/
Test: non testé en production ou condition réelle

Description:
Ce script surveille les dossiers %AppData%\Local et %AppData%\Roaming\Microsoft\Windows\Start Menu\Programs\Startup pour détecter les exécutables associés au ransomware Big Head. Une fois détectés, les exécutables sont supprimés du système.

Utilisation:
- Créer une GPO afin de déployer le script ou le placer dans un emplacement partagé.
- Configurer une GPO pour exécuter le script en tant que tâche planifiée.
    Onglet Général:
        - Renseigner un nom explicite et une description.
        - Sélectionner le compte administrateur ou système pour l'exécution de la tâche.
        - Sélectionner "Exécuter même si l'utilisateur n'est pas connecté".
        - Cocher "Exécuter avec les modifications maximales, configurer pour Windows (version appropriée)".
    Onglet Déclencheur:
        - Basique / Log Application, modifier l'Event ID si souhaité.
        - Cocher uniquement "Activée".
    Onglet Action:
        - Action = "Démarrer un programme".
        - Renseigner le chemin d'exécutable PowerShell = -File C:\Script\BigHead.ps1 ou \\Server_Name\Shared_Folder\BigHead.ps1.
    Onglet Conditions par défaut.
    Onglet Settings:
        - Cocher "Permettre l'exécution d'une tâche à la demande / arrêter la tâche si elle dure plus longtemps que X / Si la tâche d'exécution ne s'arrête pas à la demande, la forcer à s'arrêter".

Note: Ce script utilise les commandes Unblock-File et Remove-Item pour supprimer les exécutables détectés. Assurez-vous de comprendre les implications de ces commandes et de les utiliser avec précaution.

#>

# Chemins des dossiers à surveiller
$folderLocal = $env:LOCALAPPDATA
$folderStartup = [Environment]::GetFolderPath([Environment+SpecialFolder]::Startup)

# Filtre des exécutables associés au ransomware Big Head
$Filter = "1.exe","discord.exe","archive.exe","Xarch.exe"

# Action à effectuer sur les exécutables détectés
$action = {
    param($path)
    if ([string]::IsNullOrEmpty($path)) {
        Write-Host "Chemin du fichier manquant." -ForegroundColor Yellow
        return
    }
    
    Write-Host "Nouvel exécutable détecté : $path"
    
    # Supprimer le blocage de sécurité des fichiers et les supprimer
    try {
        Unblock-File -Path $path -ErrorAction Stop
        Remove-Item -Path $path -Force -ErrorAction Stop
        Write-Host "Attention, un exécutable lié à un ransomware (Big Head) a été détecté et supprimé : $path" -ForegroundColor Green
    } catch {
        Write-Host "Attention, un exécutable lié à un ransomware (Big Head) a été détecté et n'a pas pu être supprimé : $path" -ForegroundColor Red
        Write-Host "Erreur : $_" -ForegroundColor Red
    }
}

# Boucle infinie pour surveiller les dossiers et détecter les exécutables
while ($true) {
    foreach ($filter in $Filter) {
        $pathLocal = Join-Path -Path $folderLocal -ChildPath $filter
        $pathStartup = Join-Path -Path $folderStartup -ChildPath $filter
        
        if (Test-Path $pathLocal -PathType Leaf) {
            & $action -path $pathLocal
        }
        
        if (Test-Path $pathStartup -PathType Leaf) {
            & $action -path $pathStartup
        }
    }
    
    Start-Sleep -Seconds 2
}
