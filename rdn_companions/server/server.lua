RedEM = exports["redem_roleplay"]:RedEM()

-- Based on Malik's and Blue's animal shelters and vorp animal shelter --
local data = {}
local VorpCore = {}
local VorpInv

if Config.Framework == "redem" then
	TriggerEvent("redemrp_inventory:getData",function(call)
		data = call
	end)
elseif Config.Framework == "vorp" then
	TriggerEvent("getCore",function(core)
		VorpCore = core
	end)
	VorpInv = exports.vorp_inventory:vorp_inventoryApi()
end

RegisterServerEvent('rdn_companions:sellpet')
AddEventHandler('rdn_companions:sellpet', function()

	local _src = source

	if Config.Framework == "redem" then
	  --TriggerEvent('redemrp:getPlayerFromId', _src, function(user)
			local user = RedEM.GetPlayer(_src)
			local u_identifier = user.getIdentifier()
			local u_charid = user.getSessionVar("charid")

			exports.oxmysql:execute("DELETE FROM companions WHERE identifier = @identifier AND charidentifier = @charidentifier", {["identifier"] = u_identifier, ['charidentifier'] = u_charid})

			--MySQL.Sync.execute("DELETE FROM companions WHERE identifier = @identifier AND charidentifier = @charidentifier", {["identifier"] = u_identifier, ['charidentifier'] = u_charid})
			TriggerClientEvent('rdn_companions:removedog', _src)
			
		--end)
	elseif Config.Framework == "vorp" then
			local Character = VorpCore.getUser(_src).getUsedCharacter
			local u_identifier = Character.identifier
			local u_charid = Character.charIdentifier
		 exports.ghmattimysql:execute("DELETE FROM companions WHERE identifier = @identifier AND charidentifier = @charidentifier", {["identifier"] = u_identifier, ['charidentifier'] = u_charid})
		TriggerClientEvent('rdn_companions:removedog', _src)
			
	end 
end)


RegisterServerEvent('rdn_companions:feedPet')
AddEventHandler('rdn_companions:feedPet', function(xp)

        local _src = source
		
		if Config.Framework == "redem" then
	--TriggerEvent('redemrp:getPlayerFromId', _src, function(user)
		local user = RedEM.GetPlayer(_src)
        local u_identifier = user.getIdentifier()
        local u_charid = user.getSessionVar("charid")
		
		local currentXP = xp
		local newXp = currentXP + Config.XpPerFeed
	
		local ItemData = data.getItem(_src, Config.AnimalFood)
		local amount = ItemData.ItemAmount
		if amount >= 1 then
			if newXp < Config.FullGrownXp then

				ItemData.RemoveItem(1)

				local Parameters = { ['identifier'] = u_identifier, ['charidentifier'] = u_charid,  ['addedXp'] = Config.XpPerFeed }
				exports.oxmysql:execute("UPDATE companions SET xp = xp + @addedXp  WHERE identifier = @identifier AND charidentifier = @charidentifier", Parameters, function(result) end)

				--MySQL.Sync.execute("UPDATE companions SET xp = xp + @addedXp  WHERE identifier = @identifier AND charidentifier = @charidentifier", Parameters, function(result) end)		
				TriggerClientEvent('redem_roleplay:NotifyLeft',_src, "+"..Config.XpPerFeed.." Pet XP",newXp.."/"..Config.FullGrownXp.." XP" , "HUD_TOASTS", "toast_mp_status_change", 4000)
				TriggerClientEvent('rdn_companions:UpdateDogFed', _src, newXp)
			else
			
			ItemData.RemoveItem(1)
			
			TriggerClientEvent('rdn_companions:UpdateDogFed', _src, newXp)
			end	
		else
		 	--TriggerClientEvent( 'UI:DrawNotification', _src, _U('NoFood') )
			TriggerClientEvent('redem_roleplay:NotifyLeft',_src, _U('NoFood'), "", "menu_textures", "cross", 4000)
		end
	--end)
	elseif Config.Framework == 'vorp' then
		local Character = VorpCore.getUser(_src).getUsedCharacter
		local u_identifier = Character.identifier
		local u_charid = Character.charIdentifier		
		local currentXP = xp
		local newXp = currentXP + Config.XpPerFeed
		local amount = VorpInv.getItemCount(_src, Config.AnimalFood)
		if amount >= 1 then
			if newXp < Config.FullGrownXp then

				VorpInv.subItem(_src,Config.AnimalFood,1)

				 local Parameters = { ['identifier'] = u_identifier, ['charidentifier'] = u_charid,  ['addedXp'] = Config.XpPerFeed }
				exports.ghmattimysql:execute("UPDATE companions SET xp = xp + @addedXp  WHERE identifier = @identifier AND charidentifier = @charidentifier", Parameters, function(result) end)		
				--TriggerClientEvent('redem_roleplay:NotifyLeft',_src, "+"..Config.XpPerFeed.." Pet XP",newXp.."/"..Config.FullGrownXp.." XP" , "generic_textures", "tick", 8000)	
				TriggerClientEvent('UI:DrawNotification', _src, "+"..Config.XpPerFeed.." Pet XP Progress:"..newXp.."/"..Config.FullGrownXp.." XP")				
				TriggerClientEvent('rdn_companions:UpdateDogFed', _src, newXp)
			else			
			VorpInv.subItem(_src,Config.AnimalFood,1)		
			TriggerClientEvent('rdn_companions:UpdateDogFed', _src, newXp)
			end	
		else
		 TriggerClientEvent('UI:DrawNotification', _src, _U('NoFood'))
		end
	end
end)

