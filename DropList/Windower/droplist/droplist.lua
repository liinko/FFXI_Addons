--[[
Copyright © 2020, Liinko
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of <addon name> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

_addon.name = 'DropList'
_addon.author = 'Liinko'
_addon.version = '1.0.0.0'
_addon.command = 'droplist'

require('logger')
config = require('config')
texts = require('texts')
res = require('resources')
 
----------------------------------------------------------------------------------------------------
-- Configurations
----------------------------------------------------------------------------------------------------
defaults = {};
defaults.pos = {};
defaults.pos.x = 600;
defaults.pos.y = 350;
defaults.text = {};
defaults.text.font = 'Arial';
defaults.text.size = 12;
defaults.display = {};
defaults.display.bg = {};
defaults.display.bg.alpha = 102;

active = true;
viewTotal = false;

-- Gets a text representation of droplist active status
function getActive()
	if active then
		return "ON";
	else
		return "OFF";
	end
end

-- Sets the title to the drop list
function setTitle()
	return 'Drop List (%s)':format(getActive());
end

dlText = T{ setTitle(), '-------------------------'  };
dropItems = {};
totalInv = {};
 
settings = config.load(defaults);
drops = texts.new(settings.display, settings);
drops:text(dlText:concat('\n'));
drops:show();

----------------------------------------------------------------------------------------------------
-- func: add item
-- desc: Event called when the player aqquires an item.
----------------------------------------------------------------------------------------------------
windower.register_event('add item', function(bag, index, id, count)

	if(bag == 0 and active) then
		local itemName = res.items[id].name;
		
		-- Check if already in dropped items list to either add new or add to existing
		if(setContains(dropItems, itemName)) then
			dropItems[itemName] = dropItems[itemName]  + count;
		else
			dropItems[itemName] = count;
		end
		
		totalInv[itemName] = getTotalInInventory(id);
		
		setItemsToList();
	end
end)


----------------------------------------------------------------------------------------------------
-- Extra Functions
----------------------------------------------------------------------------------------------------

-- Gets the total item count in the player inventory
function getTotalInInventory(itemId)
	local total = 0;
	-- Get total from inventory
	for _, item in ipairs(windower.ffxi.get_items(0)) do
		if item.id == itemId then
			total = total + item.count;
		end
	end
	
	return total;
end

-- Inserts items into tracking table
function setItemsToList()
	dlText = T{ setTitle(), '-------------------------' };
	
	for key,value in pairs(dropItems) do
		if(viewTotal) then
			dlText:append('%s: %s (%s)':format(key, value, totalInv[key]));
		else
			dlText:append('%s: %s':format(key, value));
		end
	end
	
	drops:text(dlText:concat('\n'));
end

-- Checks if the table conatians an item aleady
function setContains(set, key)
    return set[key] ~= nil;
end

----------------------------------------------------------------------------------------------------
-- func: addon command
-- desc: Called when the addon is handling a command.
---------------------------------------------------------------------------------------------------
windower.register_event('addon command', function(...)
	local param = L{...};
	local command = param[1];

	-- Help Command
	if command == 'help' then
		log("'reset' removes everything from the drop list" );
		log("'toggle' toggles the drop list on or off" );
		log("'toggletotal' toggles the inventory totals" );
		
	-- Reset Command
	elseif command == 'reset' then
		for k,v in pairs(dropItems) do dropItems[k]=nil end
		for k,v in pairs(totalInv) do totalInv[k]=nil end
		dlText = T{ setTitle(), '-------------------------' };
		drops:text(dlText:concat('\n'));
		
	-- Toggle Command
	elseif command == 'toggle' then
		if active then
			active = false;
		else
			active = true;
		end
		dlText[1] = setTitle();
		drops:text(dlText:concat('\n'));
		
	-- Toggle Totals Command
	elseif command == 'toggletotal' then
		if viewTotal == true then
			viewTotal = false;
		elseif viewTotal == false then
			viewTotal = true;
		end
		setItemsToList();
	end
end)
