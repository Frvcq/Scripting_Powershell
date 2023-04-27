
is_insttalled (string $name) {
    $state = $false

    try {
        if ($((Get-WindowsFeature -name $name).installed)) {

            $state = $true
        }

        else {

            $state = $false
           
        }
    }
    catch {
        Write-Host "Erreur : " $($_.Exeception.Message)
        $state = $false
    }

    return $state

}
function installation_services_AD() {

    if (!(is_installed(AD-Domain-Services))){

        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

    }

    else{

        Write-Host "cest installed"

    }
    menu
    


}
function installation_DHCP() {
    if (is_installed(DHCP)){

        Install-WindowsFeature -Name DHCP -IncludeManagementTools

    }

    else{

        Write-Host "cest installed"

    }
    menu

}
function  installation_DNS() {
    if (is_installed(DNS)){

        Install-WindowsFeature -Name DNS -IncludeManagementTools

    }

    else{

        Write-Host "cest installed"

    }
    menu

}

function creation_arborescence() {
    try {
$root = "DC=ad01,DC=lcl"
$rep = @()

    $rep_nb = Read-Host "Combien de sous OU va comporter votre OU en plus de votre OU () 1 si que votre OU"
        for ($i=0;$i -lt $rep_nb;$i++){

            $rep+=($(Read-Host "Entrez le nom de l'OU numero $i"))

            New-ADOrganizationalUnit -Name $rep($i) -Path $root
            $root = "OU=$rep,"+$root

        }
        menu
    }

    catch{

        Write-Host "Erreur : " $($_.Exeception.Message)

    }

}

function creation_utilisateur_IN_OU($OU) {
try {

    $user_nameSam = Read-Host "entrer le sam"
    $user_name = Read-Host "entrer le nom"
    $user_firstname = Read-Host "entrer le firstname"
    $user_surname = Read-Host "entrer le surname"
    $user_mail = Read-Host "entrer le usermail"
    $user_password = Read-Host "entrer le password"

    New-ADUser -Name $user_nameSam -SamAccountName $user_name -GivenName $user_firstname -Surname $user_surname -EmailAddress $user_mail -AccountPassword (ConvertTo-SecureString $user_password -AsPlainText -Force) -Enabled $true
    menu
}

catch {

 Write-Host "Erreur : " $($_.Exeception.Message)

}

}
function  configuration_dhcp() {
    try {
       
        do {
            $numberOfRange = Read-Host "Combien d'étendu souhaitez-vous créer ?"
            for ($i = 0; $i -lt $numberOfRange; $i++) {
                $rangeName = Read-Host "Quel est le nom de la range n°$($i + 1)?"
                $startRange = Read-Host "Donner l'adresse de début de l'étendue"
                $endRange = Read-Host "Donner l'adresse de fin de l'étendue"
                $subnetmask = Read-Host "Donner le masque de sous réseau en décimal pointer (exemple : 255.255.255.0)"
                $dnsServer = Read-Host "Donner l'adresse du serveur DNS"
                $gatewayAddr = Read-Host "Donner l'adresse de la passerelle"
                $lessDays = Read-Host "Nombre de jour avant expiration des baux"
                $lessHours = Read-Host "Nombre d'heure avant expiration des baux"
                $lessMinutes = Read-Host "Nombre de minutes avant expiration des baux"
                $lessDuration = New-TimeSpan -Days $lessDays -Hours $lessHours -Minutes $lessMinutes
    
                Add-DhcpServerV4Scope -Name $rangeName -StartRange $startRange -EndRange $endRange -SubnetMask $subnetmask
                
                Set-DhcpServerV4OptionValue -DnsServer $dnsServer -Router $gatewayAddr
                
                Set-DhcpServerv4Scope -ScopeId (Get-NetIPAddress -AddressFamily IPv4).IPAddress[0] -LeaseDuration $lessDuration -State Active
            }
            Restart-service dhcpserver
            Write-Host "Configuration du service DHCP réussi" -ForegroundColor Green
        }while ($numberOfRange -notmatch "[0-9]+")
        menu
    }
    catch {
        Write-Host "Erreur : " $($_.Exeception.Message)
    }
}
function  activation_dhcp() {
    try {
        $fqdn = "$($env:COMPUTERNAME).$((Get-ComputerInfo).CSDomain)"
        Add-DhcpServerInDC -DnsName $fqdn -IPAddress (Get-NetIPAddress -AddressFamily IPv4).IPAddress[0]
        Set-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles\12 -Name ConfigurationState -Value 2
        menu

    }

    catch {

        Write-Host "Erreur : " $($_.Exeception.Message)
    }
    
        

}
function desactiver_all_mdp() {
    try {
        foreach ($user in (Get-ADUser -Filter * -Property * | Where-Object { $_.passwordneverexpires -ne $true })) {
            if ($user.name -eq "Administrateur" || $user.name -eq "Admin"){
                Write-Host "on ne touche pas a ladmin" 
            }
            else{
            Set-ADUser -Identity $user.SamAccountName -AccountExpirationDate (Get-Date -Format "MM/dd/yyyy HH:mm:ss")
            Write-Host "Date d'expiration de $($user.Name) modifier avec succès" -ForegroundColor Green
            }
        }
        menu
    }
    catch {
        Write-Host "Erreur : " $($_.Exeception.Message)
    }
    

}


