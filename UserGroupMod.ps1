<#
Powershell User and Group Modification Tool
(C) Ana Gallardo Ballesteros 2023

A simple script to manage users and groups.
This version will ACTUALLY modify users/groups.
Tread with caution.
#>

<#
GLOBAL VARIABLES WILL GO HERE, IF ANY.
#>
$Global:mod_user_name = ""

<#
//////////////////////////////////////////////////
//////////////////////////////////////////////////
/////   S T A R T   O F    T H E   U S E R   /////
/////    M A N A G E M E N T    B L O C K    /////
//////////////////////////////////////////////////
//////////////////////////////////////////////////
#>

<#
THE user_management FUNCTION
    This function will manage user creation as well
    as modification and deletion. It will primarily
    collect data needed, and pass it any other
    sub-routines as needed. It is essentially a
    glorified sub-menu with extra steps.
#>
function user_management{
    print_user_menu
    while(($user_selection = Read-Host -Prompt "Seleccione una Opcion") -ne "5"){
        print_user_menu
        switch($user_selection){
            1 {
                Clear-Host
                create_user
                print_user_menu
            }
            2 {
                Clear-Host
                modify_user
                print_user_menu
            }
            3 {
                Clear-Host
                list_user
                print_user_menu
            }
            4 {
                Clear-Host
                delete_user
                print_user_menu
            }
            5 {
                Clear-Host
                main_menu
            }
            default {
                print_selector_error
                print_user_menu
            }   
        }
        Clear-Host
        print_user_menu |Out-Host
    }
}
# END OF user_management FUNCTION

#THE "print_" FUNCTIONS PRINT THE RELEVANT MENUS TO SAVE ON REPETITION
function print_user_menu{
    Clear-Host
    Write-Output "1) Creacion de Usuario";
    Write-Output "2) Modificacion de Usuario";
    Write-Output "3) Listar Usuarios";
    Write-Output "4) Borrado de Usuario";
    Write-Output "5) Volver";
}

<#
THE create_user FUNCTION
    It handles the actual user creation. It has been
    broken off the case switch to avoid potential
    conflicts and keeping things readable
#>
function create_user{
    Clear-Host;
    $user_name = Read-Host -Prompt "Login de Usuario";
    $full_name = Read-Host -Prompt "Nombre Completo del Usuario";
    $pass_word = Read-Host -AsSecureString -Prompt "Password (Opcional)";
    # TODO: Check how to PROPERLY compare "AsSecureString". A check
    # like ($pass_word -eq $pass_word_2) yields error.
    # If the $pass_word var is empty, create an user with no password.
    # Otherwise, copy $pass_word's contents to the -Password argument
    if ( ($pass_word -eq "") ){
        New-LocalUser $user_name -NoPassword -FullName $full_name | Out-Host
        Write-Output "Hecho"
        pause;
    }
    elseif( ($pass_word -ne "") ){
        New-LocalUser $user_name -Password $pass_word -FullName $full_name | Out-Host
        Write-Output "Hecho"
        pause;
    }
    # Vestigial check trying to compare the password and the password confirmation.
    else{
        Write-Host -ForegroundColor white -BackgroundColor red "Error en la creacion de Usuario";
        pause;
        user_management
    }
    Clear-Host;
}
# END OF create_user FUNCTION

<#
+++++          MODIFY USER SUB-BLOCK         +++++
#>

<#
THE select_mod_user FUNCTION
    This function will check for the presence of the
    user selected by the end-user, and proceed
    accordingly in basis of it's success, or failure
#>
function select_mod_user{
    # Make sure the username to be acted upon is $null
    Clear-Variable mod_user_name -Scope Global
    # Safety check for people who press Enter too many times
    while ( ($Global:mod_user_name -eq "") -or ($Global:mod_user_name -eq $null) ){  
        $Global:mod_user_name = Read-Host -Prompt "Usuario a Modificar (Escribir 0 Para Salir)";
        if ($Global:mod_user_name -eq 0){
            # clear mod_user_name and return users home
            Clear-Variable mod_user_name -Scope Global
            break;
        }
        # Check if the user exists. If it does, keep the
        # current variable's contents for other methods
        try{
            Get-LocalUser -Name $Global:mod_user_name -ErrorAction Stop | Select-Object  Name | Out-Host
        }
        # If it doesn't. Print an error, null the variable
        # and return the users home.
        catch{
            print_selector_error | Out-Host
            Clear-Host
            Clear-Variable mod_user_name -Scope Global
        }
    }
}
# END OF select_mod_user FUNCTION

