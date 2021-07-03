local Class = {}

setmetatable(Class, {
	__call = function(self)
		self.__call = getmetatable(self).__call
		self.__index = self
		return setmetatable({}, self)
	end
})

function Class:new()
	return self()
end

DuiBrowser = Class()

DuiBrowser.pool = {}
DuiBrowser.renderTargets = {}

function DuiBrowser:createNamedRendertargetForModel(model, name)
	local handle = 0

	if not IsNamedRendertargetRegistered(name) then
		RegisterNamedRendertarget(name, 0)
	end
	if not IsNamedRendertargetLinked(model) then
		LinkNamedRendertarget(model)
	end
	if IsNamedRendertargetRegistered(name) then
		handle = GetNamedRendertargetRenderId(name)
	end

	return handle
end

function DuiBrowser:waitForConnection()
	self.initDone = false

	local timeWaited = 0

	while not self.initDone and timeWaited < 1000 do
		self:sendMessage({type = "DuiBrowser:init", handle = self.phonographHandle})
		Citizen.Wait(100)
		timeWaited = timeWaited + 100
	end

	if not self.initDone then
		print("Failed to connect to " .. Config.dui.url)
	end
end

function DuiBrowser:enableRenderTarget()
	if self.renderTargetHandle then
		return
	end

	self.renderTargetHandle = self:createNamedRendertargetForModel(self.model, self.renderTarget)

	DuiBrowser.renderTargets[self.renderTarget].browsers[self] = true
end

function DuiBrowser:disableRenderTarget()
	if not self.renderTargetHandle then
		return
	end

	ReleaseNamedRendertarget(self.renderTarget)

	self.renderTargetHandle = nil

	DuiBrowser.renderTargets[self.renderTarget].browsers[self] = nil
end

function DuiBrowser:new(phonographHandle, model, renderTarget)
	local self = Class.new(self)

	self.phonographHandle = phonographHandle
	self.duiObject = CreateDui(Config.dui.url, Config.dui.screenWidth, Config.dui.screenHeight)
	self.handle = GetDuiHandle(self.duiObject)
	self.txdName = "phono_txd_" .. tostring(phonographHandle)
	self.txnName = "video"
	self.txd = CreateRuntimeTxd(self.txdName)
	self.txn = CreateRuntimeTextureFromDuiHandle(self.txd, self.txnName, self.handle)
	self.model = model
	self.renderTarget = renderTarget
	self.drawSprite = true

	DuiBrowser.pool[phonographHandle] = self

	if not DuiBrowser.renderTargets[renderTarget] then
		DuiBrowser.renderTargets[renderTarget] = {
			disabled = false,
			browsers = {}
		}
	end

	self:waitForConnection()

	return self
end

local foo = false

function DuiBrowser:renderFrame(drawSprite)
	if DuiBrowser.renderTargets[self.renderTarget].disabled then
		return
	end

	self:enableRenderTarget()

	SetTextRenderId(self.renderTargetHandle)
	Set_2dLayer(4)
	SetScriptGfxDrawBehindPausemenu(1)

	DrawRect(0.5, 0.5, 1.0, 1.0, 0, 0, 0, 255)

	if drawSprite then
		DrawSprite(self.txdName, self.txnName, 0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, 255)
	end

	SetTextRenderId(GetDefaultScriptRendertargetRenderId())
	SetScriptGfxDrawBehindPausemenu(0)
end

function DuiBrowser:draw()
	self:renderFrame(true)
end

function DuiBrowser:doesBrowserExistForRenderTarget(renderTarget)
	for handle, duiBrowser in pairs(DuiBrowser.pool) do
		if duiBrowser.renderTarget == renderTarget then
			return true
		end
	end

	return false
end

function DuiBrowser:getBrowserForHandle(handle)
	return DuiBrowser.pool[handle]
end

function DuiBrowser:sendMessage(data)
	SendDuiMessage(self.duiObject, json.encode(data))
end

function DuiBrowser:isAvailable()
	return IsDuiAvailable(self.duiObject)
end

function DuiBrowser:delete()
	self:renderFrame(false)
	DuiBrowser.renderTargets[self.renderTarget].disabled = true
	Citizen.Wait(50)
	DuiBrowser.renderTargets[self.renderTarget].disabled = false

	DuiBrowser.pool[self.phonographHandle] = nil

	DestroyDui(self.duiObject)

	for duiBrowser, _ in pairs(DuiBrowser.renderTargets[self.renderTarget].browsers) do
		duiBrowser:disableRenderTarget()
	end
end

RegisterNUICallback("DuiBrowser:initDone", function(data, cb)
	DuiBrowser.pool[data.handle].initDone = true
	cb({})
end)
