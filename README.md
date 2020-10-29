# linux_virtual_nexwork

### Introduction :
The goal of this project to create a virtual network of linux machine. I create a new shell command, called **rvsh** which works in two following modes: connect mode and admin mode.

When the file is run, check for the existence of the following three files:
1. *users.txt* : contains the usernames, their password and the list of machines to which they have the right of access
2. *machines.txt* : contains all the machine created by admin
3. *connection.log* : contains the list of current connections with the user name, machine name, login date and time, and terminal name.

### Project content :
#### Verification functions

| Function | Description |
| ------ | ------ |
| verifNbArguments() | check the number of arguments passed in parameter when the user types the rvsh command |
| verifNomMachine() | check whether the machine name entered by user exists |
| verifUtilisateur() | check whether the user exists  |
| verifAccess() | check if the machine connected and that the user has the right to connect to this machine |
| verifMdp() | check the password entered by the user to establish the connection. |

#### Log functions

| Function | Description |
| ------ | ------ |
| ajoutLog() | Add a log to the connection.log file each time a user logs in |
| supprimeLog() | delete the log from the connection.log file each time a user logs out. |

#### Connect Mode
This mode allows a user to connect to an existing virtual machine on the network. These virtual machines were created by admin. A user can connect to several machines at the same time.
To use mode 1, the user must type the command : 
```sh
$ ./rvsh.sh -connect machineName username
```
List of commande :
| Commande | Description |
| ------ | ------ |
| who | provides information on the different connected users, it is the linux 'who' command |
| rusers | displays the list of users connected to the network |
| rhosts | display the list of machines connected to the virtual network. |
| connect | allows the user to connect to another machine on the network. |
| su | allows the user to change users or to open a session of another user in the same machine, it is the Linux 'su' command |
| passwd | allows the user to change password across the entire virtual network, it is the linux 'passwd' command. |
| write | allows the user to send a message to other user logged on to a network machine, it is the Linux 'write' command |
| finger | display the information about users, it is the Linux 'finger' command. |

Admin mode :
Admin mode allows the administrator to log in to admin mode to manage users and virtual machines. 
To use mode 2, the admin must type the command
```sh
$ ./rvsh.sh -admin adminPassword
```
List of commande :
| Commande | Description |
| ------ | ------ |
| help | contains the display of the other commands with a short guide how to use them and what parameters they need |
| host | delete amd add machines. |
| users | delete, add and give user rights to machines |
| afinger | open file afinger for user |