<#
THE modify_user FUNCTION
    Another menu without much logic. It will redirect
    the user's choice to the appropiate task
#>
function modify_user{
    # Call the select_mod_user to work with
    # the specified user, if it exists
    select_mod_user
    pause;
    print_mod_user_menu | Out-Host
    while(($user_mod_selection = Read-Host -Prompt "Seleccione una Opcion") -ne "4"){
        # Use Out-Host to avoid out-of-order printouts
        print_mod_user_menu | Out-Host
        switch($user_mod_selection){
            1 {
                # This needn't a bespoke function. ( won't be called elsewhere )
                # It'll acquire the global username and apply a new password.
                Clear-Host
                $user_new_password = Read-Host -AsSecureString -Prompt "Nueva Password?"
                $Global:mod_user_name | Set-LocalUser -Password $user_new_password
                Write-Output "Hecho"
                pause;
                Clear-Host
                print_mod_user_menu | Out-Host
            }
            2 {
                add_to_group
                Clear-Host
                print_mod_user_menu | Out-Host
            } 
            3 {
                remove_from_group
                Clear-Host
                print_mod_user_menu | Out-Host
            }
            4 {
                user_management
                print_mod_user_menu | Out-Host
            }
            default {
                Clear-Variable mod_user_name -Scope Global
                print_selector_error | Out-Host
                print_mod_user_menu | Out-Host
            }   
        }
        Clear-Host
        print_mod_user_menu | Out-Host
    }
}

#THE "print_" FUNCTIONS PRINT THE RELEVANT ITEMS TO SAVE ON REPETITION
function print_mod_user_menu{
    Clear-Host
    Write-Output "1) Cambiar Password";
    Write-Output "2) Agregar a Grupo";
    Write-Output "3) Eliminar de Grupo";
    Write-Output "4) Volver";
}

<#
THE add_to_group FUNCTION
    This function searches for a given group and
    based on that will attempt to add that user to
    the specified group
#>
function add_to_group{
    Clear-Host
    # Failsafe for people who press Enter too many times
    while ( ($mod_user_group -eq "") -or ($mod_user_group -eq $null) ){  
        $mod_user_group = Read-Host -Prompt "Grupo a Buscar (Escribir 0 para Salir)"
        if ($mod_user_group -eq 0){
            # Send the users home if they wrote 0
            Clear-Variable mod_user_group
            break;
        }
        # Try to check if the group exists. If it does. Add the user to the Group
        try{
            # Verify the existence of the group by querying
            # if an object with it's name exists
            Get-LocalGroup -Name $mod_user_group -ErrorAction Stop | Select-Object  Name | Out-Host
            Write-Output "Agregando el usuario $Global:mod_user_name en el grupo $mod_user_group" | Out-Host
            Add-LocalGroupMember -Group $mod_user_group -Member $Global:mod_user_name | Out-Host
            Write-Output "Hecho" | Out-Host
            # Global variables are dangerous. ALWAYS
            # clear them after being done with them.
            Clear-Variable mod_user_name -Scope Global
            pause;
            Clear-Host
        }
        catch{
            Clear-Variable mod_user_name -Scope Global
            # Empty the variable as it's the cause of the error
            print_selector_error
            # Send users the way they came from
            break;
        }
    }
}
# END OF add_to_group FUNCTION

<#
THE remove_from_group FUNCTION
    This function searches for a given group and
    based on that will attempt to delete that
    user from the specified group
#>
function remove_from_group{
    Clear-Host
    # Failsafe for those who obsessively press Enter
    while ( ($mod_user_group -eq "") -or ($mod_user_group -eq $null) ){  
        $mod_user_group = Read-Host -Prompt "Grupo a Buscar (Escribir 0 para Salir)"
        # The only anti-deletion safety. Press Zero to exit.
        if ($mod_user_group -eq 0){
            Clear-Variable mod_user_group
            break;
        }
        # Try to check if the group exists. If it does. Remove the user to the Group
        try{
            # Verify the existence of the group by querying
            # if an object with it's name exists
            Get-LocalGroup -Name $mod_user_group -ErrorAction Stop | Select-Object  Name | Out-Host
            Write-Output "Eliminando el usuario $Global:mod_user_name del grupo $mod_user_group" | Out-Host
            Remove-LocalGroupMember -Group $mod_user_group -Member $Global:mod_user_name | Out-Host
            Write-Output "Hecho" | Out-Host
            # Clear Global Variable before moving on
            Clear-Variable mod_user_name -Scope Global
            pause;
            Clear-Host | Out-Host
        }
        # Protection against typos.
        catch{
            Clear-Variable mod_user_name -Scope Global
            print_selector_error
            # Send users the way they came from
            break;
        }
    }
}
# END OF THE remove_from_group FUNCTION