RegisterServerEvent('rdn_companions:buydog')
AddEventHandler('rdn_companions:buydog', function(args)
    local src = source
    local userIdentifier, characterIdentifier, canTrack, money, price, model, skin

    if Config.Framework == 'redem' then
        local user = RedEM.GetPlayer(src)
        userIdentifier = user.getIdentifier()
        characterIdentifier = user.getSessionVar('charid')
        money = user.getMoney()
    elseif Config.Framework == 'vorp' then
        local character = VorpCore.getUser(src).getUsedCharacter
        userIdentifier = character.identifier
        characterIdentifier = character.charIdentifier
        money = character.money
    end

    canTrack = CanTrack(src)
    price = args['Price']
    model = args['Model']
    skin = math.floor(math.random(0, 2))

    if money <= price then
        --TriggerClientEvent('UI:DrawNotification', src, _U('NoMoney'))
		TriggerClientEvent('redem_roleplay:NotifyLeft',src, _U('NoMoney'), "", "menu_textures", "cross", 4000)
        return
    end

    local result = exports.oxmysql:fetchSync('SELECT * FROM companions WHERE identifier = @identifier AND charidentifier = @charidentifier', {
        ['identifier'] = userIdentifier,
        ['charidentifier'] = characterIdentifier
    })

    if #result > 0 then
        local parameters = {
            ['identifier'] = userIdentifier,
            ['charidentifier'] = characterIdentifier,
            ['dog'] = model,
            ['skin'] = skin,
            ['xp'] = 0
        }

        exports.oxmysql:execute('UPDATE companions SET dog = @dog, skin = @skin, xp = @xp WHERE identifier = @identifier AND charidentifier = @charidentifier', parameters, function(result)
            if Config.Framework == 'redem' then
				local user = RedEM.GetPlayer(src)
                user.removeMoney(price)
            elseif Config.Framework == 'vorp' then
                character.removeCurrency(0, price)
            end

            TriggerClientEvent('rdn_companions:spawndog', src, model, skin, true, 0, canTrack)
            --TriggerClientEvent('UI:DrawNotification', src, _U('ReplacePet'))
			TriggerClientEvent('redem_roleplay:NotifyLeft',src, _U('ReplacePet'), "", "menu_textures", "cross", 4000)
        end)
    else
        local parameters = {
            ['identifier'] = userIdentifier,
            ['charidentifier'] = characterIdentifier,
            ['dog'] = model,
            ['skin'] = skin,
            ['xp'] = 0
        }

        exports.oxmysql:insert('INSERT INTO companions ( `identifier`,`charidentifier`,`dog`,`skin`, `xp` ) VALUES ( @identifier,@charidentifier, @dog, @skin, @xp )', parameters, function(result)
            if Config.Framework == 'redem' then
				local user = RedEM.GetPlayer(src)
                user.removeMoney(price)
            elseif Config.Framework == 'vorp' then
                character.removeCurrency(0, price)
            end

            TriggerClientEvent('rdn_companions:spawndog', src, model, skin, true, 0, canTrack)
            --TriggerClientEvent('UI:DrawNotification', src, _U('NewPet'))
			TriggerClientEvent('redem_roleplay:NotifyLeft',src, _U('NewPet'), "", "menu_textures", "menu_icon_tick", 4000)
        end)
    end
end)

