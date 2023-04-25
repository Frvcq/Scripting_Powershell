# Récupérer tous les utilisateurs et leurs propriétés de département et de ville
$users = Get-ADUser -Filter * -Properties Department, City

# Identifier l'ensemble des villes et des services d'appartenance des utilisateurs
$cities = $users | Select-Object -ExpandProperty City -Unique
$departments = $users | Select-Object -ExpandProperty Department -Unique

# Créer des OU et des groupes en fonction des propriétés de département et de ville de chaque utilisateur
foreach ($city in $cities) {
   New-ADOrganizationalUnit -Name $city -Path "DC=ad01,DC=lcl"
  foreach ($department in $departments) {

   New-ADOrganizationalUnit -Name $department -Path "OU=$city,DC=ad01,DC=lcl"

    New-ADGroup -Name "$department $city" -GroupScope Global -Path "OU=$department,OU=$city,DC=ad01,DC=lcl"

    $deptGroup = Get-ADGroup -Filter { Name -eq "$city $department"} | Select-Object -Property DistinguishedName
    
    $usersInDept = $users | Where-Object { $_.City -eq $city -and $_.Department -eq $department }

    foreach ($user in $usersInDept) {

      Add-ADGroupMember -Identity $deptGroup -Members $user
    }
  
  }


}