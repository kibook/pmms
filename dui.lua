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
DuiBrowser.scaleforms = {}

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

	DuiBrowser.initQueue[self.mediaPlayerHandle] = self

	local timeout = GetGameTimer() + Config.dui.timeout

	while not DuiBrowser.initQueue[self.mediaPlayerHandle].initDone and GetGameTimer() < timeout do
		self:sendMessage({type = "DuiBrowser:init", handle = self.mediaPlayerHandle})
		Citizen.Wait(100)
	end

	DuiBrowser.initQueue[self.mediaPlayerHandle] = nil

	if self.initDone then
		return true
	else
		print(("Failed to initialize DUI browser: Could not connect to %s within %d ms"):format(self.duiUrl, Config.dui.timeout))
		return false
	end
end

function DuiBrowser:enableRenderTarget()
	if not self.renderTarget then
		return
	end

	if self.renderTargetHandle then
		return
	end

	self.renderTargetHandle = self:createNamedRendertargetForModel(self.model, self.renderTarget)

	DuiBrowser.renderTargets[self.renderTarget].browsers[self] = true
end

function DuiBrowser:disableRenderTarget()
	if not self.renderTarget then
		return
	end

	if not self.renderTargetHandle then
		return
	end

	ReleaseNamedRendertarget(self.renderTarget)

	self.renderTargetHandle = nil

	DuiBrowser.renderTargets[self.renderTarget].browsers[self] = nil
end

function DuiBrowser:createTexture()
	self.txdName = "pmms_txd_" .. tostring(self.mediaPlayerHandle)
	self.txnName = "video"
	self.txd = CreateRuntimeTxd(self.txdName)
	self.txn = CreateRuntimeTextureFromDuiHandle(self.txd, self.txnName, self.duiHandle)
end

function DuiBrowser:loadScaleform()
	local timeout = GetGameTimer() + 5000

	while not HasScaleformMovieLoaded(self.sfHandle) and GetGameTimer() < timeout do
		Citizen.Wait(0)
	end

	return HasScaleformMovieLoaded(self.sfHandle)
end

function DuiBrowser:enableScaleform()
	if self.sfHandle then
		return
	end

	self.sfHandle = RequestScaleformMovie(self.sfName)

	if self:loadScaleform() then
		self:createTexture()

		BeginScaleformMovieMethod(self.sfHandle, "SET_TEXTURE")
		ScaleformMovieMethodAddParamTextureNameString(self.txdName)
		ScaleformMovieMethodAddParamTextureNameString(self.txnName)
		ScaleformMovieMethodAddParamInt(0)
		ScaleformMovieMethodAddParamInt(0)
		ScaleformMovieMethodAddParamInt(Config.dui.screenWidth)
		ScaleformMovieMethodAddParamInt(Config.dui.screenHeight)

		EndScaleformMovieMethod()

		DuiBrowser.scaleforms[self.sfName].browsers[self] = true
	else
		print(("Failed to load scaleform %s"):format(self.sfName))
	end
end

function DuiBrowser:disableScaleform()
	if not self.sfHandle then
		return
	end

	self.sfHandle = nil

	DuiBrowser.scaleforms[self.sfName].browsers[self] = nil

	SetScaleformMovieAsNoLongerNeeded(self.sfHandle)
end

function DuiBrowser:enable()
	if self.renderTarget then
		self:enableRenderTarget()
	elseif self.scaleform then
		self:enableScaleform()
	end
end

function DuiBrowser:disable()
	if self.renderTarget then
		self:disableRenderTarget()
	elseif self.scaleform then
		self:disableScaleform()
	end
end

function DuiBrowser:new(mediaPlayerHandle, model, renderTarget, scaleform, url)
	local self = Class.new(self)

	if DuiBrowser.initQueue[mediaPlayerHandle] then
		return DuiBrowser.initQueue[mediaPlayerHandle]
	end

	self.mediaPlayerHandle = mediaPlayerHandle
	self.model = model

	if scaleform then
		self.scaleform = scaleform
	else
		self.renderTarget = renderTarget
	end

	local thisResource = GetCurrentResourceName()

	local useHttps = url:sub(1, 8) == "https://"

	if useHttps then
		self.duiUrl = Config.dui.urls.https
	else
		if Config.dui.urls.http then
			self.duiUrl = Config.dui.urls.http
		else
			self.duiUrl = ("http://%s/%s/dui/"):format(GetCurrentServerEndpoint(), thisResource)
		end
	end

	self.duiObject = CreateDui(self.duiUrl .. "?resourceName=" .. thisResource, Config.dui.screenWidth, Config.dui.screenHeight)
	self.duiHandle = GetDuiHandle(self.duiObject)

	if self.renderTarget or self.scaleform then
		self:createTexture()

		if self.scaleform then
			self.sfName = self.scaleform.name or Config.defaultScaleformName
		end
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
		elseif self.scaleform then
			if not DuiBrowser.scaleforms[self.sfName] then
				DuiBrowser.scaleforms[self.sfName] = {
					disabled = false,
					browsers = {}
				}
			end
		end

		return self
	else
		DuiBrowser.pool[self.mediaPlayerHandle] = nil
		DestroyDui(self.duiObject)
		return nil
	end
end

function DuiBrowser:renderFrame(drawSprite)
	if self.renderTarget then
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
	elseif self.scaleform then
		if DuiBrowser.scaleforms[self.sfName].disabled then
			return
		end

		self:enableScaleform()

		DrawScaleformMovie_3dSolid(self.sfHandle,
			self.scaleform.finalPosition or self.scaleform.position,
			self.scaleform.finalRotation or self.scaleform.rotation,
			2.0, 2.0, 1.0,
			self.scaleform.scale,
			2)
	end
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

function DuiBrowser:isDrawable()
	return self.renderTarget ~= nil or self.scaleform ~= nil
end

function DuiBrowser:getDrawableName()
	if self.renderTarget then
		return self.renderTarget
	elseif self.scaleform then
		return self.sfName
	end
end

function DuiBrowser:setScaleform(scaleform)
	self.scaleform = scaleform
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
	elseif self.scaleform then
		for duiBrowser, _ in pairs(DuiBrowser.scaleforms[self.sfName].browsers) do
			duiBrowser:disableScaleform()
		end
	end
end

RegisterNUICallback("DuiBrowser:initDone", function(data, cb)
	if DuiBrowser.initQueue[data.handle] then
		DuiBrowser.initQueue[data.handle].initDone = true
	end
	cb({})
end)
