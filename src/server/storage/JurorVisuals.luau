-- ServerStorage/JurorVisuals
-- Diegetic visualization of cognitive processes in jury simulation

local TweenService = game:GetService("TweenService")

local JurorVisuals = {}

-- Visual effect configurations
local EFFECT_CONFIG = {
	BeliefHalo = {
		colors = {
			guilt = Color3.fromRGB(220, 50, 50), -- Red for guilt
			doubt = Color3.fromRGB(50, 150, 220), -- Blue for doubt
			confusion = Color3.fromRGB(150, 150, 50), -- Yellow for confusion
			clarity = Color3.fromRGB(50, 220, 100), -- Green for clarity
		},
		maxRadius = 3,
		pulseIntensity = 0.8,
		duration = 2.0,
	},

	ThoughtBubble = {
		maxDistance = 5,
		fadeTime = 3.0,
		floatHeight = 2.0,
	},

	CoherenceCracks = {
		threshold = 0.3, -- Show cracks when coherence drops below 30%
		intensity = 0.7,
		duration = 1.5,
	},

	BeliefPulse = {
		colors = {
			WitnessCredibility = Color3.fromRGB(255, 200, 100),
			PhysicalEvidence = Color3.fromRGB(100, 255, 150),
			Timeline = Color3.fromRGB(150, 100, 255),
			DefendantCharacter = Color3.fromRGB(255, 150, 200),
		},
	},
}

-- Thought phrases for different cognitive states
local THOUGHT_PHRASES = {
	highMeaning = {
		"Wait... that changes everything!",
		"Now I see the connection!",
		"This doesn't add up...",
		"That's the missing piece!",
		"I need to reconsider...",
	},

	lowCoherence = {
		"I'm so confused...",
		"Nothing makes sense anymore...",
		"Too much to process...",
		"My head is spinning...",
		"I can't think straight...",
	},

	strongGuilt = {
		"He definitely did it.",
		"The evidence is clear.",
		"All roads lead to guilt.",
		"No reasonable doubt here.",
	},

	strongDoubt = {
		"Something's not right...",
		"I have serious doubts.",
		"The evidence is weak.",
		"Innocent until proven guilty.",
	},
}

-- Create belief halo effect around juror's head
function JurorVisuals.createBeliefHalo(jurorModel, beliefType, intensity)
	local head = jurorModel:FindFirstChild("Head")
	if not head then
		return
	end

	-- Remove existing halo
	local existingHalo = head:FindFirstChild("BeliefHalo")
	if existingHalo then
		existingHalo:Destroy()
	end

	-- Create new halo
	local halo = Instance.new("Part")
	halo.Name = "BeliefHalo"
	halo.Shape = Enum.PartType.Cylinder
	halo.Material = Enum.Material.Neon
	halo.Anchored = true
	halo.CanCollide = false
	halo.Size = Vector3.new(0.1, 4, 4)
	halo.CFrame = head.CFrame * CFrame.Angles(0, 0, math.rad(90))
	halo.CFrame = halo.CFrame + head.CFrame.LookVector * -1

	-- Set color based on belief type
	local config = EFFECT_CONFIG.BeliefHalo
	local color = config.colors[beliefType] or config.colors.confusion
	halo.Color = color

	-- Set initial transparency
	halo.Transparency = 0.3
	halo.Parent = head

	-- Pulse effect based on intensity
	local pulseInfo = TweenInfo.new(
		config.duration,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut,
		-1, -- Infinite repeats
		true -- Reverse
	)

	local targetSize = config.maxRadius * (0.5 + intensity * 0.5)
	local pulseTween = TweenService:Create(halo, pulseInfo, {
		Size = Vector3.new(0.1, targetSize, targetSize),
		Transparency = 0.1 + (1 - intensity) * 0.6,
	})

	pulseTween:Play()

	-- Auto-cleanup after effect duration
	task.delay(config.duration * 3, function()
		if halo and halo.Parent then
			local fadeTween = TweenService:Create(halo, TweenInfo.new(1), {
				Transparency = 1,
				Size = Vector3.new(0.1, 1, 1),
			})
			fadeTween:Play()
			fadeTween.Completed:Connect(function()
				halo:Destroy()
			end)
		end
	end)

	return halo
end

