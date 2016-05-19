function widget:GetInfo()
  return {
    name      = "SVG Draw",
    desc      = "v0.004 Draw SVG on the map - /luaui svgdraw",
    author    = "CarRepairer",
    date      = "2013-08-10",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,
  }
end

include("keysym.h.lua")
local imageLists = {}
local drawMode
local keypadNumKeys = {}
local picScale = 0.5
local picWidth = 0
local picHeight = 0
local echo = Spring.Echo

local function explode(div,str)
  if (div=='') then return false end
  local pos,arr = 0,{}
  -- for each divider found
  for st,sp in function() return string.find(str,div,pos,true) end do
    table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
    pos = sp + 1 -- Jump past current divider
  end
  table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
  return arr
end

function string:findlast(str)
  local i
  local j = 0
  repeat
    i = j
    j = self:find(str,i+1,true)
  until (not j)
  return i
end

function string:GetExt()
  local i = self:findlast('.')
  if (i) then
    return self:sub(i)
  end
end

function table:ifind(element)
  for i=1, #self do
    if self[i] == element then
      return i
    end
  end
  return false
end


--code from cmd_emotes by TheFatController

local function linePoints(x1, y1, x2, y2)
  return { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
end

local function addline(lineList,x1, y1, x2, y2)
  table.insert(lineList,linePoints((x1*picScale),(y1*picScale),(x2*picScale),(y2*picScale)))
end

local function getHW(lineList)
  if (table.getn(lineList) == 0) then
    return false
  end
  local bx1 = lineList[1].x1
  local by1 = lineList[1].y1
  local bx2 = lineList[1].x2
  local by2 = lineList[1].y2
  for _,lineInfo in ipairs(lineList) do
    if (lineInfo.x1 < bx1) then
      bx1 = lineInfo.x1
    end
    if (lineInfo.y1 < by1) then
      by1 = lineInfo.y1
    end
    if (lineInfo.x2 > bx2) then
      bx2 = lineInfo.x2
    end
    if (lineInfo.y2 > by2) then
      by2 = lineInfo.y2
    end
  end
  picWidth = math.abs(bx1 - bx2)
  picHeight = math.abs(by1 - by2)
end


local function drawList(lineList)
  local x,y = Spring.GetMouseState()
  local getOver,getCo = Spring.TraceScreenRay(x,y, true) --param3 = onlycoords
  getHW(lineList)
  --if (getOver == "ground") then
    x = (getCo[1] - (picWidth / 2))
    y = (getCo[3] - (picHeight / 2))
    for _,l in ipairs(lineList) do
      Spring.MarkerAddLine((x+l.x1),0,(y+l.y1),(x+l.x2),0,(y+l.y2))
    end
  --end
end
--end code from cmd_emotes


--https://gist.github.com/ashdnazg/3d4de5bae33e4f54cd40
local ERROR_THRESHOLD = 10
local MAX_RECURSION = 7
--rom, from control, to control, to
local function FlattenBezier(x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4, lineList, depth)
    local bError = math.abs(x1 + x3 - x2 - x2) +
                   math.abs(y1 + y3 - y2 - y2) +
                   math.abs(z1 + z3 - z2 - z2) +
                   math.abs(x2 + x4 - x3 - x3) +
                   math.abs(y2 + y4 - y3 - y3) +
                   math.abs(z2 + z4 - z3 - z3)

    if first then
        Echo("e: ".. bError)
    end
    if bError < ERROR_THRESHOLD or depth > MAX_RECURSION then
        --lineList[#lineList+1] = {x1, y1, z1, x4, y4, z4}
        lineList[#lineList+1] = {x1, z1, x4, z4}
    else
        local x12   = (x1 + x2) / 2
        local y12   = (y1 + y2) / 2
        local z12   = (z1 + z2) / 2
        local x23   = (x2 + x3) / 2
        local y23   = (y2 + y3) / 2
        local z23   = (z2 + z3) / 2
        local x34   = (x3 + x4) / 2
        local y34   = (y3 + y4) / 2
        local z34   = (z3 + z4) / 2
        local x123  = (x12 + x23) / 2
        local y123  = (y12 + y23) / 2
        local z123  = (z12 + z23) / 2
        local x234  = (x23 + x34) / 2
        local y234  = (y23 + y34) / 2
        local z234  = (z23 + z34) / 2
        local x1234 = (x123 + x234) / 2
        local y1234 = (y123 + y234) / 2
        local z1234 = (z123 + z234) / 2
        FlattenBezier(x1, y1, z1, x12, y12, z12, x123, y123, z123, x1234, y1234, z1234, lineList, depth + 1)
        FlattenBezier(x1234, y1234, z1234, x234, y234, z234, x34, y34, z34, x4, y4, z4, lineList, depth + 1)
    end
end

local function BezierToList(x1, y1,   cx1, cy1,   x2, y2,   cx2, cy2,   abs)
	local lineList = {}
	
	--echo ('BezierToList1', x1, y1,   cx1, cy1,   x2, y2,   cx2, cy2, (abs and 'abs' or 'nabs'))
	if not abs then
		cx1 = x1 + cx1
		cy1 = y1 + cy1
		
		cx2 = x1 + cx2
		cy2 = y1 + cy2
		
	end
	
	--echo ('BezierToList2', x1, y1,   cx1, cy1,   x2, y2,   cx2, cy2, (abs and 'abs' or 'nabs'))
					
	FlattenBezier(x1, 0, y1,    cx1, 0, cy1,    cx2, 0, cy2,    x2, 0, y2,    lineList, 1)
    return lineList
end

--convert svg path to a list of line segments.
local function PathToList(data)

    local list = {}
    
    data = data:gsub('([%a,])', ' %1 ')
    --echo(data)
    
    local dataBreakdown = explode( ' ', data )
    
    local x,y, firstX,firstY
    
    local cx,cy
	
	local conx1, cony1, conx2, cony2
	local gotCon1, gotCon2
	
    local firstCmd
    local onFirstCmd
    local abs
    
    local gotX, gotY
    local nx, ny
    
    local gotCoord
	
	
	local movedOnce
  
    for i,v in ipairs(dataBreakdown) do
        
        gotCoord = false
        badElem = false
		--cmd = nil
		
		--echo ('v', v)
        if v:sub(1,1):find( '[%d%-]' ) then
			--local xy = explode( ',', v )
			--x = xy[1]
			--y = xy[2]
			
			if not gotX then
				x = v
				gotX = true
			else
				y = v
				
				if cmd == 'bez' then
					if not gotCon1 then
						gotCon1 = true
						conx1 = x
						cony1 = y
					elseif not gotCon2 then
						gotCon2 = true
						conx2 = x
						cony2 = y
					else
						gotCoord = true
						gotCon1 = false
						gotCon2 = false
					end
					
				else
					gotCoord = true
					if movedOnce and cmd == 'move' then
						cmd = 'line'
					end
				end
				
				if not firstX then
					firstX = x
					firstY = y
				end
				
				gotX = false
			end
			
        elseif ({M=1, m=1})[v:sub(1,1)] then
            cmd = 'move'
            abs = v:sub(1,1):find( '%u' ) 
        elseif ({L=1, l=1})[v:sub(1,1)] then
            cmd = 'line'
            abs = v:sub(1,1):find( '%u' ) 
        elseif ({C=1, c=1})[v:sub(1,1)] then
            cmd = 'bez'
            abs = v:sub(1,1):find( '%u' ) 
        elseif v:sub(1,1) == 'z' then
			
			if(i == #dataBreakdown) then
				cmd = 'move'
				abs = true
				x = firstX
				y = firstY
				gotCoord = true
			else
				cmd = 'move'
				abs = true
				gotCoord = false
			end
        else
            badElem = true
        end
        --[[
			(x1 y1 x2 y2 x y)+	Draws a cubic Bézier curve
			from the current point to (x,y)
			using (x1,y1) as the control point at the beginning of the curve
			and (x2,y2) as the control point at the end of the curve.
			C (uppercase) indicates that absolute coordinates will follow;
			c (lowercase) indicates that relative coordinates will follow. Multiple sets of coordinates may be specified to draw a polybézier. At the end of the command, the new current point becomes the final (x,y) coordinate pair used in the polybézier.
		]]
        if not badElem then
            if not firstCmd then
                firstCmd = cmd
                onFirstCmd = true
            end
            
            if gotCoord then
                if onFirstCmd then
                    abs = true
                end
                if cmd == 'move' or cmd == 'line' or cmd == 'bez' then
                    if abs then
                        nx = x
                        ny = y
                    else
						echo ('cx', cx)
                        nx = cx + x
                        ny = cy + y
                    end
                end
				
                --echo('curCmd:: ', cmd, nx, ny)
				
                if cmd == 'bez' then
					local blist = BezierToList(cx, cy, conx1, cony1, nx, ny, conx2, cony2, abs)
                    for b_i, b_v in ipairs(blist) do
						list[#list+1] = b_v
					end
					
                elseif cmd == 'line' then
                    
					list[#list+1] = {cx,cy, nx,ny}
				
                end
				
				if cmd == 'move' then
					movedOnce = true
				else
					movedOnce = false
				end
				
                cx = nx
                cy = ny
				
                abs = false
                onFirstCmd = false
            end
        end
        
    end
    
    return list
    
end


local function AddPaths( pic, paths )
    imageLists[pic] = {}
    for i,path in ipairs(paths) do
        local list = PathToList(path)
        for i2,v in ipairs(list) do
            addline(imageLists[pic],unpack(v))
        end
    end    
end

local function AddImage(file)
	local imageName = file:match( '([^/\\]+)%.svg' )
    --echo(imageName )
	
	local VFSMODE = VFS.ZIP_FIRST
	local data = VFS.LoadFile(file, VFSMODE)
	local lines = explode('\n', data)
	
    local lists = {}
    	
	for _,line in ipairs(lines) do
		--echo(line)
        local match = line:match('%sd="([^"]*)"')
		
		if match then
            lists[#lists+1] = match
        end
    end
    
    AddPaths( imageName, lists )
end

local function ScanDir()
    local files = VFS.DirList('LuaUI/images/svgdraw')
    local imageFiles = {}
    for i=1,#files do
        local fileName = files[i]
        local ext = (fileName:GetExt() or ""):lower()
        if (table.ifind({'.svg'},ext))then
            imageFiles[#imageFiles+1]=fileName
            AddImage(fileName)
        end
    end
    
end

local function EnterDrawMode()
    drawMode = true
    local out = ''
    local index = 1
    for pic, v in pairs(imageLists) do
        out = out .. '(' .. index .. ') ' .. pic .. '. '
        index = index + 1
    end
    echo(out)
end



-------------
--callins

function widget:Initialize()
    ScanDir()
    
    for i=0,9 do
        keypadNumKeys[ KEYSYMS['KP' .. i] ] = i
    end
end

function widget:KeyPress(key, mods, isRepeat, label, unicode)
    if not drawMode then
        return
    end
    if keypadNumKeys[key] then
        --drawList(imageLists['drawing'])
        
        local index = 1
        for pic, imageList in pairs(imageLists) do
            if index == keypadNumKeys[key] then
                drawList(imageList)
                drawMode = false
                return
            end
            index = index + 1
        end
    end
    drawMode = false
end

function widget:TextCommand(command)
    if (string.find(command, 'svgdraw') == 1) then
        EnterDrawMode()
    end
end