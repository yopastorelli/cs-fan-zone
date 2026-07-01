local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local VisualKit = require(Shared:WaitForChild("VisualKit"))

local requestedTier = (Config.Visual and Config.Visual.VisualQualityDefault) or "Low"
local qualityTier = VisualKit.QualityTiers[requestedTier] and requestedTier or "Low"
local lighting = VisualKit.LightingPresets[qualityTier]

pcall(function()
    Lighting.Technology = VisualKit.QualityTiers[qualityTier].Technology
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
atmosphere.Haze = lighting.AtmosphereHaze
atmosphere.Glare = lighting.AtmosphereGlare

local bloom = ensureEffect("BloomEffect", "CSFanZoneBloom")
bloom.Intensity = lighting.BloomIntensity
bloom.Size = lighting.BloomSize
bloom.Threshold = lighting.BloomThreshold

local colorCorrection = ensureEffect("ColorCorrectionEffect", "CSFanZoneColor")
colorCorrection.Contrast = lighting.Contrast
colorCorrection.Saturation = lighting.Saturation
colorCorrection.TintColor = lighting.TintColor

local sunRays = ensureEffect("SunRaysEffect", "CSFanZoneSunRays")
sunRays.Intensity = VisualKit.QualityTiers[qualityTier].UseSunRays and lighting.SunRaysIntensity or 0
sunRays.Spread = lighting.SunRaysSpread
