
function installation_services_AD() {


}
function installation_DHCP() {


}
function  installation_DNS() {


}

function creation_arborescence() {

                
}

function creation_utilisateur_IN_OU($OU) {


}
function  configuration_dhcp() {

}
function  activation_dhcp() {

}
function desactiver_all_mdp() {

    Get-ADUser -Filter "*"

}

function afficher_arborescence {

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
9- quitter"
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