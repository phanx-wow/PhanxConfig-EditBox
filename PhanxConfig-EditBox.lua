--[[--------------------------------------------------------------------
	PhanxConfig-EditBox
	Simple text input box widget generator. Requires LibStub.
	https://github.com/Phanx/PhanxConfig-EditBox

	Copyright (c) 2009-2014 Phanx <addons@phanx.net>. All rights reserved.

	Permission is granted for anyone to use, read, or otherwise interpret
	this software for any purpose, without any restrictions.

	Permission is granted for anyone to embed or include this software in
	another work not derived from this software that makes use of the
	interface provided by this software for the purpose of creating a
	package of the work and its required libraries, and to distribute such
	packages as long as the software is not modified in any way, including
	by modifying or removing any files.

	Permission is granted for anyone to modify this software or sample from
	it, and to distribute such modified versions or derivative works as long
	as neither the names of this software nor its authors are used in the
	name or title of the work or in any other way that may cause it to be
	confused with or interfere with the simultaneous use of this software.

	This software may not be distributed standalone or in any other way, in
	whole or in part, modified or unmodified, without specific prior written
	permission from the authors of this software.

	The names of this software and/or its authors may not be used to
	promote or endorse works derived from this software without specific
	prior written permission from the authors of this software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
	IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
	OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
	ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
	OTHER DEALINGS IN THE SOFTWARE.
----------------------------------------------------------------------]]

local MINOR_VERSION = 176

local lib, oldminor = LibStub:NewLibrary("PhanxConfig-EditBox", MINOR_VERSION)
if not lib then return end

lib.editboxes = lib.editboxes or { }

if not PhanxConfigEditBoxInsertLink then
	hooksecurefunc("ChatEdit_InsertLink", function(...) return _G.PhanxConfigEditBoxInsertLink(...) end)
end

function PhanxConfigEditBoxInsertLink(link)
	for i = 1, #lib.editboxes do
		local editbox = lib.editboxes[ i ]
		if editbox and editbox:IsVisible() and editbox:HasFocus() then
			editbox:Insert(link)
			return true
		end
	end
end

------------------------------------------------------------------------

local scripts = {}

function scripts:OnEnter()
	local container = self:GetParent()
	if container.tooltipText then
		GameTooltip:SetOwner(container, "ANCHOR_RIGHT")
		GameTooltip:SetText(container.tooltipText, nil, nil, nil, nil, true)
	end
end
local function OnLeave()
	GameTooltip:Hide()
end

function scripts:OnEditFocusGained() -- print("OnEditFocusGained")
	CloseDropDownMenus()
	local text = self:GetText()
	self.currText, self.origText = text, text
	self:HighlightText()
end
function scripts:OnEditFocusLost() -- print("OnEditFocusLost")
	self:SetText(self.origText or "")
	self.currText, self.origText = nil, nil
end

function scripts:OnTextChanged()
	if not self:HasFocus() then return end

	local text = self:GetText()
	if text:len() == 0 then text = nil end -- experimental

	local parent = self:GetParent()
	local callback = parent.CallbackOnTextChanged or parent.OnTextChanged
	if callback and text ~= self.currText then
		callback(parent, text)
		self.currText = text
	end
end

function scripts:OnEnterPressed() -- print("OnEnterPressed")
	local text = self:GetText()
	if strlen(text) == 0 then text = nil end -- experimental
	self:ClearFocus()

	local parent = self:GetParent()
	local callback = parent.Callback or parent.OnValueChanged
	if callback then
		callback(parent, text)
	end
end

function scripts:OnEscapePressed() -- print("OnEscapePressed")
	self:ClearFocus()
end

function scripts:OnReceiveDrag()
	local type, id, info = GetCursorInfo()
	if type == "item" then
		self:SetText(info)
		scripts.OnEnterPressed(self)
		ClearCursor()
	elseif type == "spell" then
		local name = GetSpellInfo(id, info)
		self:SetText(name)
		scripts.OnEnterPressed(self)
		ClearCursor()
	end
