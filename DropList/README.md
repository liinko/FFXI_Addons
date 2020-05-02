# DropList
  - An item tracker which tracks any item that falls into a players inventory
  
## Features
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;![DropList](https://i.imgur.com/WlmuHcy.jpg)
  
  - **Tracks any items that go into a players inventory**
    - Chocobo Digging - track dug up items
    - Farming - track monster drops
    - HELM - track gathered items
    - Or if you are in a party and just want to see what you get over time (like the images)
  
  - **Ability to track inventory totals**
    - This is useful when you log out, then log in later and continue getting items and you want to know the total you have in your inventory and not just what has been obtained that session
    - This is OFF by default, you can turn it on with the **toggletotal** command
  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;![DropListWithTotals](https://i.imgur.com/RxBZUF2.jpg)

## Things to note
  - This will track literally anything that goes into your inventory and add it to the list, that means anything such as
    - Moving items from mog house/wardrobe/etc. into your inventory
    - Purchasing items from NPCs
    - Trades
    - Etc.
    
  - To avoid reseting your list if this happens, you can pause tracking by using the **toggle** command
    - This will keep everything in your list, but will not add anything new until it is toggled ON again
    - You can see the tracking status on the top of the list **(ON)** or **(OFF)**
    
  - The list can be moved 
    - Windower: click and drag 
    - Ashita: hold shift then click and drag
    
  - The list does not update when items are removed from inventory (dropped, sold, etc.)
  
  - (Ashita) Equipping an item with charges (eg. Empress Ring) may cause it to potentially appear on the list

## Instructions
- Place the appropriate DropList folder into the addons directory 
  - Windower: \Windower\addons
  - Ashita: \Ashita\addons
  
- Type the load command in-game, or add it to the appropriate load script
  - Windower: //lua load droplist
  - Ashita: /addon load droplist
  
- To remove it
  - Windower: //lua unload droplist
  - Ashita: /addon unload droplist
  
 ## Commands
 - **help**
    - Shows list of commands and their function
 - **toggle**
    - Toggles item tracking ON or OFF
 - **toggletotal**
    - Toggles inventory totals display
 - **reset**
    - Clears the entire Drop List
    