<#
+++++      END OF MODIFY  USER SUB-BLOCK     +++++
#>

<#
THE list_user FUNCTION
    Functionally identical to running the
    "Get-LocalUser" cmdlet, with a little
    bit more spice. Hardcoded to always
    return to the user_management menu
#>
function list_user {
    Clear-Host
    Get-LocalUser | Out-Host
    pause;
    Clear-Host
    user_management
}

<#
THE delete_user FUNCTION
    This function will find an user to be deleted
    and if found, will delete it. Extra attention
    is provided against accidental deletion and
    last-minute changes of heart.
#>
function delete_user{
    # Select a valid user
    select_mod_user
    if ( ($Global:mod_user_name -eq "") -or ($Global:mod_user_name -eq $null) ){
        break
    }
    # Ensure the user REALLY wants to delete the user
    # Ask the user again if the answer is not POSITIVELY YES
    # For example, a valid user has been set, but user
    # may be second guessing themselves.
    $confirm = Read-Host -Prompt "Realmente borrar usuario $Global:mod_user_name?"
    if ( ($confirm -eq "Si") -or ($confirm -eq "SI") -or ($confirm -eq "si") ){
        Remove-LocalUser -Name $Global:mod_user_name | Out-Host
        Write-Output "Hecho"
        pause;
    }
    # If they aren't absolutely sure, send them to 
    # the start of the function, where they can hit
    # zero to exit, or choose another username
    else{
        user_management
    }
    Clear-Host
    user_management | Out-Host
}
# END OF THE delete_user FUNCTION

<#
//////////////////////////////////////////////////
//////////////////////////////////////////////////
/////     E N D   O F    T H E   U S E R     /////
/////    M A N A G E M E N T    B L O C K    /////
//////////////////////////////////////////////////
//////////////////////////////////////////////////
#>

<#
//////////////////////////////////////////////////
//////////////////////////////////////////////////
/////   S T A R T   O F  T H E   G R O U P   /////
/////    M A N A G E M E N T    B L O C K    /////
//////////////////////////////////////////////////
//////////////////////////////////////////////////
#>

<#
THE group_management FUNCTION
    This function will manage group creation and 
    deletion. It will primarily It is essentially
    a glorified sub-menu with extra steps.
#>

function group_management{
    print_group_menu
    while(($user_selection = Read-Host -Prompt "Seleccione una Opcion") -ne "7"){
        print_group_menu
        switch($user_selection){
            1 {
                Clear-Host
                create_group
                print_group_menu
            }
            2 {
                Clear-Host
                delete_group
                print_group_menu
            }
            3 {
                Clear-Host
                list_group
                print_group_menu
            }
            4 {
                Clear-Host
                select_mod_user
                add_to_group
                print_group_menu
            }
            5 {
                Clear-Host
                select_mod_user
                remove_from_group
                print_group_menu
            }
            6 {
                Clear-Host
                group_members
                print_group_menu
            }
            7 {
                Clear-Host
                main_menu
            }
            default {
                print_selector_error
                print_user_menu
            }   
        }
        Clear-Host
        print_group_menu | Out-Host
    }
}
# END OF group_management FUNCTION

#THE "print_" FUNCTIONS PRINT THE RELEVANT ITEMS TO SAVE ON REPETITION
function print_group_menu{
    Clear-Host
    Write-Output "1) Creacion Grupo";
    Write-Output "2) Borrar Grupo";
    Write-Output "3) Listar Grupos";
    Write-Output "4) Agregar Usuarios a un Grupo";
    Write-Output "5) Eliminar Usuarios de un Grupo";
    Write-Output "6) Listar Miembros de un Grupo";
    Write-Output "7) Volver";
}

<#
THE create_group FUNCTION
    Similar to create_user, it will acquire a few parameters,
    namemely, a name, and create a group based on it.
#>
function create_group{
    Clear-Host
    $group_name = Read-Host -Prompt "Nombre del Grupo"
    New-LocalGroup -Name $group_name | Out-Host
    Write-Output "Hecho"
    Clear-Variable group_name
    pause;
}
#END OF THE create_group FUNCTION

