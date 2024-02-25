
local p = {}

local skinData  = mw.loadData('Module:SkinData/data')
local themes    = require('Module:SkinThemes')
local lib       = require('Module:Feature')
local color     = require('Module:Color')
local FN        = require('Module:Filename')
local IL        = require('Module:ImageLink')
local userError = require('Dev:User error')
local builder   = require("Module:SimpleHTMLBuilder")

local function getSkins(champion, skin)
	return skinData[champion] and skinData[champion].skins and skinData[champion].skins[skin or "Original"] or {}
end

function skinIter(t)
    local keys = {}
    for k in pairs(t) do
        if t[k]['id'] ~= nil then
            keys[#keys+1] = k
        end
    end

    table.sort(keys, function(a,b)
        return (t[a]['custom_sort_id'] or t[a]['id']) < (t[b]['custom_sort_id'] or t[b]['id'])
    end)

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]], i
        end
    end
end

function p.skinscount(frame)
	local function orderup(a,b)
	    if type(a) == type(b) then 
	        return b > a 
	    end
	    
	    if type(a) == "string" then
	    	return false
	    end

	    return true 
	end

	local s					= builder.create()
	local prices			= {count = 0}
    local resulttable		= {total = 0, cost = 0}

    for championname in pairs(skinData) do
        local t = skinData[championname]["skins"]

        for skinname, sdata in pairs(t) do
            if skinname ~= "Original" and sdata["availability"] ~= "Upcoming" and sdata["availability"] ~= "Canceled" and sdata["availability"] ~= "Removed" then
            	local price
            	local price_accepted

                if sdata["availability"] == "Limited" then
                    price = "Limited"
                    price_accepted = true
                elseif sdata["looteligible"] == false then
                    price = "Rare"
                    price_accepted = true
                else
                	price = sdata["cost"]
                	price_accepted = false
            	end

                if resulttable[price] == nil then
                	if price_accepted == false and price ~= "Special" and type(price) == "string" then
                		return userError("Price '" .. price .. "' is not accepted for '" .. (
                				sdata["formatname"] or 
                				lib.ternary(skinname == "Original", championname, skinname .. " " .. championname)
                			) .. ". Either update this function or check that the data is correctly inputted", "LuaError"
                		)
                	end

                    resulttable[price] = 0
                    prices.count = prices.count + 1
                    prices[prices.count] = price
                end

                resulttable[price] = resulttable[price] + 1
                resulttable.total = resulttable.total + 1
                
                if type(price) ~= "string" then
                	resulttable.cost = resulttable.cost + price
                end
            end
        end
    end

    table.sort(prices, orderup)
    
    s:wikitext("This table is automatically generated based on the data from " ..
    	"[https://leagueoflegends.fandom.com/wiki/Module:SkinData/data?action=edit Module:SkinData/data].")
    s:newline()

    local sdtable = s:tag("table")
    sdtable
    	:addClass("wikitable sortable")
    	:tag("tr")
	    	:tag("th")
	    		:wikitext("Price")
	    		:done()
	    	:tag("th")
	    		:wikitext("Count")
	    		:done()
	    	:done()

    for i = 1, prices.count do
    	local price = prices[i]

    	sdtable
    		:tag("tr")
    			:tag("td")
    				:css("text-align", "right")
    				:wikitext(price)
    				:done()
    			:tag("td")
    				:css("text-align", "right")
    				:wikitext(resulttable[price])
    				:done()
				:done()
    end
    
    sdtable:done()
    s:newline()
    s:wikitext(frame:preprocess('Total: ' .. resulttable.total ..' skins (Total: ' .. resulttable.cost .. ' RP). Skins not found inside [[Hextech Chest]]s are considered rare, and are not placed in the final RP calculation. This includes skins below {{RP|520 RP}}. Upcoming skins are not counted.'))
    
    return tostring(s)
end

