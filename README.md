# sam3-xml-event-admin
Administrate your Serious Sam 3 server through in-game chat

# What it does
This is a simple Lua script that listens for XML_Log events on your Serious Sam 3 dedicated server and runs certains actions on them. I examines `<chat>` messages for server commands and uses the `<playerjoined>` and `<playerleft>` XML messages are used to keep track of connected players. By typing a pre-defined command into the in-game chat you can perform certain actions like changing the map or kicking a player.

# How to use it and available commands
Just open the chat (default 'y') and enter a command (prefixed with a dot). The following ones are currently implemented:

* `.kick` - calls gamKickByIndex() or gamKickByName() depending on whether `.kick` is followed by digits or a string. Examples: `.kick 7` kicks player with index 7 (see `gamListPlayers()` for the actual index number), `kick hans` kicks the player whose name begins with hans (case doesn't matter), e.g. Hans or hanswurst.
* `.ban` - calls gameBanByIndex() or gameBanByName, see above for details, and additionally kicks targeted player.
      
* `.pass` - calls samVotePass() - forces the current vote to pass
* `.fail` - calls samVoteFail() - forces the current vote to fail

* `.nextmap` - calls samNextMap - instantly changes to the next map in the active mapcycle
* `.restart map`- calls samRestartMap() - restarts the current map (without disconnecting players)
* `.restart game` - calls gamRestartGame() - restarts the current game (without disconnecting players)
* `.restart server` - calls gamRestartServer() - restarts the server and drops all connections

* `.start` - calls gamStart()- starts the game
* `.stop`  - calls gamStop() - stops the current game
* `.pause` - calls samPauseGame() - pauses and unpauses the game

# Installation
Copy the script to your `Content/SeriousSam3/Scripts/Startup/` directory, it will get automatically executed on server startup.

For the in-gaem chat commands to work, you will have to define at least one administrative user. By default, the variable `globals.ser_strAdminList` is used for this purpose. Its value is the hexadecimal representation of one or more steamID64, you can find these in the game's console/log or by running, e.g.

	printf "%x\n" 76561197964423629

Simply define the variable in a file that gets executed on server startup, e.g. your server.cfg:

	globals.ser_strAdminList = "1100001003f71cd;1100001066b41df;"
