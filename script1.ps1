# Installation du rôle AD DS (Active Directory Domain Services)
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Saisie sécurisée du mot de passe pour le mode restauration AD
$SafeModePassword = Read-Host "Mot de passe administrateur (mode restauration DSRM)" -AsSecureString

# Création de la forêt et du domaine Active Directory "laplateforme.io"
Install-ADDSForest `
    -DomainName "laplateforme.io" `
    -DomainNetbiosName "LAPLATEFORME" `
    -InstallDNS `
    -SafeModeAdministratorPassword $SafeModePassword `
    -Force