function p.splashartistpage()
    local searchstring = mw.title.getCurrentTitle().text

    local championtable = {}
    for championname in pairs(skinData) do
        table.insert(championtable, championname)
    end
    table.sort(championtable)

    local resulttable = {}
    for _, championname in pairs(championtable) do
        local skintable  = {}
        for championname in pairs(skinData[championname]["skins"]) do
            table.insert(skintable, championname)
        end
        table.sort(skintable)

        for _, skinname in pairs(skintable) do
            local t = skinData[championname]["skins"][skinname]
            
            if t.splashartist ~= nil then
                for _, splashartistname in pairs(t.splashartist) do
                    if splashartistname == searchstring then
                        table.insert(resulttable, {championname, skinname, t.formatname, t.splashartist})
                    end
                end
            end
        end
    end
    
    if #resulttable == 0 then
        return userError("No results for " .. searchstring, "LuaError")
    end
    
    -- Three random images of work examples
    math.randomseed(os.time())
    local hash = {}
    local rnd  = 0
    local s1   = ""
    
    for i = 1, 3 do
        rnd = math.random(#resulttable)
        if hash[rnd] ~= true then
            s1 = s1 .. "[[File:" .. FN.skin({resulttable[rnd][1], resulttable[rnd][2]}) .. "|thumb|200px|Work example.]]"
        end
        hash[rnd] = true
    end
    
    -- Splash Art list
    local s2 = "<dl><dt>Splash Art</dt></dl><ul><li>"
    local tempval = ""
    for i, val in pairs(resulttable) do
        local championname = val[1]
        local skinname     = val[2]
        local formatname   = val[3]
        local splashartist = val[4]
        
        if tempval == championname then
            s2 = s2 .. ", "
        else
            if i ~= 1 then
                s2 = s2 .. "</li><li>"
            end
            tempval = championname
        end
        s2 = s2 .. tostring(IL.skin{
            ["champion"] = championname,
            ["skin"] = skinname,
            ["link"] = championname .. "/Skins",
            ["text"] = lib.ternary(formatname, formatname, skinname .. " " .. championname),
            ["circle"] = "true"
        })
        
        count = 0
        for i, val in pairs (splashartist) do
            if val ~= searchstring then
                if count == 0 then
                    s2 = s2 .. " <small>(Collaboration with "
                else
                    s2 = s2 .. ", "
                end
                s2 = s2 .. splashartist[i]
                count = count + 1
            end
        end
        if count ~= 0 then
            s2 = s2 .. ")</small>"
        end
    end
    s2 = s2 .. "</li></ul>"
    
    return s1 .. s2
end

function p.chromapartner(frame)
    local s = ''
    
    s = s .. '<div id="chromaexhibition" style="position:relative">'
    s = s .. '<b>Partner Program Chromas</b>'
    s = s .. '<div class="chroma-gallery" style="width:718px; text-align:center"><div class="base">[[File:Partner Program LoL Logo.png|150px]]</div>'
    
    local championtable = {}
    for x in pairs(skinData) do
        table.insert(championtable, x)
    end
    table.sort(championtable)
    
    local resulttable = {}
    for _, championname in pairs(championtable) do
        local skintable  = {}
        for championname in pairs(skinData[championname]["skins"]) do
            table.insert(skintable, championname)
        end
        table.sort(skintable)
 
        for _, skinname in pairs(skintable) do
            local chromatable = {}
            local t           = skinData[championname]["skins"][skinname]
            local formatname  = t.formatname
            
            if t.chromas ~= nil then
                t = t.chromas
                for chromaname in pairs(t) do
                    if t[chromaname].distribution == "Partner Program" then
                        s = s .. '<div class="skin-icon" data-game="lol" data-champion="' .. championname .. '" data-skin="' .. skinname .. '"><div class="chroma partner-border">[[File:' .. FN.chroma({championname, skinname, chromaname}) .. '|100px|border|link=]]</div> <div class="chroma-caption">[[File:' .. FN.championcircle({championname, skinname}) .. '|20px|link=' .. championname .. ']] [[' .. championname .. '|' .. lib.ternary(formatname, formatname, skinname .. ' ' .. championname) .. ']]</div></div>'
                    end
                    
                end
            end
        end
    end
    s = s .. '</div>'
    
    return s
end

function p.chromagallery(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2] or "Original"
    args['variant']  =					args['variant']  or args[3] or nil
    args['fullgallery'] =				args['fullgallery'] or false
    
    local t = skinData[args['champion']] and skinData[args['champion']].skins[args['skin']]
    if t == nil or t.chromas == nil then
        return userError("No chromas specified for skin ''" .. args['skin'] .. "'' in Module:SkinData/data", "LuaError")
    end
    t = t.chromas
    
    local header = "Chromas"
    local headerpre = ""
    if args['variant'] then
        headerpre = "Old "
    end
    local frame = mw.getCurrentFrame()
    
    if skinData[args['champion']].skins[args['skin']].forms ~= nil then
        header = "forms"
    end
    
    local chromatable  = {}
    local chromastring = args['chromas'] or "true"
    if chromastring == "true" then
        for chromaname in pairs(t) do
            table.insert(chromatable, chromaname)
        end
    else
        chromatable = lib.split(chromastring, ",", true)
    end
    table.sort(chromatable)
    
    local formatname = skinData[args['champion']].skins[args['skin']].formatname
    local key        = args["key"] or "true" 
    local imagewidth = "100px"
    local s = ''
    s = s .. '<div id="chromaexhibition" style="position:relative"><b>' .. headerpre .. lib.ternary(formatname, formatname, args['skin'] .. " " .. args['champion']) .. " " .. header .. "</b>"
    
    if key == "true" then
        s = s .. "<div class='glossary' data-game='lol' data-tip='Chroma exhibition' style='position:absolute; top:5px; right: 5px; z-index:20;'>[[File:Information.svg|30px|link=]]</div>"
    end
    
    if #chromatable > 8 then
        imagewidth = "80px"
        s = s .. '<div class="chroma-gallery-large" style="width:718px; text-align:center">'
    else
        s = s .. '<div class="chroma-gallery" style="width:718px; text-align:center">'
    end
    
    s = s .. '<div class="base">[[File:' .. FN.chroma({args['champion'], args['skin'], "Base", args['variant']}) .. '|183px]]</div>'
    
    for i, chromaname in pairs(chromatable) do

    	if not args['variant'] or args['fullgallery'] or mw.title.new('File:'..FN.chroma({args['champion'], args['skin'], chromaname, args['variant']})).fileExists then --only added if the file exists!
	        if skinData[args['champion']].skins[args['skin']].chromas[chromaname] == nil then
	            return userError("Chroma ''" .. chromaname .. "'' not specified in Module:SkinData/data for " .. lib.ternary(formatname, formatname, args['skin'] .. " " .. args['champion']), "LuaError")
	        end
	        
	        local availability = skinData[args['champion']].skins[args['skin']].chromas[chromaname].availability or "Available"
	        
	        if availability ~= "Canceled" then
	            s = s .. "<div><div class='chroma " .. string.lower(availability) .. "-border'>[[File:" .. FN.chroma({args['champion'], args['skin'], chromaname, args['variant']}) .. "|" .. imagewidth .. "|border]]</div> <div class='chroma-caption' title='" .. skinData[args['champion']].skins[args['skin']].chromas[chromaname].id .. "'>" .. chromaname .. "</div></div>"
	        end
		end
    end
    
    s = s .. '</div></div>'
    
    return frame:preprocess(s)
end

function p.skinpage(frame)
    local args = lib.frameArguments(frame)
    
    args[1] = args['champion'] or args[1] or mw.title.getCurrentTitle().rootText
    args['champion'] = lib.validateName(args[1])
    
    if skinData[args['champion']] == nil then
        return userError("Champion ''" .. args['champion'] .. "'' does not exist in Module:SkinData/data", "LuaError")
    end
    
    local t = skinData[args['champion']]["skins"]
    
    local availabletable = {}
    local legacytable    = {}
    local limitedtable   = {}
    local upcomingtable  = {}
    local canceledtable  = {}

    for skinname in pairs(t) do
        if t[skinname].availability == "Available" then
            table.insert(availabletable, {skinname, t[skinname]})
        end
        if t[skinname].availability == "Legacy" then
            table.insert(legacytable,    {skinname, t[skinname]})
        end
        if t[skinname].availability == "Limited" or t[skinname].availability == "Rare" then
            table.insert(limitedtable,   {skinname, t[skinname]})
        end
        if t[skinname].availability == "Upcoming" then
            table.insert(upcomingtable,  {skinname, t[skinname]})
        end
        if t[skinname].availability == "Canceled" then
            table.insert(canceledtable,  {skinname, t[skinname]})
        end
    end
    
    -- generates all categories of all sets of all skins of said champion
    local k = ""
    for skinname in pairs(t) do
        k = k..(themes.getsetcategory{['s_type']		= 'skin',['arguments']	= {['champion'] = args['champion'], ['skin'] = skinname},['output']		= 'category'} or '')

    end
    k = "[[Category:LoL Champion cosmetics]][[Category:"..args[1].."]]"..k

    function skinitem(data)
        local lang = mw.language.new("en")
        local skinname     = data[1]
        local formatname   = data[2].formatname or skinname .. ' ' .. args['champion']
        local champid      = skinData[args['champion']]["id"]
        local skinid       = data[2].id
        local cost         = data[2].cost
        local release      = data[2].release
        local distribution = data[2].distribution
        
        if release ~= "N/A" then
            release  = lang:formatDate("d-M-Y", data[2].release)
        end

        local s = ""
        
        s = s .. '<div style="display:inline-block; margin:5px; width:342px"><div class="skin-icon" data-game="lol" data-champion="' .. args['champion'] .. '" data-skin="' .. skinname .. '">[[File:' .. FN.skin({args['champion'], skinname}) .. '|340px|border]]</div><div><div style="float:left">' .. formatname
        
        if skinid ~= nil then
            standardizedname = string.lower(args['champion']:gsub("[' ]", ""))
            if standardizedname == "wukong" then
                standardizedname = "monkeyking"
            end
            s = s .. ' <span class="plainlinks">[https://www.modelviewer.lol/model-viewer?id=' .. champid .. string.format("%03d", skinid).. ' <span class="button" title="View in 3D" style="text-align:center; border-radius: 2px;"><b>View in 3D</b></span>]</span>'
        end
        
        s = s .. '</div><div style="float:right">'
        
        if cost == 'N/A' then
            -- skip
        elseif cost == 150000 then
            s = s .. tostring(IL.basic{["link"] = "Blue Essence", ["text"] = cost, ["alttext"] = cost .. " Blue Essence", ["image"] = "BE icon.png", ["border"] = "false", ["labellink"] = "false"}) .. ' / ' 
        elseif cost == 100 then
            s = s .. tostring(IL.basic{["link"] = "Prestige Point", ["text"] = cost, ["alttext"] = cost .. " Prestige Points", ["image"] = "Hextech Crafting Prestige token.png", ["border"] = "false", ["labellink"] = "false"}) .. ' / ' 
        elseif cost == 10 then
            s = s .. tostring(IL.basic{["link"] = "Gemstone", ["text"] = cost, ["alttext"] = cost .. " Rare Gems", ["image"] = "Rare Gem.png", ["border"] = "false", ["labellink"] = "false"}) .. ' / ' 
        elseif cost == "special" then
            s = s .. "Special pricing" .. ' / ' 
        else
            s = s .. tostring(IL.basic{["link"] = "Riot Points", ["text"] = cost, ["alttext"] = cost .. " RP", ["image"] = "RP icon.png", ["border"] = "false", ["labellink"] = "false"}) .. ' / ' 
        end
        
        s = s .. lib.ternary(release == 'N/A', 'N/A', release) .. '  </div></div></div>'
		s = s..k
		
        return s
    end

    function chroma(chromatable)
        s = ""
        if #chromatable > 0 then
            for i in ipairs(chromatable) do
                s = s .. '<div style="clear:both"></div>' .. p.chromagallery{args['champion'], chromatable[i]}
            end
        end
        return s
    end
    
    function comp(a, b)
        local a = a[2].id or -1
        local b = b[2].id or -1
        
        if a < b then
            return true
        end
    end
    
    local skintable = {
            {availabletable, text = 'Available'},
            {legacytable,    text = 'Legacy Vault'},
            {limitedtable,   text = 'Rare & Limited'},
            {upcomingtable,  text = 'Upcoming'},
            {canceledtable,  text = 'Canceled'}
        }
    local s = ''
    for i, value in ipairs(skintable) do
        table.sort(skintable[i][1], comp)
        local chromatable = {}
        if #value[1] > 0 then
            s = s .. ('<div style="clear:both"></div>\n==' .. value.text .. '==\n<div style="font-size:small">')
            for i in pairs(value[1]) do
                s = s .. skinitem(value[1][i])
                if value[1][i][2].chromas then
                    table.insert(chromatable, value[1][i][1])
                end
            end
            s = s .. '</div>'
            table.sort(chromatable)
            
            s = s .. chroma(chromatable)
        end
    end
    
    s = s .. '<div style="clear:both"></div>'
    return s
end

function p.skintabber(frame)
    local args = lib.frameArguments(frame)
    local champname = lib.validateName(args['champion'] or args[1] or mw.title.getCurrentTitle().rootText)
    if skinData[champname] == nil then
        return userError("Champion ''" .. champname .. "'' does not exist in the Module:SkinData/data", "LuaError")
    end
    
    local lualinkData   	= mw.loadData('Module:SkinData/setlinks')
    local set_to_universe   = require("Module:SkinThemes").getSetToUniverse()

    local champid = skinData[champname]["id"]

    local t = skinData[champname]["skins"]
    local standardizedname = string.lower(champname:gsub("[' ]", ""))
        if standardizedname == "wukong" then
            standardizedname = "monkeyking"
        end
    
    local container = builder.create('div'):addClass('lazyimg-wrapper')
    local navContainer = builder.create('div')
        :addClass('skinviewer-nav')
        :addClass('hidden')
        :css({
            ['display'] = 'flex',
            ['justify-content'] = 'center',
            ['margin-bottom'] = '10px',
            ['flex-wrap'] = 'wrap',
        })
    local tabContainer = builder.create('div'):addClass('skinviewer-tab-container')
    
    for k,v,i in skinIter(t) do
        local releaseSplit = mw.text.split(v['release'], '%D')
        local cost
        if type(v['cost']) ~= 'number' then
            cost = '<div class="skinviewer-price" style="flex 1 1 0px; text-align:center;" title="'.. (v['distribution'] and v['distribution'] or 'This skin can only be obtained in a special way.') ..'">Special</div>'
        elseif v['cost'] == 10 then
            cost = '<div class="skinviewer-price" style="flex 1 1 0px; text-align:center;" title="This skin is forged from Rare Gemstones in the Hextech workshop.">[[File:Rare Gem.png|20px|Gemstone]] 10</div>'
        elseif v['cost'] == 100 then
            cost = '<div class="skinviewer-price" style="flex 1 1 0px; text-align:center;" title="This skin is purchased from the Prestige Point Shop, which is accessed in the Hextech workshop.">[[File:Hextech Crafting Prestige token.png|20px|Prestige Point]] 100</div>'
        elseif v['cost'] == 150000 then
            cost = '<div class="skinviewer-price" style="flex 1 1 0px; text-align:center;" title="This skin is available to purchase with Blue Essence during an Essence Emporium.">[[File:BE icon.png|20px|Blue Essence]] 150000)</div>' 
        else
            cost = '<div class="skinviewer-price" title="This skin is available to purchase with RP from the store.">[[File:RP icon.png|20px|RP]] '.. v["cost"] ..'</div>'
        end
        
        
        local set

        if v['set'] ~= nil then
        	set = v.set[1]
	    end

        navContainer
            :tag('span')
                :attr('data-id', i)
                :addClass('skinviewer-show')
                :css({
                    ['position'] = 'relative',
                    ['width'] = '52px',
                    ['height'] = '52px'
                })
                :wikitext(v['chromas'] and '[[File:Chromas available.png|x52px||link=]]' or '')
                :tag('span')
                    :css({
                        ['position'] = 'absolute',
                        ['top'] = 0,
                        ['left'] = 0,
                        ['right'] = 0,
                        ['bottom'] = 0,
                        ['z-index'] = 100,
                        ['padding'] = '2px',
                        ['cursor'] = 'pointer'
                    })
                    :attr('title', k)
                    :wikitext('[[File:' .. FN.championcircle({champname, k}) .. '|x48px|link=' .. ']]')
                    :done()
                :done()
        tabContainer
            :tag('div')
                :addClass('skinviewer-tab-content')
                :addClass(i==1 and 'skinviewer-active-tab' or '')
                :attr('data-id', 'item-'..i)
                :css('display', i~=1 and 'none' or 'block')
                :tag('div')
                    :addClass('skinviewer-tab-skin')
                    :css('position', 'relative')
                    :css('font-family', 'BeaufortLoL')
                    :wikitext('<div class="FullWidthImage" style="max-width:1240px;margin-left:auto;margin-right:auto;">[[File:' .. FN.skin({ champname, k }) .. ']]</div>')
                    :tag('div')
                        :css({
                            ['position'] = 'absolute',
                            ['bottom'] = 0,
                            ['left'] = 0,
                            ['right'] = 0,
                            ['z-index'] = '100',
                            ['display'] = 'flex',
                            ['justify-content'] = 'space-between',
                            ['align-items'] = 'flex-end',
                            ['background-color'] = 'rgba(0,0,0,0.6)',
                            ['border-top'] = '1px solid rgba(0,0,0,0.25)',
                            ['border-left'] = '1px solid rgba(0,0,0,0.25)',
                            ['border-right'] = '1px solid rgba(0,0,0,0.25)',
                            ['border-radius'] = '6px 6px 0 0',
                            ['height'] = '24px',
                            ['line-height'] = '24px',
                            ['font-size'] = '20px'
                        })
                        :tag('div')
                            :css({
                                ['flex'] = '4 1 0px',
                                ['text-align'] = 'center',
                                ['color'] = '#d3c7aa',
                                ['font-weight'] = 700
                            })
                            :wikitext('<span title="'.. (v['id']) ..'">' ..(k).. '</span>')
                            :done()
                        :tag('div')
                            :css({
                                ['flex'] = '1 1 0px',
                                ['text-align'] = 'center'
                            })
                            :wikitext('<span class="plainlinks">[https://www.modelviewer.lol/model-viewer?id=' .. champid .. string.format("%03d", v['id'] or 0) ..' <span class="button" title="View in 3D" style="text-align:center; border-radius: 2px;"><b>View in 3D</b></span>]</span>')
                            :done()
                    	:wikitext(cost)
                        :tag('div')
                            :css({
                                ['flex'] = '1 1 0px',
                                ['text-align'] = 'center',
                                ['color'] = '#c9aa71',
                                ['font-size'] = 'smaller',
                                ['padding-right'] = '2px'
                            })
                            :wikitext(mw.ustring.format('%s.%s.%s', releaseSplit[3], releaseSplit[2], releaseSplit[1]))
                            :done()
                        :done()
                    :done()
                :tag('div')
                    :addClass('skinviewer-info')
                    :css({
                        ['padding'] = '15px',
                        ['background-color'] = 'rgba(0, 0, 0, 0.1)',
                        ['font-family'] = 'BeaufortLoL',
                        ['font-size'] = '14px'
                    })
                        :tag('div')
                            :addClass('skinviewer-info-lore')
                            :wikitext(lib.ternary(v['lore'], '<div style="line-height: 1.6em; text-align: center; font-size: 15px;">' .. tostring(v['lore']) .. '</div><div>[[File:Separator.png|400px|center|link=]]</div>', ''))
                            :done()
                        :tag('div')
                            :addClass('skinviewer-info-kleine-bilder')
                            :css({
                                ['display'] = 'flex',
                                ['justify-content'] = 'center'
                            })
                            :wikitext(lib.ternary(p.getVoiceactor{champname, k} ~= nil, '<div style="padding-right:1em; text-align:center;">[[File:Actor.png|20px|link=]]' .. tostring(p.getVoiceactor{champname, k}) .. '</div>', ''))
                            :wikitext(lib.ternary(p.getSplashartist{champname, k} ~= nil, '<div style="padding-right:1em; text-align:center;">[[File:Artist.png|20px|link=]]' .. tostring(p.getSplashartist{champname, k}) .. '</div>', ''))
                            :wikitext(set and ('<div style="padding-right:1em; text-align:center;">[[File:Set piece.png|20px|link=]] '.. 
                            			require("Module:SkinThemes").getThemeLink(set, lualinkData, set_to_universe) .. '</div>') or "")
                            :wikitext(lib.ternary(v['looteligible'] ~= false, '<div style="padding-right:1em; text-align:center;">[[File:Loot eligible.png|20px|link=]] Loot eligible</div>', ''))
                            :wikitext(lib.ternary(v['looteligible'] == false, '<div style="padding-right:1em; text-align:center;">[[File:Loot ineligible.png|20px|link=]] Loot inelgible</div>', ''))
                            :done()
                        :tag('div')
                            :addClass('skinviewer-info-grosse-bilder')
                            :css({
                                ['display'] = 'flex',
                                ['justify-content'] = 'center',
                                ['padding-top'] = '5px'
                            })
                            :wikitext(v['availability'] == 'Limitiert' and '<div style="padding:0 1em; text-align:center;"><div class="skin-viewer-text-icon">[[File:Limited skin.png|50px|link=]]</div><div class="skin-viewer-text-icon">Limited Edition</div></div>' or (v['availability'] == 'Legacy' and '<div style="padding:0 1em; text-align:center;"><div class="skin-viewer-text-icon">[[File:Legacy skin.png|50px|link=]]</div><div class="skin-viewer-text-icon">Legacy</div></div>' or ''))
                            :wikitext(lib.ternary(v['filter'], '<div style="padding:0 1em; text-align:center;"><div class="skin-viewer-text-icon">[[File:Voice filter.png|50px|link=]]</div><div class="skin-viewer-text-icon">Voice filter</div></div>', ''))
                            :wikitext(lib.ternary(v['newquotes'], '<div style="padding:0 1em; text-align:center;"><div class="skin-viewer-text-icon">[[File:Additional quotes.png|50px|link=]]</div><div class="skin-viewer-text-icon">Additional/unique quotes</div></div>', ''))
                            :wikitext(lib.ternary(v['newvoice'], '<div style="padding:0 1em; text-align:center;"><div class="skin-viewer-text-icon">[[File:New voice.png|50px|link=]]</div><div class="skin-viewer-text-icon">New voiceover</div></div>', ''))
                            :wikitext(lib.ternary(v['neweffects'], '<div style="padding:0 1em; text-align:center;"><div class="skin-viewer-text-icon">[[File:New effects.png|50px|link=]]</div><div class="skin-viewer-text-icon">New SFX/VFX</div></div>', ''))
                            :wikitext(lib.ternary(v['newanimations'], '<div style="padding:0 1em; text-align:center;"><div class="skin-viewer-text-icon">[[File:New animations.png|50px|link=]]</div><div class="skin-viewer-text-icon">New Animations/Recall</div></div>', ''))
                            :wikitext(lib.ternary(v['transforming'], '<div style="padding:0 1em; text-align:center;"><div class="skin-viewer-text-icon">[[File:Transforming.png|50px|link=]]</div><div class="skin-viewer-text-icon">Transforming</div></div>', ''))
                            :wikitext(lib.ternary(v['extras'], '<div style="padding:0 1em; text-align:center;"><div class="skin-viewer-text-icon">[[File:Includes extras.png|50px|link=]]</div><div class="skin-viewer-text-icon">Includes Extras</div></div>', ''))
                            :wikitext(lib.ternary(v['chromas'], '<div style="padding:0 1em; text-align:center;"><div class="skin-viewer-text-icon">[[File:Chromas available.png|50px|link=]]</div><div class="skin-viewer-text-icon">Chromas</div></div>', ''))
                            :done()
                        :tag('div')
                            :addClass('skinviewer-info-variantof')
                            :css('text-align', 'center')
                            :wikitext(lib.ternary(p.getVariant{champname, k} ~= nil, '<div>This skin is a variant of  ' .. tostring(IL.skin{champion = champname, skin = p.getVariant{champname, k}, circle = "true", link = '*none*', text = p.getVariant{champname, k}}) .. '. Store variants are discounted for multiple purchases.</div>', ''))
                            :done()
                    :done()
                :tag('div')
                    :addClass('skinviewer-tab-chroma')
                    :wikitext(v['chromas'] and p.chromagallery{champname, k} or '')
                    :done()
    end
    
    return container:node(navContainer):node(tabContainer)
    
end

function p.skingallery(frame)
    local args = lib.frameArguments(frame)
    
    args['champion'] = args['champion'] or args[1] or mw.title.getCurrentTitle().rootText
    
    local t = skinData[args['champion']]["skins"]
    
    local availabletable = {}
    local legacytable    = {}
    local limitedtable   = {}
    local upcomingtable  = {}
    local canceledtable  = {}

    for skinname in pairs(t) do
        if t[skinname].availability ~= "Canceled" then
            table.insert(availabletable, {skinname, t[skinname]})
        end
    end

    function skinitem(data)
        local lang = mw.language.new("en")
        local skinname     = data[1]
        local formatname   = data[2].formatname or skinname .. ' ' .. args['champion']
        local champid      = skinData[args['champion']]["id"]
        local skinid       = data[2].id
        local cost         = data[2].cost
        local release      = data[2].release
        local distribution = data[2].distribution
        
        if release ~= "N/A" then
            release  = lang:formatDate("d-M-Y", data[2].release)
        end

        local s = ""
        
        s = s .. '<div style="display:inline-block; margin:5px; width:342px"><div class="skin-icon" data-game="lol" data-champion="' .. args['champion'] .. '" data-skin="' .. skinname .. '">[[File:' .. FN.loading({args['champion'], skinname}) .. '|150px|border]]</div><div><div style="float:left">' .. formatname
        
        if skinid ~= nil then
            standardizedname = string.lower(args['champion']:gsub("[' ]", ""))
            if standardizedname == "wukong" then
                standardizedname = "monkeyking"
            end
            s = s .. ' <span class="plainlinks">[https://www.modelviewer.lol/model-viewer?id=' .. skinData[args['champion']]["id"] .. string.format("%03d", skinid or 0) .. ' <span class="button" title="View in 3D" style="text-align:center; border-radius: 2px;"><b>View in 3D</b></span>]</span>'
        end
        
        s = s .. '</div><div style="float:right">'
        
        if cost == 'N/A' then
            -- skip
        elseif cost == 150000 then
            s = s .. tostring(IL.basic{["link"] = "Blue Essence", ["text"] = cost, ["alttext"] = cost .. " Blue Essence", ["image"] = "BE icon.png", ["border"] = "false", ["labellink"] = "false"}) .. ' / ' 
        elseif cost == 100 then
            s = s .. tostring(IL.basic{["link"] = "Prestige Point", ["text"] = cost, ["alttext"] = cost .. " Prestige Points", ["image"] = "Hextech Crafting Prestige token.png", ["border"] = "false", ["labellink"] = "false"}) .. ' / ' 
        elseif cost == 10 then
            s = s .. tostring(IL.basic{["link"] = "Gemstone", ["text"] = cost, ["alttext"] = cost .. " Rare Gems", ["image"] = "Rare Gem.png", ["border"] = "false", ["labellink"] = "false"}) .. ' / ' 
        elseif cost == "special" then
            s = s .. "Special pricing" .. ' / ' 
        else
            s = s .. tostring(IL.basic{["link"] = "Riot Points", ["text"] = cost, ["alttext"] = cost .. " RP", ["image"] = "RP icon.png", ["border"] = "false", ["labellink"] = "false"}) .. ' / ' 
        end
        
        s = s .. lib.ternary(release == 'N/A', 'N/A', release) .. '  </div></div></div>'

        return s
    end

    function chroma(chromatable)
        s = ""
        if #chromatable > 0 then
            for i in ipairs(chromatable) do
                s = s .. '<div style="clear:both"></div>' .. p.chromagallery{args['champion'], chromatable[i]}
            end
        end
        return s
    end
    
    function comp(a, b)
        local a = a[2].id or -1
        local b = b[2].id or -1
        
        if a < b then
            return true
        end
    end
    
    local skintable = {
            {availabletable, text = 'Available'},
            {legacytable,    text = 'Legacy Vault'},
            {limitedtable,   text = 'Rare & Limited'},
            {upcomingtable,  text = 'Upcoming'},
            {canceledtable,  text = 'Canceled'}
        }
    local s = ''
    for i, value in ipairs(skintable) do
        table.sort(skintable[i][1], comp)
        local chromatable = {}
        if #value[1] > 0 then
            s = s .. ('<div style="clear:both"></div>\n==' .. value.text .. '==\n<div style="font-size:small">')
            for i in pairs(value[1]) do
                s = s .. skinitem(value[1][i])
                if value[1][i][2].chromas then
                    table.insert(chromatable, value[1][i][1])
                end
            end
            s = s .. '</div>'
            table.sort(chromatable)
            
            s = s .. chroma(chromatable)
        end
    end
    
    s = s .. '<div style="clear:both"></div>'
    return s
end

function p.getAllchampionskins(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])

    return skinData[args['champion']]
