Import-Module ActiveDirectory

# Paramètres configurables
$CsvPath              = "D:\Users.csv"
$FirstNameColumn      = "prénom"
$LastNameColumn       = "nom"
$GroupColumnPrefix    = "groupe"
$DomainName           = "laplateforme.io"
$BaseDN               = "DC=laplateforme,DC=io"
$UserOuName           = "Utilisateurs"
$GroupOuName          = "Groupes"
$DefaultPasswordPlain = "Azerty_2025!"

# Crée une OU si elle n'existe pas déjà
function New-OUIfNotExists {
    param($Name, $Path)
    $dn = "OU=$Name,$Path"
    if (-not (Get-ADOrganizationalUnit -LDAPFilter "(distinguishedName=$dn)" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $Name -Path $Path | Out-Null
        Write-Host "OU créée : $dn"
    }
}

# Création des OUs Utilisateurs et Groupes
New-OUIfNotExists -Name $UserOuName  -Path $BaseDN
New-OUIfNotExists -Name $GroupOuName -Path $BaseDN
$UserOuPath  = "OU=$UserOuName,$BaseDN"
$GroupOuPath = "OU=$GroupOuName,$BaseDN"

# Lecture du fichier CSV
$CsvUsers = Import-Csv -Path $CsvPath -Delimiter "," -Encoding Default |
    Where-Object { $_.$FirstNameColumn -and $_.$LastNameColumn }

# Colonnes groupe* dynamiques
$groupColumns = $CsvUsers[0].PSObject.Properties |
    Where-Object { $_.Name -like "$GroupColumnPrefix*" } |
    Select-Object -ExpandProperty Name

# Groupes mentionnés dans le CSV
$groupsMentioned = [System.Collections.Generic.HashSet[string]]::new()
foreach ($User in $CsvUsers) {
    foreach ($col in $groupColumns) {
        $value = $User.$col
        if ($value) { $null = $groupsMentioned.Add($value.Trim()) }
    }
}

# Liste les groupes existants dans l'OU
$existingGroups = @{ }
Get-ADGroup -Filter * -SearchBase $GroupOuPath | ForEach-Object { $existingGroups[$_.Name] = $true }

# Création des groupes manquants
foreach ($group in $groupsMentioned) {
    if (-not $existingGroups.ContainsKey($group)) {
        New-ADGroup -Name $group -GroupScope Global -GroupCategory Security -Path $GroupOuPath | Out-Null
        Write-Host "Groupe créé : $group"
    }
}

# Récupère les utilisateurs déjà existants dans l'OU
$existingUsers = @{ }
Get-ADUser -Filter * -SearchBase $UserOuPath -Properties SamAccountName | ForEach-Object {
    $existingUsers[$_.SamAccountName.ToLower()] = $true
}

# Génère un SamAccountName unique pour chaque utilisateur
function Get-UniqueSamAccountName($first, $last, $existingUsers) {
    $base = (($first.Substring(0, [Math]::Min(3, $first.Length)) + $last) -replace '[^a-zA-Z0-9]', '').ToLower()
    $sam = $base
    $i = 1
    while ($existingUsers.ContainsKey($sam)) {
        $sam = "$base$i"
        $i++
    }
    return $sam
}

# Mot de passe par défaut
$DefaultPassword = ConvertTo-SecureString $DefaultPasswordPlain -AsPlainText -Force

# Prépare l'affectation des utilisateurs aux groupes
$groupMembers = @{ }

foreach ($User in $CsvUsers) {
    $First = $User.$FirstNameColumn
    $Last  = $User.$LastNameColumn
    $FullName = "$First $Last"
    $Sam = Get-UniqueSamAccountName $First $Last $existingUsers
    $UPN = "$Sam@$DomainName"

    # Création du compte utilisateur si inexistant
    if (-not $existingUsers.ContainsKey($Sam)) {
        New-ADUser -Name $FullName `
                   -GivenName $First `
                   -Surname $Last `
                   -SamAccountName $Sam `
                   -UserPrincipalName $UPN `
                   -AccountPassword $DefaultPassword `
                   -Enabled $true `
                   -ChangePasswordAtLogon $true `
                   -Path $UserOuPath
        Write-Host "Utilisateur créé : $FullName ($Sam)"
        $existingUsers[$Sam] = $true
    }

    # Préparation de l'appartenance aux groupes
    foreach ($col in $groupColumns) {
        $group = $User.$col
        if ($group) {
            $group = $group.Trim()
            if (-not $groupMembers.ContainsKey($group)) {
                $groupMembers[$group] = [System.Collections.Generic.HashSet[string]]::new()
            }
            $null = $groupMembers[$group].Add($Sam)
        }
    }
}

# Ajoute chaque utilisateur à ses groupes respectifs
foreach ($group in $groupMembers.Keys) {
    $members = @($groupMembers[$group])
    if ($members.Count -gt 0) {
        try {
            Add-ADGroupMember -Identity $group -Members $members -ErrorAction Stop
            Write-Host "Ajout au groupe : $group"
        } catch {
            Write-Warning "Erreur pour le groupe $group : $_"
        }
    }
}


