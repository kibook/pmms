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

DuiBrowser.initQueue = {}
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
	DuiBrowser.initQueue[self.mediaPlayerHandle] = false

	local timeWaited = 0

	while not DuiBrowser.initQueue[self.mediaPlayerHandle] and timeWaited < 5000 do
		self:sendMessage({type = "DuiBrowser:init", handle = self.mediaPlayerHandle})
		Citizen.Wait(100)
		timeWaited = timeWaited + 100
	end

	if DuiBrowser.initQueue[self.mediaPlayerHandle] then
		DuiBrowser.initQueue[self.mediaPlayerHandle] = nil
		return true
	else
		print("Failed to connect to " .. Config.dui.url)
		return false
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

function DuiBrowser:new(mediaPlayerHandle, model, renderTarget)
	local self = Class.new(self)

	self.mediaPlayerHandle = mediaPlayerHandle
	self.model = model
	self.renderTarget = renderTarget

	self.duiObject = CreateDui(Config.dui.url, Config.dui.screenWidth, Config.dui.screenHeight)
	self.handle = GetDuiHandle(self.duiObject)

	if self.renderTarget then
		self.txdName = "pmms_txd_" .. tostring(mediaPlayerHandle)
		self.txnName = "video"
		self.txd = CreateRuntimeTxd(self.txdName)
		self.txn = CreateRuntimeTextureFromDuiHandle(self.txd, self.txnName, self.handle)
	end

	if self:waitForConnection() then
		DuiBrowser.pool[self.mediaPlayerHandle] = self

		if self.renderTarget then
			if not DuiBrowser.renderTargets[self.renderTarget] then
				DuiBrowser.renderTargets[self.renderTarget] = {
					disabled = false,
					browsers = {}
				}
			end
		end

		return self
	else
		DuiBrowser.pool[self.mediaPlayerHandle] = nil
		DestroyDui(self.duiObject)
	end
end

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

function DuiBrowser:resetPool()
	for handle, duiBrowser in pairs(DuiBrowser.pool) do
		duiBrowser:delete()
	end
end

function DuiBrowser:delete()
	if self.renderTarget then
		self:renderFrame(false)
		DuiBrowser.renderTargets[self.renderTarget].disabled = true
		Citizen.Wait(50)
		DuiBrowser.renderTargets[self.renderTarget].disabled = false
	end

	DuiBrowser.pool[self.mediaPlayerHandle] = nil

	DestroyDui(self.duiObject)

	if self.renderTarget then
		for duiBrowser, _ in pairs(DuiBrowser.renderTargets[self.renderTarget].browsers) do
			duiBrowser:disableRenderTarget()
		end
	end
end

RegisterNUICallback("DuiBrowser:initDone", function(data, cb)
	DuiBrowser.initQueue[data.handle] = true
	cb({})
end)