end

------------------------------------------------------------------------

local methods = {}

function methods:GetText()
	return self.editbox:GetText()
end
function methods:SetText(text)
	return self.editbox:SetText(text)
end
function methods:SetFormattedText(text, ...)
	return self.editbox:SetText(format(text, ...))
end

function methods:GetLabel()
	return self.labelText:GetText()
end
function methods:SetLabel(text)
	self.labelText:SetText(text)
end

function methods:GetTooltip()
	return self.tooltipText
end
function methods:SetTooltip(text)
	self.tooltipText = text
end

------------------------------------------------------------------------

function lib:New(parent, name, tooltipText, maxLetters)
	assert(type(parent) == "table" and parent.CreateFontString, "PhanxConfig-EditBox: Parent is not a valid frame!")
	if type(name) ~= "string" then name = nil end
	if type(tooltipText) ~= "string" then tooltipText = nil end
	if type(maxLetters) ~= "number" then maxLetters = nil end

	local frame = CreateFrame("Frame", nil, parent)
	frame:SetWidth(144)
	frame:SetHeight(42)

--	local bg = frame:CreateTexture(nil, "BACKGROUND")
--	bg:SetAllPoints(frame)
--	bg:SetTexture(0, 0, 0)
--	frame.bg = bg

	local editbox = CreateFrame("EditBox", nil, frame)
	editbox:SetPoint("LEFT", 5, 0)
	editbox:SetPoint("RIGHT", -5, 0)
	editbox:SetHeight(19)
	editbox:EnableMouse(true)
	editbox:SetAutoFocus(false)
	editbox:SetFontObject(ChatFontNormal)
	editbox:SetMaxLetters(maxLetters or 256)
	editbox:SetTextInsets(0, 0, 3, 3)
	lib.editboxes[ #lib.editboxes + 1 ] = editbox
	frame.editbox = editbox

	editbox.bgLeft = editbox:CreateTexture(nil, "BACKGROUND")
	editbox.bgLeft:SetPoint("LEFT", 0, 0)
	editbox.bgLeft:SetSize(8, 20)
	editbox.bgLeft:SetTexture([[Interface\Common\Common-Input-Border]])
	editbox.bgLeft:SetTexCoord(0, 0.0625, 0, 0.625)

	editbox.bgRight = editbox:CreateTexture(nil, "BACKGROUND")
	editbox.bgRight:SetPoint("RIGHT", 0, 0)
	editbox.bgRight:SetSize(8, 20)
	editbox.bgRight:SetTexture([[Interface\Common\Common-Input-Border]])
	editbox.bgRight:SetTexCoord(0.9375, 1, 0, 0.625)

	editbox.bgMiddle = editbox:CreateTexture(nil, "BACKGROUND")
	editbox.bgMiddle:SetPoint("LEFT", editbox.bgLeft, "RIGHT")
	editbox.bgMiddle:SetPoint("RIGHT", editbox.bgRight, "LEFT")
	editbox.bgMiddle:SetSize(10, 20)
	editbox.bgMiddle:SetTexture([[Interface\Common\Common-Input-Border]])
	editbox.bgMiddle:SetTexCoord(0.0625, 0.9375, 0, 0.625)

	local label = editbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	label:SetPoint("BOTTOMLEFT", editbox, "TOPLEFT")
	label:SetPoint("BOTTOMRIGHT", editbox, "TOPRIGHT")
	label:SetJustifyH("LEFT")
	frame.labelText = label

	for name, func in pairs(scripts) do
		editbox:SetScript(name, func) -- NOT on the frame!
	end
	for name, func in pairs(methods) do
		frame[name] = func
	end

	frame.labelText:SetText(name)
	frame.tooltipText = tooltipText

	return frame
end

function lib.CreateEditBox(...) return lib:New(...) end