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
]]--

_addon.author   = 'Liinko';
_addon.name     = 'DropList';
_addon.version  = '1.0.0';

require 'common'
require 'imguidef'

----------------------------------------------------------------------------------------------------
-- Configurations
----------------------------------------------------------------------------------------------------
local default_config =
{
    font =
    {
        family      = 'Arial',
        size        = 12,
        color       = 0xFFFFFFFF,
        position    = { 600, 350 },
        bgcolor     = 0x80000000,
        bgvisible   = true
    }
};

local active = true;
local zoning = false;
local viewTotal = false;
local beingEquipped = false;

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
	return string.format('Drop List (%s)', getActive());
end

local droplist_config = default_config;
local r = AshitaCore:GetResourceManager();
local dlText = T{ setTitle(), '-------------------------'  };
local dList = {};
local totalInv = {};

----------------------------------------------------------------------------------------------------
-- func: load
-- desc: Event called when the addon is being loaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
    -- Attempt to load the fps configuration..
    droplist_config = ashita.settings.load_merged(_addon.path .. 'settings/settings.json', droplist_config);

    -- Create our font object..
    local f = AshitaCore:GetFontManager():Create('__droplist_display');
    f:SetColor(droplist_config.font.color);
    f:SetFontFamily(droplist_config.font.family);
    f:SetFontHeight(droplist_config.font.size);
    f:SetBold(false);
    f:SetPositionX(droplist_config.font.position[1]);
    f:SetPositionY(droplist_config.font.position[2]);
    f:SetText(dlText:concat('\n'));
    f:SetVisibility(true);
    f:GetBackground():SetColor(droplist_config.font.bgcolor);
    f:GetBackground():SetVisibility(droplist_config.font.bgvisible);
end);

----------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Event called when the addon is being unloaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()
    local f = AshitaCore:GetFontManager():Get('__droplist_display');
    droplist_config.font.position = { f:GetPositionX(), f:GetPositionY() };
        
    -- Save the configuration..
    ashita.settings.save(_addon.path .. 'settings/settings.json', droplist_config);
    
    -- Unload our font object..
    AshitaCore:GetFontManager():Delete('__droplist_display');
end );

----------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Event called when the addon is asked to handle an incoming packet.
----------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, packet, packet_modified, blocked)
	
	-- Item is being equipped
	-- We track this to prevent items such as bands to appear on list when being equipped
	if (id == 0x0050) then
		beingEquipped = true;
	end
	
	-- Zoning
	-- We track this to prevent all inventory items to appear on list after zoning
	if (id == 0x000B) then
		zoning = true;
	end
	
	-- Done loading inventory
	-- We track this to allow item tracking after zoning
	if (id == 0x001D) then
		if(zoning) then
			zoning = false;
		end
	end

    -- Incoming item update packet..
    if (id == 0x0020) then
		-- active is user defined
		-- We prevent updates while zoning 
		-- We don't add an item if it's being equipped, this happens with items that have charges
		if(active and not zoning and not beingEquipped) then
			-- Item update packet data
			local itemCount = struct.unpack("I", packet, 0x04 + 1);
			local bazaar = struct.unpack("I", packet, 0x08 + 1); -- Not Used
			local itemId = struct.unpack('H', packet, 0x0C + 1);
			local bag = struct.unpack("B", packet, 0x0E + 1);
			local index = struct.unpack("B", packet, 0x0F + 1); -- Not Used
			local status = struct.unpack("B", packet, 0x10 + 1); -- a status of 5 is equipped
			
			-- We only care about items going into our inventory
			-- Any stutus > 0 should not be added, specifically we want to prevent items that have charges from adding to list when they are ready to use
			if(bag == 0 and itemCount > 0 and status == 0) then
				local item = r:GetItemById(itemId);
				local itemName = item.Name[0];
			
				-- Check if already in dropped items list to either add new or add to existing
				if(setContains(dList, itemName)) then
					dList[itemName] = dList[itemName]  + itemCount;
				else
					dList[itemName] = itemCount;
				end
				
				-- set inventory total
				totalInv[itemName] = getTotalInInventory(itemId) + itemCount;
				
				setItemsToList();
			end
		end
		beingEquipped = false;
    end
    return false;
end);

----------------------------------------------------------------------------------------------------
-- Extra Functions
----------------------------------------------------------------------------------------------------

-- Inserts items into tracking table
function setItemsToList()
	local drops = AshitaCore:GetFontManager():Get('__droplist_display');
	dlText = T{ setTitle(), '-------------------------' };
	
	for key,value in pairs(dList) do
		if(viewTotal) then
			table.insert(dlText, string.format('%s: %s (%s)', key , value, totalInv[key]));
		else
			table.insert(dlText, string.format('%s: %s', key, value));
		end
	end
	
	drops:SetText(dlText:concat('\n'));
end

-- Gets the total item count in the player inventory
function getTotalInInventory(itemId)
	local inventory = AshitaCore:GetDataManager():GetInventory();
	local inventoryMax = inventory:GetContainerMax(0);
	local total = 0;
	
	for x = 0, inventoryMax do
		local item = inventory:GetItem(0, x);
		if (item ~= nil and item.Id == itemId) then
			total = total + item.Count;
		end
	end
	
	return total;
end

-- Checks if the table conatians an item aleady
function setContains(set, key)
    return set[key] ~= nil;
end

----------------------------------------------------------------------------------------------------
-- func: command
-- desc: Called when the addon is handling a command.
----------------------------------------------------------------------------------------------------
ashita.register_event('command', function(cmd, nType)
    
	-- Parse the incoming command..
    local args = cmd:args();
    if (args == nil or #args == 0 or args[1] ~= '/droplist') then
        return false;
    end
	
	-- help command
	if (#args >= 2 and args[2] == 'help') then
        print(string.format('Commands:'));
		print(string.format('reset - removes everything from the drop list'));
		print(string.format('toggle - toggles the drop list on or off'));
		print(string.format('toggletotal - toggles the inventory totals'));	
        return true;
    end
	
	-- toggle command
	if (#args >= 2 and args[2] == 'toggle') then
		local drops = AshitaCore:GetFontManager():Get('__droplist_display');
		
		if(active) then
			print(string.format('The Drop List has been toggled OFF, item tracking paused.'));
			active = false;
		else
			print(string.format('The Drop List has been toggled ON, item tracking resumed.'));
			active = true;
		end
		
		dlText[1] = setTitle();
		drops:SetText(dlText:concat('\n'));
        return true;
    end
	
	-- toggle total command
	if (#args >= 2 and args[2] == 'toggletotal') then
		local drops = AshitaCore:GetFontManager():Get('__droplist_display');
		
		if(viewTotal) then
			print(string.format('Drop List now hiding Inventory Totals'));
			viewTotal = false;
		else
			print(string.format('Drop List now showing Inventory Totals'));
			viewTotal = true;
		end
		
		setItemsToList();
        return true;
    end
	
	-- reset command
	if (#args >= 2 and args[2] == 'reset') then
		local drops = AshitaCore:GetFontManager():Get('__droplist_display');
        print(string.format('Drop List Reset'));
		for k,v in pairs(dList) do dList[k]=nil end
		
		dlText = T{ setTitle(), '-------------------------' };
		drops:SetText(dlText:concat('\n'))
        return true;
    end
	
    return false;
end);