end

function p.getChampionskin(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    return getSkins(args['champion'], args['skin'])
end

function p.getFormatname(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    return getSkins(args['champion'], args['skin']).formatname
end

function p.getAvailability(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    return getSkins(args['champion'], args['skin']).availability
end

function p.getDistribution(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    return getSkins(args['champion'], args['skin']).distribution
end

function p.getCost(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    return getSkins(args['champion'], args['skin']).cost
end

function p.getRelease(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    return getSkins(args['champion'], args['skin']).release
end

function p.getRetired(frame)
    local args = lib.frameArguments(frame)
    
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    return getSkins(args['champion'], args['skin']).retired
end

function p.getEarlysale(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    return getSkins(args['champion'], args['skin']).earlysale
end

function p.getSet(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    local t = getSkins(args['champion'], args['skin']).set
    
    if t == nil then
        return nil
    end
    
    for i, setname in ipairs(t) do
        if i ~= 1 then
            s = s .. ", " .. setname:gsub("% ", "&nbsp;")
        else
            s = setname
        end
    end

    return s
end

function p.getSetlist(frame)
    local championtable = {}
    local sets = {}
    local hash = {}
    local setList = builder.create('ul')
    
    setList:newline()
    
    for x in pairs(skinData) do
        table.insert(championtable, x)
    end
    table.sort(championtable)

    for _, championname in pairs(championtable) do
        local skintable  = {}
        for championname in pairs(skinData[championname]["skins"]) do
            table.insert(skintable, championname)
        end
        table.sort(skintable)

        for _, skinname in pairs(skintable) do
            local t = skinData[championname]["skins"][skinname]
            
            if t.set ~= nil then
                for _, value in pairs(t.set) do
                    if (not hash[value]) then
                        table.insert(sets, value)
                        hash[value] = true
                    end
                end
            end
        end
    end
    table.sort(sets)
    
    for _, setname in pairs(sets) do
        setList
            :tag('li')
                :wikitext('[[' .. setname .. ' (Collection)]]')
                :done()
            :newline()
    end
 
    return setList
end

function p.getSetskins(frame)
    local args = lib.frameArguments(frame)
 
    local skinList = builder.create('ul')
    local championtable = {}
    local result = false
    
    skinList:newline()
    
    for x in pairs(skinData) do
        table.insert(championtable, x)
    end
    table.sort(championtable)
 
    for _, championname in pairs(championtable) do
        local skintable  = {}
        
        for championname in pairs(skinData[championname]["skins"]) do
            table.insert(skintable, championname)
        end
        table.sort(skintable)
        
        for _, skinname in pairs(skintable) do
            local hit = false
            local t = skinData[championname]["skins"][skinname]
            
            if t.set ~= nil then
                for _, subset in pairs(t.set) do
                    if subset == args[1] then
                        hit = true
                        result = true
                    end
                end
            end
            if hit == true then
                skinList
                    :tag('li')
                        :tag('div')
                            :addClass('skin-icon')
                            :attr('data-champion', championname)
                            :attr('data-skin', skinname)
                            :attr('data-game', "lol")
                            :wikitext('[[File:' .. FN.championcircle({championname, skinname}) .. '|20px|link=' .. championname .. ']] [[' .. championname .. '|' .. lib.ternary(t["formatname"] ~= nil, t["formatname"], skinname .. " " .. championname) .. ']]')
                        :done()
                    :done()
                    :newline()
            end
        end
    end

    if result == false then 
        skinList
            :tag('li')
                :wikitext('No match found for ' .. args[1] .. '.')
            :done()
            :newline()
    end
 
    return skinList
end

function p.getNeweffects(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    return getSkins(args['champion'], args['skin']).neweffects
end

function p.getNewrecall(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    return getSkins(args['champion'], args['skin']).newrecall
end

function p.getNewanimations(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    return getSkins(args['champion'], args['skin']).newanimations
end

function p.getTransforming(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    return getSkins(args['champion'], args['skin']).transforming
end

function p.getFilter(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    return getSkins(args['champion'], args['skin']).filter
end

function p.getNewquotes(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    return getSkins(args['champion'], args['skin']).newquotes
end

function p.getNewvoice(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    return getSkins(args['champion'], args['skin']).newvoice
end

function p.getExtras(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    return getSkins(args['champion'], args['skin']).extras
end

function p.getLore(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    return getSkins(args['champion'], args['skin']).lore
end

function p.getLootEligible(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    return getSkins(args['champion'], args['skin']).looteligible
end

function p.getChromas(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    return getSkins(args['champion'], args['skin']).chromas
end

function p.getChromacount(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    local t = getSkins(args['champion'], args['skin']).chromas
    local s = ""
    
    local chromatable  = {}
    for chromaname in pairs(t) do
        table.insert(chromatable, chromaname)
    end
    
    return #chromatable or "N/A"
end

function p.getChromanames(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    local t = getSkins(args['champion'], args['skin'])
    if t == nil or t.chromas == nil then
        return ""
    end
    t = t.chromas
    
    local chromatable  = {}
    for chromaname in pairs(t) do
        table.insert(chromatable, chromaname)
    end
    table.sort(chromatable)

    local s = ""
    for i, chromaname in pairs(chromatable) do
        if i ~= 1 then
            s = s  .. ", " .. chromaname
        else
            s = s .. chromaname
        end
    end
    
    return s
end

function p.getForms(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    return getSkins(args['champion'], args['skin']).forms
end

function p.getFormnames(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    local t = getSkins(args['champion'], args['skin']).forms
    local s = ""
    
    local formtable  = {}
    for formname in pairs(t) do
        table.insert(formtable, formname)
    end
    table.sort(formtable)

    for i, formname in pairs(formtable) do
        if i ~= 1 then
            s = s  .. ", " .. formname
        else
            s = s .. formname
        end
    end
    
    return s
end

function p.getFormicon(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    return getSkins(args['champion'], args['skin']).formicon
end

function p.getVu(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    return getSkins(args['champion'], args['skin']).vu
end

function p.getSplashartist(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    local t = getSkins(args['champion'], args['skin']).splashartist
    local s = ""
    
    if t == nil then
        return "Unknown artist"
    end
    
    for i, splashartistname in ipairs(t) do
        if i ~= 1 then
            s = s .. ", " .. splashartistname:gsub("% ", "&nbsp;")
        else
            s = splashartistname
        end
    end
    return s
end

function p.getArtistlist(frame)
    local championtable = {}
    local artists = {}
    local hash = {}
    local artistList = builder.create('ul')
    
    artistList:newline()
    
    for x in pairs(skinData) do
        table.insert(championtable, x)
    end
    table.sort(championtable)

    for _, championname in pairs(championtable) do
        local skintable  = {}
        for championname in pairs(skinData[championname]["skins"]) do
            table.insert(skintable, championname)
        end
        table.sort(skintable)

        for _, skinname in pairs(skintable) do
            local t = skinData[championname]["skins"][skinname]
            
            if t.splashartist ~= nil then
                for _, value in pairs(t.splashartist) do
                    if (not hash[value]) then
                        table.insert(artists, value)
                        hash[value] = true
                    end
                end
            end
        end
    end
    table.sort(artists)
        
    for _, artist in pairs(artists) do
        artistList
            :tag('li')
                :wikitext('[[' .. artist .. ']]')
                :done()
            :newline()
    end
    
    return artistList
end

function p.getVariant(frame)
    local args = lib.frameArguments(frame)
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    local searchid = getSkins(args['champion'], args['skin']).variant
    local skintable = {}
    
    if searchid == nil then
        return nil
    end
    
    for skinname, data in pairs(skinData[args['champion']]["skins"]) do
        if data.id == searchid then
            return skinname
        end
    end

    return nil
end

function p.getVoiceactor(frame)
    local args = lib.frameArguments(frame)
        
    args['champion'] = lib.validateName(args['champion'] or args[1])
    args['skin']	 =                  args['skin']     or args[2]
    
    local t = getSkins(args['champion'], args['skin']).voiceactor
    local s = ""
    
    if t == nil then
        return "Unknown voice actor"
    end
    
    for i, voiceactorname in ipairs(t) do
        if i ~= 1 then
            s = s .. ", " .. voiceactorname:gsub("% ", "&nbsp;")
        else
            s = voiceactorname
        end
    end

    return s
end

function p.newestSkins(frame)
    local args = lib.frameArguments(frame)

    local championtable = {}
    local releasetable = {}

    for x in pairs(skinData) do
        table.insert(championtable, x)
    end
    table.sort(championtable)

    for _, championname in pairs(championtable) do
        local skintable  = {}
        
        for championname in pairs(skinData[championname]["skins"]) do
            table.insert(skintable, championname)
        end
        
        for _, skinname in pairs(skintable) do
            table.insert(releasetable, {championname, skinname, skinData[championname]["skins"][skinname].release})
        end
    end
    
    function comp(a, b)
        if a[3] == "Upcoming" or b[3] == "Upcoming" then return false end
        if a[3] > b[3] then
            return true
        end
    end

    table.sort(releasetable, function(a, b) return a[2] > b[2] end)
    table.sort(releasetable, comp)
    
    local lang = mw.language.new("en")
    local count = tonumber(args[1]) or 7
    local s = ""
    
    for i in pairs(releasetable) do
        local champ      = releasetable[i][1]
        local skin       = releasetable[i][2]
        local formatname = releasetable[i][4]
        local cost       = p.getCost({champ, skin})
        local release    = releasetable[i][3]
        
        if release > lang:formatDate("Y-m-d") then
            -- skip if releasedate is in the future
        else
            if skin == "Original" then
                -- skip
            else 
                if count >= 1 then
                    count = count - 1
                    s = s .. "{{Skin portrait|" .. champ .. "|" .. skin.."|game=lol"
                    if     cost == 10   then s = s .. "|gems="
                    elseif cost == 100  then s = s .. "|prestige="
                    elseif cost == 2000 then s = s .. "|tokens="
                    else                     s = s .. "|rp="
                    end
                    s = s .. cost .. "|date=" .. lang:formatDate("d-M-Y", release) .. "}}"
                end
            end
        end
    end
    
    return frame:preprocess(s)
end

function p.skinCatalog(frame)
    local dlib          = require("Dev:Datecalc")
    local lang          = mw.language.new( "en" )
    local championtable = {}
    local sdtable       = builder.create('table')
    
    sdtable
        :addClass('sortable article-table novpadding hcpadding VerticalAlign sticky-header')
        :css('width','100%')
        :css('text-align','center')
        :css('font-size','12px')
        :newline()
        
        -- TABLE HEADER
        :tag('tr')
            :tag('th')
                :css('font-size','12px')
                :css('width','140x')
                :wikitext('Champion')
            :done()
            :tag('th')
                :css('font-size','12px')
                :attr('data-sort-type', "number")
                :wikitext('<div title="Available in-store or through Hextech Crafting.">Available</div>')
            :done()
            :tag('th')
                :css('font-size','12px')
                :attr('data-sort-type', "number")
                :wikitext('<div title="Available through Hextech Crafting or limited sales.">Legacy Vault</div>')
            :done()
            :tag('th')
                :css('font-size','12px')
                :attr('data-sort-type', "number")
                :wikitext('<div title="Only periodically available or acquired through special means.">Rare</div>')
            :done()
            :tag('th')
                :css('font-size','12px')
                :attr('data-sort-type', "number")
                :wikitext('Unavailable')
            :done()
            :tag('th')
                :css('font-size','12px')
                :attr('data-sort-type', "number")
                :wikitext('Total')
            :done()
            :tag('th')
                :css('font-size','12px')
                :attr('data-sort-type', "isoDate")
                :wikitext('Last Skin')
            :done()
            :tag('th')
                :css('font-size','12px')
                :attr('data-sort-type', "number")
                :wikitext('Days Ago')
            :done()
        :done()
        :newline()
        
    
    -- TABLE ENTRIES
    for x in pairs(skinData) do
        table.insert(championtable, x)
    end
    table.sort(championtable)

    local total_counts = {available = 0, legacy = 0, rare = 0, unavailable = 0}

    for _, championname in pairs(championtable) do
        local t            	= skinData[championname]["skins"]
        local sdnode		= builder.create('tr')
        local available		= {node = builder.create("td"), count = 0}
        local legacy		= {node = builder.create("td"), count = 0}
        local rare			= {node = builder.create("td"), count = 0}
        local unavailable	= {node = builder.create("td"), count = 0}
        local skintable    	= {}
        
        for skinname, sdata in pairs(t) do
            if skinname ~= "Original" and sdata["availability"] ~= "Canceled" and sdata["availability"] ~= "Removed" then
                table.insert(skintable, skinname)
            end
        end

        local function orderup(a,b)
	    	if a == "N/A" then
	    		return false
	    	end
	    	
	    	if b == "N/A" then
	    		return true
	    	end
	    	
	    	return t[a].release < t[b].release
	    end

        table.sort(skintable, orderup)
        
        local latest_release = t[skintable[#skintable]].release

        for i, skinname in pairs(skintable) do
        	local circle = builder.create("li")
        		:addClass("skin-icon")
        		:attr({
        			["data-game"] = "lol",
        			["data-champion"] = championname,
        			["data-skin"] = skinname
        		})
        		:wikitext('[[File:' .. FN.championcircle({championname, skinname}) .. '|26px|link=]]')
        	
            if t[skintable[i]].release == latest_release then
                circle:css({
                	["border-radius"] = "13px",
                	["width"] = "26px",
                	["height"] = "26px",
                	["box-shadow"] = "0 0 2px 2px #70fff2, 0 0 4px #111"
                })
            end
            
            if t[skinname].availability == "Available" then
                available.count = available.count + 1
                available.node:wikitext(tostring(circle))
            elseif t[skinname].availability == "Legacy" then
                legacy.count = legacy.count + 1
                legacy.node:wikitext(tostring(circle))
            elseif t[skinname].availability == "Rare" then
                rare.count = rare.count + 1
                rare.node:wikitext(tostring(circle))
            else
                unavailable.count = unavailable.count + 1
                unavailable.node:wikitext(tostring(circle))
            end
        end
        
        total_counts.available = total_counts.available + available.count
        total_counts.legacy = total_counts.legacy + legacy.count
        total_counts.rare = total_counts.rare + rare.count
        total_counts.unavailable = total_counts.unavailable + unavailable.count
        
        sdnode
            :tag('td')
                :addClass('skin-icon')
                :attr('data-sort-value', championname)
                :attr('data-champion', championname)
                :attr('data-skin', "Original")
                :attr('data-game', "lol")
                :css('text-align', 'left')
                :wikitext('[[File:' .. FN.championcircle({championname, "Original"}) .. '|26px|link=' .. championname .. ']] ' .. championname)
            :done()
        
        -- Available skins
        available.node
                :addClass('icon_list')
                :attr('data-sort-value', available.count)
                :css('text-align', 'left')
                :css('background-color', '#0a1827')
        
        sdnode:wikitext(tostring(available.node))
            
        -- Legacy skins
        legacy.node
                :addClass('icon_list')
                :attr('data-sort-value', legacy.count)
                :css('text-align', 'left')
            	:done()
        
        sdnode:wikitext(tostring(legacy.node))

        -- Rare skins
        rare.node
                :addClass('icon_list')
                :attr('data-sort-value', rare.count)
                :css('text-align', 'left')
                :css('background-color', '#0a1827')
            	:done()
        
        sdnode:wikitext(tostring(rare.node))

        -- Limited skins
        unavailable.node
                :addClass('icon_list')
                :attr('data-sort-value', unavailable.count)
                :css('text-align', 'left')
            	:done()
       
       sdnode:wikitext(tostring(unavailable.node))

        -- Total
            
        sdnode
            :tag('td')
                :css('text-align','right')
                :wikitext(#skintable)
            	:done()

        -- Last Skin
        local y, m, d = latest_release:match("(%d+)-(%d+)-(%d+)")

		if latest_release == "N/A" then
			--These should all be Upcoming, but if they're not it should help
			--debugging
        	latest_release = t[skintable[#skintable]].availability 
        end

        local latest_skin_node = sdnode:tag("td")
        latest_skin_node
        	:addClass('skin-icon')
            :css('white-space', 'nowrap')
            :attr('data-champion', championname)
            :attr('data-skin', skintable[#skintable])
            :attr('data-game', "lol")

        if y == nil or m == nil or d == nil then
            latest_skin_node
                :wikitext(latest_release)
            	:done()
            sdnode
	            :tag('td')
	                :css('text-align','right')
	                :wikitext(latest_release)
	            	:done()
        else
            latest_skin_node
            	:attr('data-sort-value', dlib.main{"diff", lang:formatDate('Y-m-d'), latest_release})
                :wikitext(lang:formatDate('d-M-Y', latest_release))
            	:done()
            sdnode
                :tag('td')
                    :css('text-align','right')
                    :wikitext(dlib.main{"diff", lang:formatDate('Y-m-d'), latest_release})
                	:done()
        end
        
        -- Add skin row to the table
        sdtable
            :newline()
            :wikitext(tostring(sdnode))
            
    end
    
    
    --TABLE FOOTER
    local sdfooter = builder.create('tr')
    sdfooter
        :tag('th')
            :css('font-size','12px')
            :wikitext('Total')
        	:done()
        :tag('th')
            :css('font-size','12px')
            :wikitext(total_counts.available)
        	:done()
        :tag('th')
            :css('font-size','12px')
            :wikitext(total_counts.legacy)
    		:done()
        :tag('th')
            :css('font-size','12px')
            :wikitext(total_counts.rare)
        	:done()
        :tag('th')
            :css('font-size','12px')
            :wikitext(total_counts.unavailable)
        	:done()
        :newline()
        :tag('th')
            :css('font-size','12px')
            :wikitext(total_counts.available + total_counts.legacy + total_counts.rare + total_counts.unavailable)
        	:done()
        :tag('th')
        	:done()
        :tag('th')
        	:done()
        
    sdtable
        :wikitext(tostring(sdfooter))
        :newline()
    --TABLE END

    return sdtable
end

function p.collectionCatalog(frame)
    local dlib          = require("Dev:Datecalc")
    local lang          = mw.language.new( "en" )
    local sdtable       = builder.create('table')
    
    sdtable
        :addClass('sortable article-table novpadding hcpadding VerticalAlign sticky-header')
        :css('width','100%')
        :css('text-align','center')
        :css('font-size','12px')
        :newline()
        
        -- TABLE HEADER
        :tag('tr')
            :tag('th')
                :css('font-size','12px')
                :css('width','140x')
                :wikitext('Set')
            :done()
            :tag('th')
                :css('font-size','12px')
                :attr('data-sort-type', "number")
                :wikitext('<div title="Available in-store or through Hextech Crafting.">Available</div>')
            :done()
            :tag('th')
                :css('font-size','12px')
                :attr('data-sort-type', "number")
                :wikitext('<div title="Available through Hextech Crafting or limited sales.">Legacy Vault</div>')
            :done()
            :tag('th')
                :css('font-size','12px')
                :attr('data-sort-type', "number")
                :wikitext('<div title="Only periodically available or acquired through special means.">Rare</div>')
            :done()
            :tag('th')
                :css('font-size','12px')
                :attr('data-sort-type', "number")
                :wikitext('Unavailable')
            :done()
            :tag('th')
                :css('font-size','12px')
                :attr('data-sort-type', "number")
                :wikitext('Total')
            :done()
            :tag('th')
                :css('font-size','12px')
                :attr('data-sort-type', "isoDate")
                :wikitext('Latest Addition')
            :done()
            :tag('th')
                :css('font-size','12px')
                :attr('data-sort-type', "number")
                :wikitext('Days Ago')
            :done()
        :done()
        :newline()
    
    -- TABLE ENTRIES
    local championtable = {}
    for x in pairs(skinData) do
        table.insert(championtable, x)
    end
    table.sort(championtable)
    
    local skintable 	= {}
    local settable		= {}
    local hash			= {}
    
    for _, championname in pairs(championtable) do
        local t = skinData[championname]["skins"]
        
        for skinname in pairs(t) do
            if t[skinname].set ~= nil then
            	for _, setname in pairs(t[skinname].set) do
            		table.insert(skintable, {setname, championname, skinname})
            		
            		if (not hash[setname]) then
                		table.insert(settable, setname)
                		hash[setname] = true
		        	end
            	end
        	end
        end
    end
	
	function comp(a, b)
		if a[1] == b[1] then
			return a[2] < b[2] 
		else
			return a[1] < b[1]
		end
	end
	table.sort(skintable, comp)
	table.sort(settable)
    
--    for k, v in pairs(skintable) do
--    	mw.log(k, v[1], v[2], v[3])
--    end
    
    for k, v in pairs(settable) do
    	mw.log(k, v)
    end
    
    local availablecounttotal = 0
    local legacycounttotal    = 0
    local rarecounttotal      = 0
    local limitedcounttotal   = 0
    
    for _, setname in pairs(settable) do
        local availablecount   = 0
	    local availablecircles = ""
        local legacycount      = 0
	    local legacycircles    = ""
        local rarecount        = 0
	    local rarecircles      = ""
        local limitedcount     = 0
	    local limitedcircles   = ""
        local result           = {"","",""}
        local sdnode           = builder.create('tr')
        local border           = ""
        
        for k, v in pairs(skintable) do
        	local skinname = v[3]
        	local championname = v[2]
        	
        	if setname == v[1] then	
        		local t = skinData[championname]["skins"]
        		
	            --if t[skintable[i]].release == t[skintable[#skintable]].release then
	            --    border = "border-radius:13px; width:26px; height:26px; box-shadow: 0 0 2px 2px #70fff2, 0 0 4px #111;"
	            --end
	            
	            if t[skinname].availability == "Available" then
	                availablecount      = availablecount      + 1
	                availablecounttotal = availablecounttotal + 1
	                availablecircles = availablecircles .. '<li class="skin-icon" data-game="lol" data-champion="' .. championname ..'" data-skin="' .. skinname .. '" style="'.. border ..'">[[File:' .. FN.championcircle({championname, skinname}) .. '|26px|link=]]'
	            end
	            if t[skinname].availability == "Legacy" then
	                legacycount         = legacycount         + 1
	                legacycounttotal    = legacycounttotal    + 1
	                legacycircles = legacycircles .. '<li class="skin-icon" data-game="lol" data-champion="' .. championname ..'" data-skin="' .. skinname .. '" style="'.. border ..'">[[File:' .. FN.championcircle({championname, skinname}) .. '|26px|link=]]'
	            end
	            if t[skinname].availability == "Rare" then
	                rarecount           = rarecount           + 1
	                rarecounttotal      = rarecounttotal      + 1
	                rarecircles = rarecircles .. '<li class="skin-icon" data-game="lol" data-champion="' .. championname ..'" data-skin="' .. skinname .. '" style="'.. border ..'">[[File:' .. FN.championcircle({championname, skinname}) .. '|26px|link=]]'
	            end
	            if t[skinname].availability == "Limited" then
	                limitedcount        = limitedcount        + 1
	                limitedcounttotal   = limitedcounttotal   + 1
	                limitedcircles = limitedcircles .. '<li class="skin-icon" data-game="lol" data-champion="' .. championname ..'" data-skin="' .. skinname .. '" style="'.. border ..'">[[File:' .. FN.championcircle({championname, skinname}) .. '|26px|link=]]'
	            end
	            
	            if t[skinname].release > result[2] then
	                    result[1] = skinname
	                    result[2] = t[skinname].release
	                    result[3] = t[skinname].formatname
	            end
            end
        end
        
        sdnode
            :tag('td')
                :attr('data-sort-value', setname)
                :css('text-align', 'left')
                :wikitext(setname)
            :done()
        
        -- Available skins
        sdnode
            :tag('td')
                :addClass('icon_list')
                :attr('data-sort-value', availablecount)
                :css('text-align', 'left')
                :css('background-color', '#0a1827')
                :wikitext(availablecircles)
            :done()
            
        -- Legacy skins
        sdnode
            :tag('td')
                :addClass('icon_list')
                :attr('data-sort-value', legacycount)
                :css('text-align', 'left')
                :wikitext(legacycircles)
            :done()
            
        -- Rare skins
        sdnode
            :tag('td')
                :addClass('icon_list')
                :attr('data-sort-value', rarecount)
                :css('text-align', 'left')
                :css('background-color', '#0a1827')
                :wikitext(rarecircles)
            :done()
         
        -- Limited skins
        sdnode
            :tag('td')
                :addClass('icon_list')
                :attr('data-sort-value', limitedcount)
                :css('text-align', 'left')
                :wikitext(limitedcircles)
            :done()   
           
        -- Total
            
        sdnode
            :tag('td')
                :css('text-align','right')
                :wikitext(availablecount + legacycount + rarecount + limitedcount)
            :done()

        -- Last Skin
        local y, m, d = result[2]:match("(%d+)-(%d+)-(%d+)")
        if y == nil or m == nil or d == nil then
            sdnode
                :tag('td')
                    :addClass('skin-icon')
                    :css('white-space', 'nowrap')
                    :attr('data-sort-value', result[2])
                    :wikitext(result[2])
                :done()
                :tag('td')
                    :css('text-align','right')
                    :wikitext(result[2])
                :done()
        else
            sdnode
                :tag('td')
                    :addClass('skin-icon')
                    :css('white-space', 'nowrap')
                    :attr('data-sort-value', result[2])
                    :wikitext(lang:formatDate('d-M-Y', result[2]))
                :done()
                :tag('td')
                    :css('text-align','right')
                    :wikitext(dlib.main{"diff", lang:formatDate('Y-m-d'), result[2]})
                :done()
        end
	        
        -- Add collection row to the table
        sdtable
            :newline()
            :node(sdnode)
    end
    
    --TABLE FOOTER
    local sdfooter = builder.create('tr')
    sdfooter
        :tag('th')
            :css('font-size','12px')
            :wikitext('Total')
        :done()
        :tag('th')
            :css('font-size','12px')
            :wikitext(availablecounttotal)
        :done()
        :tag('th')
            :css('font-size','12px')
            :wikitext(legacycounttotal)
        :done()
        :tag('th')
            :css('font-size','12px')
            :wikitext(rarecounttotal)
        :done()
        :tag('th')
            :css('font-size','12px')
            :wikitext(limitedcounttotal)
        :done()
        :newline()
        :tag('th')
            :css('font-size','12px')
            :wikitext(availablecounttotal + legacycounttotal + rarecounttotal + limitedcounttotal)
        :done()
        :tag('th')
        :done()
        :tag('th')
        :done()
        
    sdtable
        :node(sdfooter)
        :newline()
    --TABLE END
    

    return sdtable
end

function p.skintooltip(frame)
    local args = lib.frameArguments(frame)
    
    args['skin']       = args['skin'] or 'Original'
    
    local filename     = FN.skin{args['champion'], args['skin'], args['variant']}
    local t            = skinData[args['champion']]['skins'][args['skin']]
    local newrecall    = t['newrecall']
    local formatname   = t['formatname']
    local cost         = t['cost']
    local distribution = t['distribution']
    local voiceactor   = p.getVoiceactor{args['champion'], args['skin']}
    local splashartist = p.getSplashartist{args['champion'], args['skin']}
    local set          = p.getSet{args['champion'], args['skin']}
    local lore         = t['lore']
    local filter       = t['filter']
    local newquotes    = t['newquotes']
    local newvoice     = t['newvoice']
    local neweffects   = t['neweffects']
    local newrecall    = t['newrecall']
    local newanimations= t['newanimations']
    local transforming = t['transforming']
    local extras       = t['extras']
    local chromas      = t['chromas']
    local looteligible = t['looteligible']
    local variantof    = p.getVariant{args['champion'], args['skin']}
    
    local rpskins      = {[260]=true, [585]=true, [790]=true, [880]=true, [390]=true, [460]=true, [500]=true, [520]=true, [750]=true, [975]=true, [1350]=true, [1820]=true, [2775]=true, [3250]=true, [5000]=true}
    local s            = ''
    
    s = s .. '<div style="position:relative;"><div class="tooltip-bg-image">[[File:' .. filename .. '|700px]]</div>'
        s = s .. '<div class="skin-features" style="padding:8px 10px; position:absolute; bottom:10px; left:10px; right:10px; background-color:RGBA(10, 24, 39, 0.75);">'
            s = s .. '<div style="font-family:BeaufortLoL;">'
                s = s .. '<span style="font-size:16px; font-weight:bold; color:#d3c7aa; width:100%; text-transform:uppercase;">'
                    s = s .. lib.ternary(formatname ~= nil, formatname, args['skin'] .. ' ' .. args['champion']) .. lib.ternary(args['variant'] ~= nil, '&nbsp;<small>(' .. tostring(args['variant']) .. ')</small>', '')
                s = s .. '</span>&nbsp;<span style="font-size:14px; color:#c9aa71; width:100%;">'
                
                    if cost == 10 then
                        s = s .. '&#x2011;&nbsp;' .. tostring(IL.basic{link = 'Gemstone', text = cost, image = 'Rare Gem.png', alttext = cost .. ' Rare Gems}', border = "false", labellink = "false"})
                    elseif cost == 100 then
                        -- Prestige: distribution string
                    elseif rpskins[cost] == true then
                        s = s .. '&#x2011;&nbsp;' .. tostring(IL.basic{link = 'Riot Points', text = cost, image = 'RP icon.png', alttext = cost .. ' RP', border = "false", labellink = "false"})
                    elseif cost == 150000 then
                        s = s .. '&#x2011;&nbsp;' .. tostring(IL.basic{link = 'Blue Essence', text = cost, image = 'BE icon.png', alttext = cost .. ' BE', border = "false", labellink = "false"})
                    else
                        -- default: do nothing
                    end
                    
                s = s .. lib.ternary(distribution ~= nil, ' ' .. tostring(distribution), '') .. '</span>'
            s = s .. '</div>'
            s = s .. '<div style="font-size:11px">'
                s = s .. lib.ternary(lore ~= nil, '<div style="line-height: 1.7em; text-align: justify; padding-bottom:4px;">' .. tostring(lore) .. '</div>', '')
                s = s .. lib.ternary(voiceactor, '<div style="display:inline-block; padding-right:1em;">[[File:Actor.png|20px|link=]]' .. tostring(voiceactor) .. '</div>', '')
                s = s .. lib.ternary(splashartist, '<div style="display:inline-block; padding-right:1em;">[[File:Artist.png|20px|link=]]' .. tostring(splashartist) .. '</div>', '')
                s = s .. lib.ternary(set ~= nil, '<div style="display:inline-block; padding-right:1em;">[[File:Set piece.png|20px|link=]]' .. tostring(set) .. '</div>', '')
                s = s .. lib.ternary(looteligible ~= false, '<div style="display:inline-block; padding-right:1em;">[[File:Loot eligible.png|20px|link=]] Loot eligible</div>', '')
                s = s .. lib.ternary(looteligible == false, '<div style="display:inline-block; padding-right:1em;">[[File:Loot ineligible.png|20px|link=]] Loot ineligible </div>', '')
           
            if availability or filter or newquotes or newvoice or neweffects or newanimations or newrecall or transforming or extras or chromas or looteligible then
                s = s .. '<div>'
                
                if availability == 'Limited' then
                    s = s .. '<div style="display:inline-grid; padding:0 1em; text-align:center;"><div>[[File:Limited skin.png|50px|link=]]</div><div>Limited Edition</div></div>'
                elseif availability == 'Legacy' then
                    s = s .. '<div style="display:inline-grid; padding:0 1em; text-align:center;"><div>[[File:Legacy skin.png|50px|link=]]</div><div>Legacy Vault</div></div>'
                end
                        
                s = s .. lib.ternary(filter, '<div style="display:inline-grid; padding:0 1em; text-align:center;"><div>[[File:Voice filter.png|32px|link=]]</div><div>Voice Filter</div></div>', '')
                s = s .. lib.ternary(newquotes, '<div style="display:inline-grid; padding:0 1em; text-align:center;"><div>[[File:Additional quotes.png|32px|link=]]</div><div>Additional Quotes</div></div>', '')
                s = s .. lib.ternary(newvoice, '<div style="display:inline-grid; padding:0 1em; text-align:center;"><div>[[File:New voice.png|32px|link=]]</div><div>New Voice</div></div>', '')
                s = s .. lib.ternary(neweffects, '<div style="display:inline-grid; padding:0 1em; text-align:center;"><div>[[File:New effects.png|32px|link=]]</div><div>New SFX/VFX</div></div>', '')
                s = s .. lib.ternary(newanimations, '<div style="display:inline-grid; padding:0 1em; text-align:center;"><div>[[File:New animations.png|32px|link=]]</div><div>New Animations</div></div>', '')
                s = s .. lib.ternary(newrecall, '<div style="display:inline-grid; padding:0 1em; text-align:center;"><div>[[File:Recall feature.png|32px|link=]]</div><div>New Recall</div></div>', '')
                s = s .. lib.ternary(transforming, '<div style="display:inline-grid; padding:0 1em; text-align:center;"><div>[[File:Transforming.png|32px|link=]]</div><div>Transforming</div></div>', '')
                s = s .. lib.ternary(extras, '<div style="display:inline-grid; padding:0 1em; text-align:center;"><div>[[File:Includes extras.png|32px|link=]]</div><div>Includes Extras</div></div>', '')
                s = s .. lib.ternary(chromas, '<div style="display:inline-grid; padding:0 1em; text-align:center;"><div>[[File:Chromas available.png|32px|link=]]</div><div>Chromas</div></div>', '')
                s = s .. '</div>'
            end
            s = s .. lib.ternary(variantof ~= nil, '<div>This skin is a variant of ' .. tostring(IL.skin{champion = args['champion'], skin = variantof, circle = "true", link = '*none*'}) .. '.</div>', '')
            s = s .. '</div>'
        s = s .. '</div>'
    s = s .. '</div>'
    
    return s
end

function p.chromaList(frame)
    local lang = mw.language.new( "en" )
    local sdtable = builder.create('table')
    
    sdtable
        :addClass('sortable article-table nopadding sticky-header')
		:css('text-align','center')	
        :newline()
        
        --TABLE HEADER
        :tag('tr')
            :tag('th')
                :css('width','26px')
                :attr('data-sort-type','text')
                :attr('title','Sort by Champion')
            :done()
            :tag('th')
                :wikitext('Skin')
                :attr('title','Sort by Skin Name')
            :done()
            :tag('th')
                :css('width','80px')
                :attr('title','Availability')
    			:css('text-align','center')	
                :wikitext('[[File:Availability.png|40px|link=|]]')
            :done()
            :tag('th')
                :css('width','80px')
    			:css('text-align','center')	
                :attr('title','Cost')
    			:css('text-align','center')	
                :wikitext('[[File:RP icon.png|30px|link=|]]')
            :done()
            :tag('th')
                :css('width','40px')
    			:css('text-align','center')	
                :attr('title','Store Chromas')
                :css('color','#404040')
                :wikitext('⬤')
            :done()
            :tag('th')
                :css('width','40px')
    			:css('text-align','center')	
                :attr('title','Bundle Chromas')
                :css('color','#e63031')
                :wikitext('⬤')
            :done()
            :tag('th')
                :css('width','40px')
    			:css('text-align','center')	
                :attr('title','Loot Chromas')
                :css('color','#82499D')
                :wikitext('⬤')
            :done()
            :tag('th')
                :css('width','40px')
    			:css('text-align','center')	
                :attr('title','Partner Chromas')
                :css('color','#8bc34a')
                :wikitext('⬤')
            :done()
            :tag('th')
                :css('width','40px')
    			:css('text-align','center')	
                :attr('title','Distributed Chromas')
                :css('color','#FFD700')
                :wikitext('⬤')
            :done()
        :done()
        :newline()
        
        
        -- TABLE ENTRIES
        local championtable = {}
        for x in pairs(skinData) do
            table.insert(championtable, x)
        end
        table.sort(championtable)
        
        local availablenode = builder.create('span')
        availablenode
            :css('color', 'green')
            :css('font-size', 'x-large')
            :css('vertical-align', 'text-top')
            :wikitext("✔")
            
        local legacynode = builder.create('span')
        legacynode
            :css('color', 'yellow')
            :css('font-size', 'x-large')
            :css('font-weight', '600')
            :css('vertical-align', 'text-top')
            :wikitext("‒")
            
        local limitednode = builder.create('span')
        limitednode
            :css('color', 'red')
            :css('font-size', 'x-large')
            :css('vertical-align', 'text-top')
            :wikitext("✘")
        local rarenode = builder.create('span')
        rarenode
            :css('color', 'orange')
            :css('font-size', 'x-large')
            :css('vertical-align', 'text-top')
            :wikitext("⭐")
        
        for _, championname in pairs(championtable) do
            local skintable  = {}
            for championname in pairs(skinData[championname]["skins"]) do
                table.insert(skintable, championname)
            end
            table.sort(skintable)
    
            for _, skinname in pairs(skintable) do
                if skinData[championname]["skins"][skinname]["chromas"] == nil then
                    -- skip
                else
                    local t = skinData[championname]["skins"][skinname]
                    local sdnode = builder.create('tr')
                    local temp = ""
                    
                    -- Skincircle
                    if (skinname == "Original") then
                        temp = "!" .. t["release"]
                    else 
                        temp = t["release"]
                    end
                    
                    sdnode
                        :tag('td')
                            :addClass('champion-icon')
                            :attr('data-sort-value', championname .. temp)
                            :attr('data-champion', championname)
                            :attr('data-skin', skinname)
                            :wikitext('[[File:' .. FN.championcircle({championname, skinname}) .. '|20px|link=' .. championname .. ']]')
                        :done()
                    
                    -- Skinname
                    sdnode
                        :tag('td')
                            :addClass('skin-icon')
                            :attr('data-champion', championname)
                            :attr('data-skin', skinname)
                            :attr('data-game', "lol")
                            :css('text-align', 'left')
                            :wikitext('[[' .. championname .. '|' .. lib.ternary(t["formatname"] ~= nil, t["formatname"], skinname .. " " .. championname) .. ']]')
                        :done()
                    
                    -- Availability
                    local astring = '<span style="color: cornflowerblue;font-size: large;font-weight: 600;">⭘</span>'
                    if (t["availability"] == "Available") then
                        astring = tostring(availablenode)
                    end
                    if (t["availability"] == "Legacy") then
                        astring = tostring(legacynode)
                    end
                    if (t["availability"] == "Limited") then
                        astring = tostring(limitednode)
                    end
                    if (t["availability"] == "Rare") then
                        astring = tostring(rarenode)
                    end
                    sdnode
                        :tag('td')
                            :tag('span')
                                :attr('title', t["availability"] or 'Upcoming')
                                :wikitext(astring)
                        :done()
                    
                    -- Cost
                    local image = ""
                    if (tostring(t["cost"]) == "150000") then
                        image = "[[File:BE icon.png|20px|link=]]"
                    end 
                    if (tostring(t["cost"]) == "100") then
                        image = "[[File:Hextech Crafting Prestige token.png|20px|link=]]"
                    end
                    if (tostring(t["cost"]) == "10") then
                        image = "[[File:Rare Gem.png|20px|link=]]"
                    end
                    sdnode
                        :tag('td')
                            :attr('data-sort-value', lib.ternary(tostring(t["cost"]) == "10" or tostring(t["cost"]) == "100", "2450", t["cost"]))
                            :tag('span')
                                :css('color', color.skin({t["cost"] .. ""}))
                                :wikitext(image .. t["cost"])
                            :done()
                        :done()
                    
                    -- Chromas
                    local availtable   = {}
                    local bundletable  = {}
                    local partnertable = {}
                    local loottable    = {}
                    local rewardtable  = {}
                    local futuretable  = {}
                    
                    for chromaname in pairs(t["chromas"]) do
                        if     t["chromas"][chromaname]["source"] == "Bundle" then
                            table.insert(bundletable, chromaname)
                        elseif t["chromas"][chromaname]["source"] == "Loot" then
                            table.insert(loottable, chromaname)
                        elseif t["chromas"][chromaname]["source"] == "Partner" then
                            table.insert(partnertable, chromaname)
                        elseif t["chromas"][chromaname]["source"] == "Reward" then
                            table.insert(rewardtable, chromaname)
                        elseif t["chromas"][chromaname]["source"] == "Upcoming" then
                            table.insert(futuretable, chromaname)
                        else
                            table.insert(availtable, chromaname)
                        end
                    end
                    
                    --normal
                    if (#availtable ~= 0) then
                        local s = table.concat(availtable, ",")
                        sdnode
                            :tag('td')
                                :addClass('chroma-icon')
                                :attr('data-sort-value', 1)
                                :attr('data-champion', championname)
                                :attr('data-skin', skinname)
                                :attr('data-chromas', s)
                                :wikitext(tostring(availablenode))
                            :done()
                    else
                        sdnode
                            :tag('td')
                                :attr('data-sort-value', 0)
                            :done()
                    end
                    
                    --bundle
                    if (#bundletable ~= 0) then
                        local s = table.concat(bundletable, ",")
                        sdnode
                            :tag('td')
                                :addClass('chroma-icon')
                                :attr('data-sort-value', 1)
                                :attr('data-champion', championname)
                                :attr('data-skin', skinname)
                                :attr('data-chromas', s)
                                :wikitext(tostring(availablenode))
                            :done()
                    else
                        sdnode
                            :tag('td')
                                :attr('data-sort-value', 0)
                            :done()
                    end
                    
                    --loot
                    if (#loottable ~= 0) then
                        local s = table.concat(loottable, ",")
                        sdnode
                            :tag('td')
                                :addClass('chroma-icon')
                                :attr('data-sort-value', 1)
                                :attr('data-champion', championname)
                                :attr('data-skin', skinname)
                                :attr('data-chromas', s)
                                :wikitext(tostring(availablenode))
                            :done()
                    else
                        sdnode
                            :tag('td')
                                :attr('data-sort-value', 0)
                            :done()
                    end
                    
                    
                    --partner
                    if (#partnertable ~= 0) then
                        local s = table.concat(partnertable, ",")
                        sdnode
                            :tag('td')
                                :addClass('chroma-icon')
                                :attr('data-sort-value', 1)
                                :attr('data-champion', championname)
                                :attr('data-skin', skinname)
                                :attr('data-chromas', s)
                                :wikitext(tostring(availablenode))
                            :done()
                    else
                        sdnode
                            :tag('td')
                                :attr('data-sort-value', 0)
                            :done()
                    end
                    
                    --distributed
                    if (#rewardtable ~= 0) then
                        local s = table.concat(rewardtable, ",")
                        sdnode
                            :tag('td')
                                :addClass('chroma-icon')
                                :attr('data-sort-value', 1)
                                :attr('data-champion', championname)
                                :attr('data-skin', skinname)
                                :attr('data-chromas', s)
                                :wikitext(tostring(availablenode))
                            :done()
                    else
                        sdnode
                            :tag('td')
                                :attr('data-sort-value', 0)
                            :done()
                    end
                    
                    -- Add skin row to the table
                    sdtable
                        :node(sdnode)
                        :newline()
                end
            end
        end
        -- TABLE END
    
    sdtable:allDone()
    return tostring(sdtable)
end

function p.filenametoskin(frame)
	local args = lib.frameArguments(frame)
	
	args["champ"] = args["champ"] or args[1] or ""
	if args["champ"] == "Nunu" then
		args["champ"] = "Nunu & Willump"
	end
	args["skin"] = args["skin"] or args[2] or ""
	if skinData[args["champ"]] then
		for k,_ in pairs(skinData[args["champ"]]["skins"]) do
	    	local key = mw.ustring.gsub(k, "[^%w%.%-,'&()]", "")
	    	if args["skin"] == key then
	        	return k
	    	end
		end
	end
	-- this checks in WR data to account for WR exclusive skins
	local WRskinData = mw.loadData('Module:SkinDataWR/data')
	if WRskinData[args["champ"]] then
		for k,_ in pairs(WRskinData[args["champ"]]["skins"]) do
	    	local key = mw.ustring.gsub(k, "[^%w%.%-,'&]()", "")
	    	if args["skin"] == key then
	        	return k
	    	end
		end
	end
	return args["skin"]
end

function p.gameexclusive(frame)
	local args = lib.frameArguments(frame)
	
	args["champ"] = args["champ"] or args[1] or ""
	if args["champ"] == "Nunu" then
		args["champ"] = "Nunu & Willump"
	end
	args["skin"] = args["skin"] or args[2] or ""
	
	local WRskinData = mw.loadData('Module:SkinDataWR/data')
	if skinData[args["champ"]] then
		if WRskinData[args["champ"]] then
			if WRskinData[args["champ"]]["skins"][args["skin"]] and skinData[args["champ"]]["skins"][args["skin"]] then
				return "none"
			elseif WRskinData[args["champ"]]["skins"][args["skin"]] and not (skinData[args["champ"]]["skins"][args["skin"]]) then
				return "wr"
			elseif not (WRskinData[args["champ"]]["skins"][args["skin"]]) and skinData[args["champ"]]["skins"][args["skin"]] then
				return "lol"
			else
				return userError("Skin ''" .. args["skin"] .. "'' does not exist in neither Module:SkinData/data nor Module:SkinDataWR/data", "LuaError")
			end
		else
			if skinData[args["champ"]]["skins"][args["skin"]] then
				return "lol"
			else
				return userError("Skin ''" .. args["skin"] .. "'' does not exist in neither Module:SkinData/data nor Module:SkinDataWR/data", "LuaError")
			end
		end
	else
		return userError("Champion ''" .. args["champ"] .. "'' does not exist in the Module:SkinData/data", "LuaError")
	end
end



-- testing upcoming skins function
function p.TEST2upcomingSkins(frame)
    local args = lib.frameArguments(frame)

    local championtable = {}
    local releasetable = {}

    for x in pairs(skinData) do
        table.insert(championtable, x)
    end
    table.sort(championtable)

    for _, championname in pairs(championtable) do
        local skintable  = {}
        
        for championname in pairs(skinData[championname]["skins"]) do
            table.insert(skintable, championname)
        end
        
        for _, skinname in pairs(skintable) do
        	if skinData[championname]["skins"][skinname].availability == "Upcoming" then
            	table.insert(releasetable, {championname, skinname})
            end
        end
    end


    table.sort(releasetable, function(a, b) return a[2] > b[2] end)
    
    local lang = mw.language.new("en")
    local count = tonumber(args[1]) or 7
    local s = ""
    
    for i in pairs(releasetable) do
        local champ      = releasetable[i][1]
        local skin       = releasetable[i][2]
        local formatname = releasetable[i][4]
        local cost       = p.getCost({champ, skin})
        local release    = p.getRelease({champ, skin})
        if (not release) or release == "" then
        	release = "N/A"
        end
        
        local releasetext
        if release == "N/A" then releasetext = "N/A" else releasetext = lang:formatDate("d-M-Y", release) end
        
--        if release > lang:formatDate("Y-m-d") then
            if skin == "Original" then
                -- skip
            else 
                if count >= 1 then
                    count = count - 1
                    s = s .. "{{Skin portrait|" .. champ .. "|" .. skin.."|game=lol"
                    if     cost == 10   then s = s .. "|gems="
                    elseif cost == 100  then s = s .. "|prestige="
                    elseif cost == 2000 then s = s .. "|tokens="
                    else                     s = s .. "|rp="
                    end
                    s = s .. cost .. "|date=" .. releasetext .. "}}"
                end
            end
        end
--    end
    
    return frame:preprocess(s)
end


-- Generates a list of champion skins with additional SFX, VO and filters, followed by an intro caption for audio pages
-- Author: ru:User:Mortorium
function p.getSkinQuotesCaption(frame)
	local args = lib.frameArguments(frame)
	
	local champion = args["champion"] or args[1]
    local append = args["append"] or
        "Each of these skins may feature: a voiceover filter; additional quotes and/or interactions<!--; sound effect variations and/or additions-->. In all other cases, skins use the base skin's audio or version of the audio. Some voicelines may also be disabled while using alternate skins."
	if(champion == nil) then
		return userError("Champion not found", "SkinData Error")
	end
	
	local championData = skinData[champion]
    if(championData == nil) then
        return userError("Champion " .. " not found in Module:SkinData/data", "SkinData Error")
    end

    local filteredSkins = {}

    for k, v in skinIter(championData["skins"]) do
        repeat
            if(v.newvoice == true) then break end
            if(v.filter or v.newquotes or (v.id == 0)) then 
                table.insert(filteredSkins, k)
            end
            break
        until true
    end
    
    local blockNode = mw.html.create("div")
    blockNode
        :addClass("lol-quotes-caption")

    for i, v in ipairs(filteredSkins) do
        local flexNode = mw.html.create("div")
        flexNode
            :addClass("lol-quotes-caption-node")
            :wikitext(tostring(IL.skin{
                ["champion"] = champion,
                ["skin"] = v,
                ["circle"] = "true",
                ["link"] = "*none*",
                ["text"] = v,
                ["size"] = "32px"
            }))
            :done()
        :newline()
        blockNode:node(flexNode)
    end

    blockNode
        :tag("div")
            :addClass("lol-quotes-caption-appended-text")
            :wikitext(append)
            :done()        
        :done()
    
    return tostring(blockNode)
end

return p
