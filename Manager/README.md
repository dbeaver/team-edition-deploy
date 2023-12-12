### Team Edition server manager

`dbeaver-te` is a utility to manage a Team Edition server. Using this manager, you can start or stop the server, as well as update its version.

How to user manager:

1. Connect to your server through the terminal.
  - If you use terminal in browser window:  
    Enter `sudo su - ubuntu`  after opening the terminal if you use the Ubuntu version  
    Enter `sudo su - ec2-user`  after opening the terminal if you use the RHEL version  
2. Enter `dbeaver-te` or `dbeaver-te help` to see the help menu.


### Configuration

The configuration occurs with the help of the [manager](#team-edition-server-manager).

To configure your server, you can enter the command `dbever-te configure`.
This will open the `.env` file, where you can change the parameters you want, then press `Ctrl+S` to save variables and `Ctrl+X` to exit the editor.


### Version update procedure

The update occurs with the help of the [manager](#team-edition-server-manager).

1. Connect to your server through the terminal.
2. Enter `dbeaver-te update list`
3. Choose the version you want to update.
4. Run this command: `dbeaver-te update %version%`