-- Show floating thought phrase near juror
function JurorVisuals.showThoughtBubble(jurorModel, phrase, _thoughtType)
	local head = jurorModel:FindFirstChild("Head")
	if not head then
		return
	end

	-- Create billboard GUI
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ThoughtBubble"
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset =
		Vector3.new(math.random(-2, 2), EFFECT_CONFIG.ThoughtBubble.floatHeight + math.random(0, 1), math.random(-2, 2))
	billboard.Parent = head

	-- Create text label
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 0.8
	textLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.SourceSansItalic
	textLabel.Text = phrase
	textLabel.TextTransparency = 0
	textLabel.Parent = billboard

	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = textLabel

	-- Animate appearance
	local appearTween = TweenService:Create(textLabel, TweenInfo.new(0.5), {
		TextTransparency = 0,
		BackgroundTransparency = 0.3,
	})
	appearTween:Play()

	-- Float upward and fade
	local floatTween = TweenService:Create(billboard, TweenInfo.new(EFFECT_CONFIG.ThoughtBubble.fadeTime), {
		StudsOffset = billboard.StudsOffset + Vector3.new(0, 2, 0),
	})

	local fadeTween = TweenService:Create(textLabel, TweenInfo.new(EFFECT_CONFIG.ThoughtBubble.fadeTime), {
		TextTransparency = 1,
		BackgroundTransparency = 1,
	})

	floatTween:Play()
	fadeTween:Play()

	-- Cleanup
	fadeTween.Completed:Connect(function()
		billboard:Destroy()
	end)
end

-- Create coherence crack effect on juror's face
function JurorVisuals.showCoherenceCracks(jurorModel, coherence)
	local head = jurorModel:FindFirstChild("Head")
	if not head then
		return
	end

	-- Only show if coherence is very low
	if coherence > EFFECT_CONFIG.CoherenceCracks.threshold then
		return
	end

	-- Remove existing cracks
	local existingCracks = head:FindFirstChild("CoherenceCracks")
	if existingCracks then
		existingCracks:Destroy()
	end

	-- Create crack overlay
	local cracksGui = Instance.new("SurfaceGui")
	cracksGui.Name = "CoherenceCracks"
	cracksGui.Face = Enum.NormalId.Front
	cracksGui.Parent = head

	-- Create crack pattern
	local crackFrame = Instance.new("Frame")
	crackFrame.Size = UDim2.new(1, 0, 1, 0)
	crackFrame.BackgroundTransparency = 1
	crackFrame.Parent = cracksGui

	-- Add multiple crack lines
	for _ = 1, math.random(3, 6) do
		local crack = Instance.new("Frame")
		crack.Size = UDim2.new(math.random(50, 100) / 100, 0, 0, 2)
		crack.Position = UDim2.new(math.random(0, 50) / 100, 0, math.random(0, 100) / 100, 0)
		crack.Rotation = math.random(-45, 45)
		crack.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
		crack.BorderSizePixel = 0
		crack.Parent = crackFrame

		-- Animate crack appearance
		crack.Size = UDim2.new(0, 0, 0, 2)
		local crackTween = TweenService:Create(crack, TweenInfo.new(0.3), {
			Size = UDim2.new(math.random(50, 100) / 100, 0, 0, 2),
		})
		crackTween:Play()
	end

	-- Fade out cracks after duration
	task.delay(EFFECT_CONFIG.CoherenceCracks.duration, function()
		if cracksGui and cracksGui.Parent then
			local fadeFrame = TweenService:Create(crackFrame, TweenInfo.new(1), {
				BackgroundTransparency = 1,
			})
			fadeFrame:Play()
			fadeFrame.Completed:Connect(function()
				cracksGui:Destroy()
			end)
		end
	end)
end