function afficher_arborescence {
#aka by le flavien el bg qui a ameliorer a fond la caisse
    param(
    
        [string]$baseDN,
    
        [int]$indentLevel = 0
    
    )
    
    
    
    
    # Define an array of colors to use for each level of indentation
    
    $colors = @('Green', 'Yellow', 'Cyan', 'Magenta', 'Red', 'Blue', 'Gray')
    
    
    
    
    # Retrieve the child nodes for the current node
    
    $childNodes = Get-ADOrganizationalUnit -SearchBase $baseDN -Filter * -Properties Name -SearchScope OneLevel
    
    
    
    
    # Process each child node recursively
    
    foreach ($childNode in $childNodes) {
    
        # Indent the output based on the current recursion level
    
        $indent = " " * $indentLevel
    
    
    
    
        # Get the color to use for this level of indentation
    
        $colorIndex = $indentLevel % $colors.Count
    
        $color = $colors[$colorIndex]
    
    
    
    
        # Write the name of the current node to the console in the current color
    
        Write-Host "$indent" -NoNewline
    
        Write-Host $childNode.Name -ForegroundColor $color
    
    
    
    
        # Recursively process the child node
    
        afficher_arborescence -baseDN $childNode.DistinguishedName -indentLevel ($indentLevel + 1)
        menu
    }
    
}

function import_user_csv($path_to_csv, $race_du_fichier) {
    try {

        if ($race_du_fichier -match "*.csv") {
    
            $users = Import-Csv $path_to_csv -Delimiter ";"

            foreach ($user in $users) {
                New-ADUser -Name $user.Name -SamAccountName $user.SamAccountName -GivenName $user.FirstName -Surname $user.LastName -EmailAddress $user.Email -AccountPassword (ConvertTo-SecureString $user.Password -AsPlainText -Force) -Enabled $true
            }
        }
        else {


            Write-Error "Le fichier n'est pas un csv"
        }
        menu
    }
    catch {

        Write-Host "Erreur : " $($_.Exeception.Message)
    }
}

function menu() {
    Write-Host "1- L’installation des services AD, DHCP ainsi que le DNS en premier choix,
2- demander à l’utilisateur de créer l’arborescence de l’ADE
3- proposer à l’utilisateur de créer les utilisateurs dans l’OU Users.
4- En quatrième choix, proposer à l’utilisateur de configurer et d’activer son serveur DHCPE
5- cinquième choix, proposer à l’utilisateur de désactiver l’ensemble des mots de passe Users
6- En  sixième choix, proposer l’affichage de l’ensemble de l’arborescence de  l’ADE
7- septième choix, proposer un export en csv des utilisateurs de l’AD
8- Et pour finir en huitième choix, proposer un import des utilisateur d’un AD en CSV
9- quitter
appuyez sur n'importe quoi pour relancer le menu"
    Read-Host $choice
    switch ($choice) {
        0 {
            installation_services_AD
            installation_DHCP
            installation_DNS
        }
        1 {
            creation_arborescence

        }
        2 { 
            creation_utilisateur_IN_OU
        }
        3 {
            configuration_dhcp
            activation_dhcp

        }
        4 {
            desactiver_all_mdp
        }
        5 { 
            afficher_arborescence
        }
        6 { 
            export_user_csv
        }
        7 { 
            import_user_csv
        }
        8 { 
            exit 0
        }
        default { 

            menu

        }
    }



}


#==========================================MAIN================================================#

menu