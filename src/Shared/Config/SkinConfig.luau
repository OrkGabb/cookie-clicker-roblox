--!strict
local Types = require(script.Parent.Parent.Types)

--[[
	unlockType:
	  "default"     → always owned
	  "milestone"   → unlockValue = lifetime cookies required
	  "robux"       → unlockValue = gamepass/product ID
	  "achievement" → unlockValue = achievement ID (string hash mapped to int)
]]

local SkinConfig: {Types.SkinDefinition} = {
	{
		id           = "classic",
		name         = "Original Recipe",
		description  = "A timeless sugar cookie, straight from grandma's recipe.",
		unlockType   = "default",
		unlockValue  = 0,
		cookieIcon   = "⬡",
		miniIcon     = "⬡",
		gradientA    = Color3.fromHex("#D4956A"),
		gradientB    = Color3.fromHex("#F5C89A"),
		borderColor  = Color3.fromHex("#8B5E3C"),
		accentColor  = Color3.fromHex("#FFB347"),
	},
	{
		id           = "golden_hour",
		name         = "Golden Hour",
		description  = "Glazed in liquid gold. Dazzling.",
		unlockType   = "milestone",
		unlockValue  = 1000,
		cookieIcon   = "⨠",
		miniIcon     = "⨿",
		gradientA    = Color3.fromHex("#FFD700"),
		gradientB    = Color3.fromHex("#FFA500"),
		borderColor  = Color3.fromHex("#CC8800"),
		accentColor  = Color3.fromHex("#FFEC80"),
	},
	{
		id           = "frosted_fantasia",
		name         = "Frosted Fantasia",
		description  = "Iced in winter magic. Cool and serene.",
		unlockType   = "milestone",
		unlockValue  = 10000,
		cookieIcon   = "≬",
		miniIcon     = "≬",
		gradientA    = Color3.fromHex("#A8D8F0"),
		gradientB    = Color3.fromHex("#E8F6FF"),
		borderColor  = Color3.fromHex("#6AABCC"),
		accentColor  = Color3.fromHex("#C0EEFF"),
	},
	{
		id           = "rainbow_revelry",
		name         = "Rainbow Revelry",
		description  = "Every bite is a different colour of joy.",
		unlockType   = "milestone",
		unlockValue  = 100000,
		cookieIcon   = "⨳",
		miniIcon     = "⪽",
		gradientA    = Color3.fromHex("#FF6EC7"),
		gradientB    = Color3.fromHex("#9B59B6"),
		borderColor  = Color3.fromHex("#FF1493"),
		accentColor  = Color3.fromHex("#FFD700"),
	},
	{
		id           = "midnight_macaron",
		name         = "Midnight Macaron",
		description  = "A cookie forged at the witching hour.",
		unlockType   = "milestone",
		unlockValue  = 1000000,
		cookieIcon   = "∢",
		miniIcon     = "⨠",
		gradientA    = Color3.fromHex("#1A1A3E"),
		gradientB    = Color3.fromHex("#3D2B6B"),
		borderColor  = Color3.fromHex("#7B2FBE"),
		accentColor  = Color3.fromHex("#8B5CF6"),
	},
	{
		id           = "crystal_glaze",
		name         = "Crystal Glaze",
		description  = "Refracts light into a thousand prismatic hues.",
		unlockType   = "milestone",
		unlockValue  = 10000000,
		cookieIcon   = "⧉",
		miniIcon     = "⨕",
		gradientA    = Color3.fromHex("#A8FFF0"),
		gradientB    = Color3.fromHex("#FFFFFF"),
		borderColor  = Color3.fromHex("#00CED1"),
		accentColor  = Color3.fromHex("#7FFFD4"),
	},
	-- Robux skins (productId = placeholder, replace in Studio)
	{
		id           = "nebula_nougat",
		name         = "Nebula Nougat",
		description  = "A swirl of cosmic caramel from the edge of the galaxy.",
		unlockType   = "robux",
		unlockValue  = 1001,  -- gamepass ID placeholder
		cookieIcon   = "∰",
		miniIcon     = "⨰",
		gradientA    = Color3.fromHex("#0D0D2B"),
		gradientB    = Color3.fromHex("#4B0082"),
		borderColor  = Color3.fromHex("#FF00FF"),
		accentColor  = Color3.fromHex("#DA70D6"),
	},
	{
		id           = "diamond_dust",
		name         = "Diamond Dust",
		description  = "The rarest cookie in the universe. Flexes hard.",
		unlockType   = "robux",
		unlockValue  = 1002,  -- gamepass ID placeholder
		cookieIcon   = "⬢",
		miniIcon     = "◆",
		gradientA    = Color3.fromHex("#B0E0FF"),
		gradientB    = Color3.fromHex("#FFFFFF"),
		borderColor  = Color3.fromHex("#4FC3F7"),
		accentColor  = Color3.fromHex("#81D4FA"),
	},
	{
		id           = "ember_eclair",
		name         = "Ember Éclair",
		description  = "Forged in a volcano. Still warm.",
		unlockType   = "robux",
		unlockValue  = 1003,  -- gamepass ID placeholder
		cookieIcon   = "⨼",
		miniIcon     = "⨽",
		gradientA    = Color3.fromHex("#CC2200"),
		gradientB    = Color3.fromHex("#FF8C00"),
		borderColor  = Color3.fromHex("#8B0000"),
		accentColor  = Color3.fromHex("#FFD700"),
	},
}

-- Fast lookup by id
local SkinMap: {[string]: Types.SkinDefinition} = {}
for _, skin in ipairs(SkinConfig) do
	SkinMap[skin.id] = skin
end

return {
	Skins    = SkinConfig,
	SkinMap  = SkinMap,
	Default  = SkinConfig[1],
}
