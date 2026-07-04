--!strict
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Declare = require(script.Parent.Parent.Declare)
local Theme = require(ReplicatedStorage.Shared.UI.Theme)
local WindowPanel = require(script.Parent.Parent.Components.WindowPanel)
local Types = require(ReplicatedStorage.Shared.Types)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Constants = require(ReplicatedStorage.Shared.Constants)
local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)
local SoundController = require(ReplicatedStorage.Shared.Util.SoundController)

-- The Auto-Clicker gamepass productId, resolved from the shop SSoT (one source of truth).
local autoClickerPassId: number? = nil
for _, product in ipairs(ShopConfig.Products) do
	if product.grantsAutoClicker then
		autoClickerPassId = product.productId
		break
	end
end

-- Volume routing lives in SoundController (single source of truth); see ApplyVolumes.
local syncVolumes = SoundController.ApplyVolumes

local function SettingsPanel(props: {
	settings: Types.ClientSettings,
	onUpdateSettings: (Types.ClientSettings) -> (),
	onClose: () -> ()
}): Instance
	local UpdateSettings = (Remotes :: any).UpdateSettings :: RemoteEvent

	-- We create deep clone to avoid mutating parent state directly before flush
	local currentSettings = table.clone(props.settings)

	-- Each control registers a closure that re-reads currentSettings into its label, so a
	-- reset can refresh every row in place (no panel rebuild / server round-trip needed).
	local refreshers: { () -> () } = {}

	local function fireUpdate()
		syncVolumes(currentSettings)
		props.onUpdateSettings(table.clone(currentSettings))
		UpdateSettings:FireServer(currentSettings)
	end

	syncVolumes(currentSettings)

	local function createSlider(name: string, key: string): Instance
		local label = Declare.TextLabel({
			Size = UDim2.fromScale(0.8, 1),
			BackgroundTransparency = 1,
			Text = name .. ": " .. tostring((currentSettings :: any)[key]) .. "%",
			Font = Theme.Fonts.Body,
			TextSize = 18,
			TextColor3 = Theme.Colors.TextPrimary,
			TextXAlignment = Enum.TextXAlignment.Left,
		})

		local function refresh()
			label.Text = name .. ": " .. tostring((currentSettings :: any)[key]) .. "%"
		end
		table.insert(refreshers, refresh)

		local function onClick()
			local val = (currentSettings :: any)[key] :: number
			val = val + 5
			if val > 100 then val = 0 end
			(currentSettings :: any)[key] = val
			fireUpdate()
			refresh()
		end

		local btn = Declare.New("TextButton")({
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundColor3 = Theme.Colors.BackgroundCream,
			Text = "",
			Children = {
				Declare.UICorner({ CornerRadius = Theme.Corners.Standard }),
				Declare.UIListLayout({ FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center }),
				Declare.UIPadding({ PaddingLeft = Theme.Padding.Standard, PaddingRight = Theme.Padding.Standard }),
				label
			},
			Events = {
				MouseButton1Click = onClick
			}
		})

		return btn
	end
	
	local function createToggle(name: string, key: string): Instance
		local label = Declare.TextLabel({
			Size = UDim2.fromScale(0.8, 1),
			BackgroundTransparency = 1,
			Text = name .. ": " .. ((currentSettings :: any)[key] and "ON" or "OFF"),
			Font = Theme.Fonts.Body,
			TextSize = 18,
			TextColor3 = Theme.Colors.TextPrimary,
			TextXAlignment = Enum.TextXAlignment.Left,
		})

		local function refresh()
			label.Text = name .. ": " .. ((currentSettings :: any)[key] and "ON" or "OFF")
		end
		table.insert(refreshers, refresh)

		local function onClick()
			local val = (currentSettings :: any)[key] :: boolean
			;(currentSettings :: any)[key] = not val
			fireUpdate()
			refresh()
		end

		local btn = Declare.New("TextButton")({
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundColor3 = Theme.Colors.BackgroundCream,
			Text = "",
			Children = {
				Declare.UICorner({ CornerRadius = Theme.Corners.Standard }),
				Declare.UIListLayout({ FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center }),
				Declare.UIPadding({ PaddingLeft = Theme.Padding.Standard, PaddingRight = Theme.Padding.Standard }),
				label
			},
			Events = {
				MouseButton1Click = onClick
			}
		})

		return btn
	end

	local resetBtnText = Declare.TextLabel({
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "Reset Settings",
		Font = Theme.Fonts.Body,
		TextSize = 18,
		TextColor3 = Theme.Colors.Danger,
	})
	
	local isConfirming = false
	local resetBtn = Declare.New("TextButton")({
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = Theme.Colors.Blush,
		Text = "",
		Children = {
			Declare.UICorner({ CornerRadius = Theme.Corners.Standard }),
			resetBtnText
		},
		Events = {
			MouseButton1Click = function()
				if not isConfirming then
					isConfirming = true
					resetBtnText.Text = "Reset all settings?"
					task.delay(3, function()
						if isConfirming then
							isConfirming = false
							resetBtnText.Text = "Reset Settings"
						end
					end)
				else
					isConfirming = false
					-- Apply the single DEFAULT_SETTINGS SSoT (music 60%, others 100%) locally
					-- for instant UI feedback, then persist via UpdateSettings. This writes
					-- ONLY settings fields — currency/upgrades are never touched.
					for k, v in pairs(Constants.DEFAULT_SETTINGS) do
						(currentSettings :: any)[k] = v
					end
					for _, r in ipairs(refreshers) do
						r()
					end
					fireUpdate()
					resetBtnText.Text = "Settings reset!"
					task.delay(1.5, function()
						resetBtnText.Text = "Reset Settings"
					end)
				end
			end
		}
	})

	local list = Declare.Frame({
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Children = {
			Declare.UIListLayout({
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = Theme.Padding.Standard,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),
			Declare.UIPadding({
				PaddingTop = Theme.Padding.Large,
				PaddingBottom = Theme.Padding.Large,
				PaddingLeft = Theme.Padding.Large,
				PaddingRight = Theme.Padding.Large,
			}),
			createSlider("Master Volume", "masterVolume"),
			createSlider("Music Volume", "musicVolume"),
			createSlider("SFX Volume", "sfxVolume"),
			createToggle("Performance Mode", "performanceMode"),
			createToggle("Notifications", "notifications"),
			Declare.Frame({ Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1 }),
			resetBtn
		}
	})

	-- Auto-Clicker toggle: owner-only. UserOwnsGamePassAsync yields, so we resolve it
	-- async and insert the row at the top of the list (LayoutOrder -1) only for owners —
	-- non-owners never see it. Reuses createToggle exactly like the other Settings rows.
	if autoClickerPassId then
		local localPlayer = Players.LocalPlayer
		task.spawn(function()
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(localPlayer.UserId, autoClickerPassId)
			end)
			-- Panel may have been closed (list destroyed) while the lookup yielded.
			if ok and owns and list.Parent ~= nil then
				local toggle = createToggle("Auto-Clicker", "autoClickerEnabled")
				;(toggle :: any).LayoutOrder = -1
				toggle.Parent = list
			end
		end)
	end

	return WindowPanel({
		title = "Settings",
		children = { list },
		onClose = props.onClose
	})
end

return SettingsPanel
