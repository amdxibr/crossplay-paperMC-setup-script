# CrossplayPaperMCScript

A collection of scripts (.sh and .py) designed to automate and simplify the creation and update of a PaperMC Minecraft Java + Bedrock crossplay server.

# Setup instructions:

Make sure that you have python3 and Java 
(minimum version 21) installed on your device.

Create a folder and move these both scripts into it, if not already.

In order to use masterscript.sh, navigate to the directory where masterscript.sh is located using the cd command, and run this in your macOS or Linux terminal:

    chmod +x masterscript.sh && ./masterscript.sh

In order to use masterscript.py in linux and macOS, first ensure that you have python3 installed, and then run:

    chmod +x masterscript.py && ./masterscript.py

In Windows, ensure that you have python3 installed, navigate to the directory where masterscript.py is located using the cd command, and then run in the command prompt:

    python masterscript.py





On Termux (android), install Termux-Ubuntu by first running:

    pkg install wget proot git && wget https://raw.githubusercontent.com/Neo-Oli/termux-ubuntu/master/ubuntu.sh && ./ubuntu.sh
Then launch Ubuntu by running:

    ./start-ubuntu.sh
Once you've launched Ubuntu, run: 

    git clone https://github.com/amdxibr/CrossplayPaperMCScript && cd CrossplayPaperMCScript && chmod +x *

Then run the server setup script by either running

    ./masterscript.py
or if you don't have python3 installed, run

    ./masterscript.sh

# Usage instructions:

This script, when launched, gives 4 options:
1. Install (Asks us to choose different server properties, and then Installs the latest version of PaperMC, GeyserMC, Floodgate, Viaversion, ViaBackwards and ViaRewind as .jar files)
2. Update (Updates PaperMC and the above plugins to the latest version)
3. Start (Asks us to choose the minimum and maximum RAM allocation for our Minecraft (crossplay) server, and then starts the Minecraft server. If the server is active, type "stop" to halt the server)
4. Quit (Exits the script console)



# Important Considerations:
Note down that the server launched through this script is only locally hosted on your PC on localhost:25565 (localhost:19132 for Bedrock Edition). To make the server accessible worldwide, either set up port forwarding on your router, or create a TUNNEL using playit.gg or similar services.