RegisterServerEvent('rdn_companions:loaddog')
AddEventHandler('rdn_companions:loaddog', function()
	local src = source
	local userIdentifier, characterIdentifier, canTrack

	if Config.Framework == 'redem' then
		userIdentifier = RedEM.GetPlayer(src).getIdentifier()
		characterIdentifier = RedEM.GetPlayer(src).getSessionVar('charid')
	elseif Config.Framework == 'vorp' then
		local character = VorpCore.getUser(src).getUsedCharacter
		userIdentifier = character.identifier
		characterIdentifier = character.charIdentifier
	end

	canTrack = CanTrack(src)

	local queryParameters = {
		['identifier'] = userIdentifier,
		['charidentifier'] = characterIdentifier,
	}

	if Config.Framework == 'redem' then
		local result = exports.oxmysql:fetchSync('SELECT * FROM companions WHERE identifier = @identifier AND charidentifier = @charidentifier', queryParameters)

		handleLoadDogResult(src, result, canTrack)
		--exports.oxmysql:executeSync('SELECT * FROM companions WHERE identifier = @identifier AND charidentifier = @charidentifier', queryParameters, function(result)
			--handleLoadDogResult(src, result, canTrack)
		--end)
	elseif Config.Framework == 'vorp' then
		exports.ghmattimysql:execute('SELECT * FROM companions WHERE identifier = @identifier AND charidentifier = @charidentifier', queryParameters, function(result)
			handleLoadDogResult(src, result, canTrack)
		end)
	end
end)

function handleLoadDogResult(src, result, canTrack)
	if result[1] then
		local dog = result[1].dog
		local skin = result[1].skin
		local xp = result[1].xp or 0
		TriggerClientEvent('rdn_companions:spawndog', src, dog, skin, false, xp, canTrack)
	else
		--TriggerClientEvent('UI:DrawNotification', src, _U('NoPet'))
		TriggerClientEvent('redem_roleplay:NotifyLeft',src, _U('NoPet'), "", "menu_textures", "cross", 4000)
	end
end


function CanTrack(source)
	local cb = false
	if Config.TrackCommand then
		if Config.AnimalTrackingJobOnly then
			local job = getJob(source)
			for k, v in pairs(Config.AnimalTrackingJobs) do
				if job == v then
				cb = true
				end
			end
		else 
			cb = true
		end
	end
	return(cb)
end


function getJob(source)
 local cb = false
 
	 if Config.Framework == "redem" then
		--TriggerEvent('redemrp:getPlayerFromId', source, function(user)
			local user = RedEM.GetPlayer(source)
			cb = user.getJob() 
		--end)	
	 elseif Config.Framework == "vorp" then
		local Character = VorpCore.getUser(source).getUsedCharacter
		cb = Character.job
	 end
	 
 return cb
end
