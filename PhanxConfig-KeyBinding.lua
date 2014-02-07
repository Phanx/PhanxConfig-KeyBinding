--[[--------------------------------------------------------------------
	PhanxConfig-KeyBinding
	Key binding button widget generator.
	Based on AceGUI-3.0-Keybinding.
	Requires LibStub.

	This library is not intended for use by other authors. Absolutely no
	support of any kind will be provided for other authors using it, and
	its internals may change at any time without notice.
----------------------------------------------------------------------]]

local PhanxConfigButton = LibStub:GetLibrary("PhanxConfig-Button", true)
assert(PhanxConfigButton, "PhanxConfig-KeyBinding requires PhanxConfig-Button")

local MINOR_VERSION = tonumber(string.match("$Revision$", "%d+"))

local lib, oldminor = LibStub:NewLibrary("PhanxConfig-KeyBinding", MINOR_VERSION)
if not lib then return end

------------------------------------------------------------------------

local HINT_TEXT_ACTIVE = "Press a key to bind, press Escape to clear the binding, or click the button again to cancel."
local HINT_TEXT_INACTIVE = "Click the button to bind a key."

do
	local GAME_LOCALE = GetLocale()
	if GAME_LOCALE == "deDE" then
		HINT_TEXT_ACTIVE = "Drücke eine Taste, um sie zu belegen. Drücke ESC, um die Belegung zu löschen, oder klick erneut, um zu abbrechen."
		HINT_TEXT_INACTIVE = "Klick, um eine Taste zu belegen."

	elseif GAME_LOCALE == "esES" or GAME_LOCALE == "esMX" then
		HINT_TEXT_ACTIVE = "Pulse una tecla para asignarlo, pulse Escape para borrar la asignación, o clic en el botón otra vez para cancelar."
		HINT_TEXT_INACTIVE = "Clic en el botón para asignar una tecla."

	elseif GAME_LOCALE == "frFR" then
		HINT_TEXT_ACTIVE = "Appuyez sur une touche pour assigner un raccourci, appuyez sur Echap pour effacer le raccourci, ou cliquez sur le bouton à nouveau pour annuler."
		HINT_TEXT_INACTIVE = "Cliquez sur le bouton pour assigner une touche."
	end
end

------------------------------------------------------------------------

local scripts = {} -- these are set on the button, not the container

function scripts:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

	local text = self.tooltipText
	if text then
		GameTooltip:SetText(text, nil, nil, nil, nil, true)
	elseif self.waitingForKey then
		GameTooltip:SetText(HINT_TEXT_ACTIVE, nil, nil, nil, nil, true)
	else
		GameTooltip:SetText(HINT_TEXT_INACTIVE, nil, nil, nil, nil, true)
	end

	GameTooltip:Show()
end

function scripts:OnClick(button)
	if button ~= "LeftButton" and button ~= "RightButton" then return end

	if self.waitingForKey then
		self:EnableKeyboard(false)
		self:UnlockHighlight()
		self.waitingForKey = nil
	else
		self:EnableKeyboard(true)
		self:LockHighlight()
		self.waitingForKey = true
	end
end

local ignoreKeys = {
	["LeftButton"] = true, ["RightButton"] = true,
	["BUTTON1"] = true, ["BUTTON2"] = true,
	["LALT"] = true, ["LCTRL"] = true, ["LSHIFT"] = true,
	["RALT"] = true, ["RCTRL"] = true, ["RSHIFT"] = true,
	["UNKNOWN"] = true,
}

function scripts:OnKeyDown(key)
	if ignoreKeys[key] or not self.waitingForKey then return end

	if key == "ESCAPE" then
		key = ""
	elseif key == "MiddleButton" then
		key = "BUTTON3"
	elseif key:match("^Button") then
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

	self:EnableKeyboard(false)
	self:UnlockHighlight()
	self.waitingForKey = nil

	self:SetValue(key)
end

------------------------------------------------------------------------

local methods = {} -- these are set on the button, not the container

function methods:GetValue()
	return self.action and GetBindingKey(self.action) or nil
end
function methods:SetValue(value)
	if value and value ~= "" then
		self:SetText(value)
	else
		self:SetText(NOT_BOUND)
	end

	local action = self.action
	if action then
		-- clear any previous bindings
		local prev1, prev2 = GetBindingKey(action)
		if prev1 == value then return end
		if prev1 then SetBinding(prev1) end
		if prev2 then SetBinding(prev2) end

		if value and strlen(value) > 0 then
			-- warn if overwriting an existing binding
			local curr = GetBindingAction(value)
			if curr and strlen(curr) > 0 then
				print(format(KEY_UNBOUND_ERROR, curr))
			end

			-- set new binding
			SetBinding(value, action)

			-- restore second binding if there was one
			if prev2 then SetBinding(prev2, action) end
		end

		-- save
		SaveBindings(GetCurrentBindingSet())
	end

	local func = self.func or self.OnKeyChanged
	if func then
		func(self, value)
	end
end

function methods:GetTooltipText()
	return self.tooltipText
end
function methods:SetTooltipText(text)
	self.tooltipText = text
end

function methods:SetFunction(func)
	self.func = func
end

function methods:SetPoint(...)
	return self.container:SetPoint(...)
end

function methods:RefreshValue()
	self:SetText(self:GetValue() or NOT_BOUND)
end

function methods:SetBindingAction(action)
	self.action = action
end

------------------------------------------------------------------------

function lib:New(parent, name, tooltipText, action)
	assert(type(parent) == "table" and parent.CreateFontString, "PhanxConfig-KeyBinding: Parent is not a valid frame!")
	if type(name) ~= "string" then name = nil end
	if type(tooltipText) ~= "string" then tooltipText = nil end

	local frame = CreateFrame("Frame", nil, parent)
	frame:SetWidth(186)
	frame:SetHeight(38)

	frame.bg = frame:CreateTexture(nil, "BACKGROUND")
	frame.bg:SetAllPoints(true)
	frame.bg:SetTexture(0, 0, 0, 0)

	local button = PhanxConfigButton.CreateButton(frame, nil, tooltipText)
	button:SetPoint("BOTTOMLEFT")
	button:SetPoint("BOTTOMRIGHT")

	local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("TOPLEFT", frame, 5, 0)
	label:SetPoint("TOPRIGHT", frame, -5, 0)
	label:SetJustifyH("LEFT")
	button.label = label

	button:SetNormalFontObject(GameFontHighlightSmall)
	button:EnableKeyboard(false)
	button:EnableMouse(true)
	button:RegisterForClicks("AnyDown")

	button.container = frame

	for name, func in pairs(scripts) do
		button:SetScript(name, func)
	end
	for name, func in pairs(methods) do
		button[name] = func
	end

	label:SetText(name)
	button.action = action
	button:RefreshValue()

	return button
end

function lib.CreateKeyBinding(...) return lib:New(...) end