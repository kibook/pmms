function GetRandomPreset()
	local presets = {}

	for preset, info in pairs(Config.Presets) do
		table.insert(presets, preset)
	end

	return presets[math.random(#presets)]
end

function GetHandleFromCoords(coords)
	return GetHashKey(string.format('%f_%f_%f', coords.x, coords.y, coords.z))
end
