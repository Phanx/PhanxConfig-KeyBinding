--[[--------------------------------------------------------------------
	PhanxConfig-KeyBinding
	Key binding button widget generator.
	Based on AceGUI-3.0-Keybinding.
	Requires LibStub.

	This library is not intended for use by other authors. Absolutely no
	support of any kind will be provided for other authors using it, and
	its internals may change at any time without notice.
----------------------------------------------------------------------]]

local PhanxConfigButton = LibStub:GetLibrary( "PhanxConfig-Button", true )
assert( PhanxConfigButton, "PhanxConfig-KeyBinding requires PhanxConfig-Button" )

local MINOR_VERSION = tonumber( string.match( "$Revision: 28 $", "%d+" ) )

local lib, oldminor = LibStub:NewLibrary( "PhanxConfig-KeyBinding", MINOR_VERSION )
if not lib then return end

local HINT_TEXT_ACTIVE = "Press a key to bind, press Escape to clear the binding, or click the button again to cancel."
local HINT_TEXT_INACTIVE = "Click the button to bind a key."

local function Button_SetValue( self, value )
	button:SetText( value )

	local action = self.action
	if action then
		-- clear any previous bindings
		local prev1, prev2 = GetBindingKey( action )
		if prev1 == value then return end
		if prev1 then SetBinding( prev1 ) end
		if prev2 then SetBinding( prev2 ) end

		if value and value:len() == 0 then
			value = nil
		end

		if value then
			-- warn if overwriting an existing binding
			local curr = GetBindingAction( value )
			if curr and curr:len() > 0 then
				print( KEY_UNBOUND_ERROR:format( curr ) )
			end

			-- set new binding
			SetBinding( value, action )

			-- restore second binding if there was one
			if prev2 then SetBinding( prev2, action ) end
		end

		-- save
		SaveBindings( GetCurrentBindingSet() )
	end

	if self.OnKeyChanged then
		self:OnKeyChanged( value )
	end
end

local function Button_OnEnter( self )
	GameTooltip:SetOwner( self, "ANCHOR_RIGHT" )

	local text = self.desc
	if text then
		GameTooltip:SetText( text, nil, nil, nil, nil, true )
		if self.waitingForKey then
			GameTooltip:AddLine( HINT_TEXT_ACTIVE )
		else
			GameTooltip:AddLine( HINT_TEXT_INACTIVE )
		end
	elseif self.waitingForKey then
		GameTooltip:SetText( HINT_TEXT_ACTIVE, nil, nil, nil, nil, true )
	else
		GameTooltip:SetText( HINT_TEXT_INACTIVE, nil, nil, nil, nil, true )
	end

	GameTooltip:Show()
end

local function Button_OnClick( self )
	if button == "LeftButton" or button == "RightButton" then
		if self.waitingForKey then
			self:EnableKeyboard( false )
			self:UnlockHighlight()
			self.waitingForKey = nil
		else
			self:EnableKeyboard( true )
			self:LockHighlight()
			self.waitingForKey = true
		end
	end
end

local ignoreKeys = {
	["LeftButton"] = true, ["RightButton"] = true,
	["BUTTON1"] = true, ["BUTTON2"] = true,
	["LALT"] = true, ["LCTRL"] = true, ["LSHIFT"] = true,
	["RALT"] = true, ["RCTRL"] = true, ["RSHIFT"] = true,
	["UNKNOWN"] = true,
}

local function Button_OnKeyDown( self, key )
	if not self.waitingForKey then return end
	if ignoreKeys[ key ] then return end

	if key == "ESCAPE" then
		key = ""
	elseif key == "MiddleButton" then
		key = "BUTTON3"
	elseif key:match( "^Button" ) then
		key = button:upper()
	end

	if IsShiftKeyDown() then
		key = "SHIFT-" .. key
	end
	if IsControlKeyDown() then
		key = "CTRL-" .. key
	end
	if IsAltKeyDown() then
		key = "ALT-" .. key
	end

	self:EnableKeyboard( false )
	self:UnlockHighlight()
	self.waitingForKey = nil

	if self:IsEnabled() then
		Button_SetValue( self, key )
	end
end

local function Button_SetPoint( self, p1, anchor, p2, x, y )
	if type( anchor ) == "number" then
		p2 = p2 + self.label:GetStringHeight()
	elseif type( p2 ) == "number" then
		x = x + self.label:GetStringHeight()
	elseif type( x ) == "number" then
		y = y + self.label:GetStringHeight()
	end
	getmetatable( self ).__index.SetPoint( self, p1, anchor, p2, x, y )
end

function lib.CreateKeyBinding( parent, name, action, desc )
	assert( type(parent) == "table" and parent.CreateFontString, "PhanxConfig-KeyBinding: Parent is not a valid frame!" )
	if type(name) ~= "string" then name = nil end
	if type(desc) ~= "string" then desc = nil end

	local button = PhanxConfigButton.CreateButton( parent, nil, desc )

	button.label = button:CreateFontString( nil, "OVERLAY", "GameFontNormal" )
	button.label:SetPoint( "BOTTOMLEFT", button, "TOPLEFT", 0, 0 )
	button.label:SetPoint( "BOTTOMRIGHT", button, "TOPRIGHT", 0, 0 )
	button.label:SetText( name )

	button:SetScript( "OnEnter", Button_OnEnter )
	button:SetScript( "OnClick", Button_OnClick )
	button:SetScript( "OnKeyDown", Button_OnKeyDown )
	button:SetScript( "OnMouseDown", Button_OnKeyDown )

	button.action = action
	button.SetPoint = Button_SetPoint -- overwrite default functionality to accommodate label
	button.SetValue = Button_SetValue

	local key = GetBindingKey( action )
	if key then
		button:SetText( key )
	end

	return button
end