<#
THE delete_group FUNCTION
    Similar to delete_user, it will acquire the
    group's a name, and delete a group accordingly.
#>
function delete_group{
    Clear-Host
    $group_name = Read-Host -Prompt "Nombre del Grupo"
    # No concerns over orphaned users here.
    Remove-LocalGroup -Name $group_name | Out-Host
    Write-Output "Hecho"
    Clear-Variable group_name
    pause;
}
#END OF THE delete_group FUNCTION

<#
THE list_group FUNCTION
    A fancy wrapper over Get-LocalGroup
#>
function list_group{
    Clear-Host
    Get-LocalGroup | Out-Host
    pause;
}
# END OF THE list_group FUNCTION

<#
THE group_members FUNCTION
    This function will verify the existence of a group
    and if it exists, show the members of said group.
#>
function group_members{
    Clear-Host
    # Safety check for people who press Enter too many times
    while ( ($search_group -eq "") -or ($search_group -eq $null) ){  
        $search_group = Read-Host -Prompt "Grupo a Buscar (Escribir 0 para Salir)"
        # Clear the variable to prevent issues when revisiting
        # other menus, and send users the way back.
        if ($search_group -eq 0){
            Clear-Variable search_group
            break;
        }
        #Try to check if the group exists. 
        try{
            Get-LocalGroup -Name $search_group -ErrorAction Stop | Select-Object  Name | Out-Host
            Get-LocalGroupMember -Group $search_group | Out-Host
            pause;
        }
        catch{
            # If the group cannot be found, or is typo'd,
            # clear local and global-scope variables to prevent
            # issues with pre-filled data, and print an error
            Clear-Variable search_group
            Clear-Variable mod_user_name -Scope Global
            print_selector_error
            # Send users the way they came from
            break;
        }
    }
}
# END OF THE group_members FUNCTION

<#
//////////////////////////////////////////////////
//////////////////////////////////////////////////
/////    E N D   O F    T H E   G R O U P    /////
/////    M A N A G E M E N T    B L O C K    /////
//////////////////////////////////////////////////
//////////////////////////////////////////////////
#>

<#
//////////////////////////////////////////////////
//////////////////////////////////////////////////
/////    S T A R T   O F  T H E   M A I N    /////
/////         L O G I C    B L O C K         /////
//////////////////////////////////////////////////
//////////////////////////////////////////////////
#>

<#
THE main_menu FUNCTION
    Self explainatory. This function handles the
    basic input from the user, and will call any
    other functions as needed, as well as handling
    the exit of the program.
#>
function main_menu{
    print_main_menu
    while(($main_selection = Read-Host -Prompt "Seleccione una Opcion") -ne "3"){
        print_main_menu
        switch($main_selection){
            1 {
                Clear-Host;
                user_management
                print_main_menu
            }
            2 {
                Clear-Host;
                group_management
                print_main_menu
            }
            3 {
                Write-Output "Adios";
                pause;
                exit;
            }
            default {
                print_selector_error
                print_main_menu
            }   
        }
        Clear-Host
        print_main_menu | Out-Host
    }
}
# END OF main_menu FUNCTION

# THE "print_" FUNCTIONS PRINT THE RELEVANT MENUS TO SAVE ON REPETITION
function print_main_menu{
    Clear-Host
    Write-Output "1) Gestion de Usuarios";
    Write-Output "2) Gestion de Grupos";
    Write-Output "3) Salir";
}

# THE print_selector_error CATCH-ALL INPUT ERROR HANDLER
function print_selector_error{
    Clear-Host
    Write-Host -ForegroundColor white -BackgroundColor red "Seleccione una opcion valida";
    pause;
}
# END OF THE print_selector_error FUNCTION

<#
MAIN PROGRAM LOGIC
    Print script's own comments ( lines 2-7 )
    to generate a brief welcome/introduction to
    the software, then call the main_menu
    function to get the rest of the script started.
#>
Clear-Host
Get-Content $MyInvocation.MyCommand.Path | Select -First 6 -Skip 1
pause;
Clear-Host
main_menu | Out-Host

<#
//////////////////////////////////////////////////
//////////////////////////////////////////////////
/////    E N D    O F    T H E    M A I N    /////
/////         L O G I C    B L O C K         /////
//////////////////////////////////////////////////
//////////////////////////////////////////////////
#>

<#
EOF
#>