-- Create belief pulse network effect
function JurorVisuals.showBeliefPulse(jurorModel, affectedNodes, strength)
	local humanoidRootPart = jurorModel:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	-- Create temporary attachment points for the pulse
	local attachments = {}
	local bodyParts = { "Head", "Left Arm", "Right Arm", "Torso" }

	for _, partName in ipairs(bodyParts) do
		local part = jurorModel:FindFirstChild(partName)
		if part then
			local attachment = Instance.new("Attachment")
			attachment.Name = "PulsePoint"
			attachment.Position = Vector3.new(math.random(-1, 1), math.random(-1, 1), math.random(-1, 1))
			attachment.Parent = part
			table.insert(attachments, attachment)
		end
	end

	-- Create beam effects between attachments
	for i = 1, #attachments - 1 do
		for j = i + 1, #attachments do
			local beam = Instance.new("Beam")
			beam.Attachment0 = attachments[i]
			beam.Attachment1 = attachments[j]
			beam.Width0 = 0.1
			beam.Width1 = 0.1
			beam.Transparency = NumberSequence.new(0.5)

			-- Color based on primary affected node
			local primaryNode = affectedNodes[1] or "confusion"
			beam.Color =
				ColorSequence.new(EFFECT_CONFIG.BeliefPulse.colors[primaryNode] or Color3.fromRGB(255, 255, 255))

			beam.Parent = workspace

			-- Pulse effect
			local pulseTween = TweenService:Create(beam, TweenInfo.new(1, Enum.EasingStyle.Quad), {
				Transparency = NumberSequence.new(1),
				Width0 = 0.5 * strength,
				Width1 = 0.5 * strength,
			})
			pulseTween:Play()
			pulseTween.Completed:Connect(function()
				beam:Destroy()
			end)
		end
	end

	-- Cleanup attachments
	task.delay(1.5, function()
		for _, attachment in ipairs(attachments) do
			if attachment and attachment.Parent then
				attachment:Destroy()
			end
		end
	end)
end

-- Main function to trigger insight effect (high meaning moment)
function JurorVisuals.triggerInsightEffect(jurorModel, beliefType, intensity)
	-- Combine multiple effects for dramatic impact
	JurorVisuals.createBeliefHalo(jurorModel, beliefType or "clarity", intensity or 0.8)

	-- Select appropriate thought phrase
	local phrases = THOUGHT_PHRASES.highMeaning
	local phrase = phrases[math.random(1, #phrases)]
	JurorVisuals.showThoughtBubble(jurorModel, phrase, "insight")

	-- Light flash effect
	local head = jurorModel:FindFirstChild("Head")
	if head then
		local flash = Instance.new("PointLight")
		flash.Brightness = 2
		flash.Range = 5
		flash.Color = EFFECT_CONFIG.BeliefHalo.colors.clarity
		flash.Parent = head

		local flashTween = TweenService:Create(flash, TweenInfo.new(0.5), {
			Brightness = 0,
		})
		flashTween:Play()
		flashTween.Completed:Connect(function()
			flash:Destroy()
		end)
	end
end

-- Handle belief changes with appropriate visual feedback
function JurorVisuals.onBeliefChanged(jurorModel, beliefName, oldValue, newValue, context)
	local delta = math.abs(newValue - oldValue)

	-- Significant belief change
	if delta > 0.2 then
		local beliefType = "doubt"
		if newValue > 0.6 then
			beliefType = "guilt"
		elseif newValue < 0.4 then
			beliefType = "doubt"
		end

		JurorVisuals.createBeliefHalo(jurorModel, beliefType, delta)

		-- Show belief pulse for major changes
		if delta > 0.3 and context.evidence then
			JurorVisuals.showBeliefPulse(jurorModel, context.evidence.AffectedNodes or { beliefName }, delta)
		end
	end
end

-- Handle coherence changes
function JurorVisuals.onCoherenceChanged(jurorModel, oldCoherence, newCoherence)
	local change = newCoherence - oldCoherence

	-- Show cracks for low coherence
	if newCoherence < EFFECT_CONFIG.CoherenceCracks.threshold then
		JurorVisuals.showCoherenceCracks(jurorModel, newCoherence)

		-- Show confusion thought
		local phrases = THOUGHT_PHRASES.lowCoherence
		local phrase = phrases[math.random(1, #phrases)]
		JurorVisuals.showThoughtBubble(jurorModel, phrase, "confusion")
	end

	-- Positive coherence change might show clarity
	if change > 0.2 then
		JurorVisuals.createBeliefHalo(jurorModel, "clarity", change)
	end
end

-- Auto-connect to all jurors' belief change events
function JurorVisuals.connectToJuror(juror, jurorModel)
	juror.OnBeliefChanged:Connect(function(beliefName, oldValue, newValue, context)
		JurorVisuals.onBeliefChanged(jurorModel, beliefName, oldValue, newValue, context)
	end)

	juror.OnCoherenceChanged:Connect(function(oldCoherence, newCoherence)
		JurorVisuals.onCoherenceChanged(jurorModel, oldCoherence, newCoherence)
	end)
end

-- Batch connect to all spawned jurors
function JurorVisuals.connectToAllJurors(juryRegistry)
	for _id, data in pairs(juryRegistry) do
		JurorVisuals.connectToJuror(data.juror, data.model)
	end
	print("[JurorVisuals] Connected to all jury cognitive events")
end

return JurorVisuals
