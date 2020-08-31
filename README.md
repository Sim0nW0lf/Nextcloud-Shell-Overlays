# Nextcloud-Shell-Overlays
Pushing Nextcloud Registry Keys to the top to enable shell Overlays on windows

Installation:
Just download the .bat file and execute it in Windows after installing the Windows Nextcloud Client.
It may be recognized by Windows as a threat but I think that's normal because I edit the Registry. Don't worry about that.

You can execute the file as often as you like, the result will stay the same. (No junk files are being left behind)
I am using Batch because it runs on every Windows System.

The Script works like this:

1. Checking if NCOverlays.dll or OCOverlays.dll is at the default installation Path. (C:\Program Files\Nextcloud\shellext\)
When it's found continue with 3.
2. If the dll is not found, the whole PC will be searched for those two files. (disks in alphabetical order)
That covers the possibility that you installed the program anywhere else
3. Set right Nextcloud Registry Key Names to search for. (Depending on the Overlays.dll (actually Nextcloud Version) the registry keys will have different names.)
4. Delete all existing NC Reg Keys, if there are any (old and new ones)
5. Execute NC Overlays.dll to insert Keys in Registry
6. Push NC Keys on top of the list by adding spaces in front of their names (by copying, since you can not rename a reg key as far as I know)
7. When all Keys are on Top, delete remaining Reg Keys which were left over further down the list when copying
8. Restart Explorer.exe to be able to see the changes immediately

Feel free to contact me for issues/suggestions/mistakes, I just learned batch to write this script and I know my code is not very good at all! Still hope that it's useful to you.
(https://github.com/iPwnWolf/Nextcloud-Shell-Overlays)
