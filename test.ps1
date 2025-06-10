Import-Module ActiveDirectory

$UserOuName   = "Utilisateurs"
$GroupOuName  = "Groupes"
$BaseDN       = "DC=laplateforme,DC=io"
$UserOuPath   = "OU=$UserOuName,$BaseDN"
$GroupOuPath  = "OU=$GroupOuName,$BaseDN"

Write-Host "Vérification des OU..."
Get-ADOrganizationalUnit -Filter * | Where-Object { $_.DistinguishedName -eq $UserOuPath -or $_.DistinguishedName -eq $GroupOuPath }

# Récupération des groupes et utilisateurs une seule fois pour éviter les requêtes multiples
$groups     = Get-ADGroup -Filter * -SearchBase $GroupOuPath
$users      = Get-ADUser -Filter * -SearchBase $UserOuPath

# Affichage des groupes
Write-Host "`nGroupes présents dans $GroupOuName ($($groups.Count)) :"
$groups | Select-Object Name

# Affichage des utilisateurs
Write-Host "`nUtilisateurs présents dans $UserOuName ($($users.Count)) :"
$users | Select-Object Name, SamAccountName

# Membres par groupe
Write-Host "`nMembres par groupe :"
foreach ($group in $groups) {
    Write-Host "`n$($group.Name) :"
    $members = Get-ADGroupMember -Identity $group -Recursive | Select-Object -ExpandProperty SamAccountName
    if ($members) {
        $members
    } else {
        Write-Host "Aucun membre"
    }
}
