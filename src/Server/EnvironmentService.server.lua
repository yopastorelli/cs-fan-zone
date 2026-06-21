local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local VisualKit = require(Shared:WaitForChild("VisualKit"))

local lighting = VisualKit.Lighting

pcall(function()
    Lighting.Technology = Enum.Technology.Future
end)

Lighting.ClockTime = lighting.ClockTime
Lighting.Brightness = lighting.Brightness
Lighting.ExposureCompensation = lighting.ExposureCompensation
Lighting.Ambient = lighting.Ambient
Lighting.OutdoorAmbient = lighting.OutdoorAmbient

local function ensureEffect(className, name)
    local existing = Lighting:FindFirstChild(name)
    if existing and existing.ClassName == className then
        return existing
    end
    if existing then
        existing:Destroy()
    end
    local effect = Instance.new(className)
    effect.Name = name
    effect.Parent = Lighting
    return effect
end

local atmosphere = ensureEffect("Atmosphere", "CSFanZoneAtmosphere")
atmosphere.Color = lighting.AtmosphereColor
atmosphere.Decay = lighting.AtmosphereDecay
atmosphere.Density = lighting.AtmosphereDensity
atmosphere.Haze = 0.78
atmosphere.Glare = 0.04

local bloom = ensureEffect("BloomEffect", "CSFanZoneBloom")
bloom.Intensity = lighting.BloomIntensity
bloom.Size = lighting.BloomSize
bloom.Threshold = lighting.BloomThreshold

local colorCorrection = ensureEffect("ColorCorrectionEffect", "CSFanZoneColor")
colorCorrection.Contrast = lighting.Contrast
colorCorrection.Saturation = lighting.Saturation
colorCorrection.TintColor = Color3.fromRGB(255, 255, 255)

local sunRays = ensureEffect("SunRaysEffect", "CSFanZoneSunRays")
sunRays.Intensity = 0.012
sunRays.Spread = 0.64
