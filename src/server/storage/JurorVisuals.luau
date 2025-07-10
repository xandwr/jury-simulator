-- ServerStorage/JurorVisuals (Enhanced with Social Dynamics)
-- Diegetic visualization of cognitive and social processes in jury simulation

local TweenService = game:GetService("TweenService")

local JurorVisuals = {}

-- Enhanced visual effect configurations
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
		socialColors = {
			authority = Color3.fromRGB(255, 215, 0), -- Gold for dominant speakers
			deference = Color3.fromRGB(150, 150, 255), -- Light blue for deference
			interruption = Color3.fromRGB(255, 100, 100), -- Red for interruptions
			facilitation = Color3.fromRGB(100, 255, 150), -- Green for facilitation
		}
	},

	SocialEffects = {
		dominanceAura = {
			color = Color3.fromRGB(255, 215, 0),
			intensity = 2.0,
			pulseSpeed = 1.0,
		},
		conversationBeam = {
			color = Color3.fromRGB(100, 200, 255),
			width = 0.3,
			transparency = 0.4,
		},
		attentionFocus = {
			color = Color3.fromRGB(255, 255, 200),
			range = 10,
			intensity = 1.5,
		}
	},

	CoherenceCracks = {
		threshold = 0.3,
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

-- Enhanced thought phrases including social dynamics
local THOUGHT_PHRASES = {
	-- Existing cognitive thoughts
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

	-- New social dynamics thoughts
	authority = {
		"Everyone needs to hear this.",
		"This is important.",
		"Let me explain clearly.",
		"We need to focus here.",
		"Listen carefully to this.",
	},

	deference = {
		"They make a good point.",
		"I'll wait my turn.",
		"Let them finish.",
		"That's worth considering.",
		"I see their perspective.",
	},

	interruption = {
		"Wait, I need to say something!",
		"Hold on, that's not right!",
		"Can I jump in here?",
		"Sorry, but I disagree.",
		"I have to stop you there.",
	},

	facilitation = {
		"What does everyone think?",
		"Let's hear other opinions.",
		"We should consider all sides.",
		"Anyone else have thoughts?",
		"Let's work together on this.",
	},

	groupDiscussion = {
		"Building on that idea...",
		"That connects to...",
		"So you're saying...",
		"Let me add to that...",
		"That's exactly right.",
	},

	socialPressure = {
		"Everyone seems to agree...",
		"Am I the only one who...",
		"Maybe I'm wrong about this...",
		"The group seems certain...",
		"I don't want to hold us up...",
	}
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
	halo.Position += Vector3.new(0, -4.49, 0)

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

-- Enhanced thought bubble with social context styling
function JurorVisuals.showThoughtBubble(jurorModel, phrase, thoughtType)
	local head = jurorModel:FindFirstChild("Head")
	if not head then
		return
	end

	-- Create billboard GUI
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ThoughtBubble"
	billboard.Size = UDim2.new(0, 220, 0, 60) -- Slightly larger for social context
	billboard.StudsOffset =
		Vector3.new(math.random(-2, 2), EFFECT_CONFIG.ThoughtBubble.floatHeight + math.random(0, 1), math.random(-2, 2))
	billboard.Parent = head

	-- Create text label with social styling
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, -10, 1, -10)
	textLabel.Position = UDim2.new(0, 5, 0, 5)
	textLabel.BackgroundTransparency = 0.2
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.SourceSansItalic
	textLabel.Text = phrase
	textLabel.TextTransparency = 0
	textLabel.Parent = billboard

	-- Style based on social context
	local socialColors = EFFECT_CONFIG.ThoughtBubble.socialColors
	if socialColors[thoughtType] then
		textLabel.BackgroundColor3 = socialColors[thoughtType]
		-- Add subtle border effect for social thoughts
		local stroke = Instance.new("UIStroke")
		stroke.Color = socialColors[thoughtType]
		stroke.Thickness = 2
		stroke.Transparency = 0.5
		stroke.Parent = textLabel
	else
		textLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	end

	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = textLabel

	-- Social thought types get different animations
	local animationSpeed = 0.5
	local floatDistance = 2
	
	if thoughtType == "authority" then
		animationSpeed = 0.3 -- Slower, more deliberate
		floatDistance = 1.5
		-- Add subtle glow
		textLabel.BackgroundTransparency = 0.1
	elseif thoughtType == "interruption" then
		animationSpeed = 0.2 -- Quick, urgent
		floatDistance = 3
		-- Slight shake effect
		billboard.StudsOffset = billboard.StudsOffset + Vector3.new(math.random(-1, 1) * 0.2, 0, 0)
	elseif thoughtType == "deference" then
		animationSpeed = 0.8 -- Slower, more hesitant
		floatDistance = 1
		textLabel.BackgroundTransparency = 0.4
	end

	-- Animate appearance
	local appearTween = TweenService:Create(textLabel, TweenInfo.new(animationSpeed), {
		TextTransparency = 0,
		BackgroundTransparency = textLabel.BackgroundTransparency,
	})
	appearTween:Play()

	-- Float upward and fade
	local floatTween = TweenService:Create(billboard, TweenInfo.new(EFFECT_CONFIG.ThoughtBubble.fadeTime), {
		StudsOffset = billboard.StudsOffset + Vector3.new(0, floatDistance, 0),
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

-- Show social dominance effect
function JurorVisuals.showDominanceEffect(jurorModel, dominanceLevel)
	local humanoidRootPart = jurorModel:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Remove existing dominance effect
	local existingEffect = humanoidRootPart:FindFirstChild("DominanceEffect")
	if existingEffect then existingEffect:Destroy() end
	
	-- Create dominance aura
	local aura = Instance.new("SelectionBox")
	aura.Name = "DominanceEffect"
	aura.Adornee = jurorModel
	aura.Color3 = EFFECT_CONFIG.SocialEffects.dominanceAura.color
	aura.LineThickness = 0.3 * dominanceLevel
	aura.Transparency = 0.2
	aura.Parent = humanoidRootPart
	
	-- Enhanced pulsing effect
	local pulseInfo = TweenInfo.new(
		EFFECT_CONFIG.SocialEffects.dominanceAura.pulseSpeed, 
		Enum.EasingStyle.Sine, 
		Enum.EasingDirection.InOut, 
		-1, 
		true
	)
	local pulseTween = TweenService:Create(aura, pulseInfo, {
		Transparency = 0.05,
		LineThickness = 0.6 * dominanceLevel
	})
	pulseTween:Play()
	
	-- Add authority spotlight effect
	local spotlight = Instance.new("SpotLight")
	spotlight.Name = "AuthoritySpotlight"
	spotlight.Color = EFFECT_CONFIG.SocialEffects.dominanceAura.color
	spotlight.Brightness = EFFECT_CONFIG.SocialEffects.attentionFocus.intensity * dominanceLevel
	spotlight.Range = EFFECT_CONFIG.SocialEffects.attentionFocus.range
	spotlight.Angle = 45
	spotlight.Face = Enum.NormalId.Front
	spotlight.Parent = humanoidRootPart
	
	-- Authority voice indicator with enhanced styling
	local phrases = THOUGHT_PHRASES.authority
	local phrase = phrases[math.random(1, #phrases)]
	JurorVisuals.showThoughtBubble(jurorModel, phrase, "authority")
	
	return {aura = aura, spotlight = spotlight, pulseTween = pulseTween}
end

-- Show deference effect
function JurorVisuals.showDeferenceEffect(jurorModel, deferenceLevel)
	local humanoidRootPart = jurorModel:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Dim the juror slightly to show they're listening
	local dimEffect = Instance.new("PointLight")
	dimEffect.Name = "DeferenceEffect"
	dimEffect.Color = Color3.fromRGB(100, 100, 200)
	dimEffect.Brightness = 0.3 * deferenceLevel
	dimEffect.Range = 3
	dimEffect.Parent = humanoidRootPart
	
	-- Show deference posture effect
	local deferenceAura = Instance.new("SelectionBox")
	deferenceAura.Name = "DeferenceAura"
	deferenceAura.Adornee = jurorModel
	deferenceAura.Color3 = Color3.fromRGB(150, 150, 255)
	deferenceAura.LineThickness = 0.1
	deferenceAura.Transparency = 0.7
	deferenceAura.Parent = humanoidRootPart
	
	-- Gentle fade effect
	local fadeTween = TweenService:Create(deferenceAura, TweenInfo.new(3), {
		Transparency = 0.9
	})
	fadeTween:Play()
	
	-- Show deference thought occasionally
	if math.random() < 0.4 then
		local phrases = THOUGHT_PHRASES.deference
		local phrase = phrases[math.random(1, #phrases)]
		JurorVisuals.showThoughtBubble(jurorModel, phrase, "deference")
	end
	
	-- Auto-remove after a short time
	task.delay(4, function()
		if dimEffect and dimEffect.Parent then
			dimEffect:Destroy()
		end
		if deferenceAura and deferenceAura.Parent then
			deferenceAura:Destroy()
		end
	end)
end

-- Show interruption attempt effect
function JurorVisuals.showInterruptionEffect(jurorModel, urgency)
	local humanoidRootPart = jurorModel:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Urgent glow effect
	local urgentGlow = Instance.new("PointLight")
	urgentGlow.Name = "InterruptionGlow"
	urgentGlow.Color = Color3.fromRGB(255, 100, 100)
	urgentGlow.Brightness = 1.0 * urgency
	urgentGlow.Range = 4
	urgentGlow.Parent = humanoidRootPart
	
	-- Quick flash effect
	local flashTween = TweenService:Create(urgentGlow, TweenInfo.new(0.2), {
		Brightness = 2.0 * urgency
	})
	flashTween:Play()
	
	flashTween.Completed:Connect(function()
		local dimTween = TweenService:Create(urgentGlow, TweenInfo.new(1), {
			Brightness = 0
		})
		dimTween:Play()
		dimTween.Completed:Connect(function()
			urgentGlow:Destroy()
		end)
	end)
	
	-- Show interruption thought
	local phrases = THOUGHT_PHRASES.interruption
	local phrase = phrases[math.random(1, #phrases)]
	JurorVisuals.showThoughtBubble(jurorModel, phrase, "interruption")
end

-- Show group discussion participation effect
function JurorVisuals.showGroupParticipationEffect(jurorModel, participationLevel)
	local humanoidRootPart = jurorModel:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Collaboration glow
	local groupGlow = Instance.new("PointLight")
	groupGlow.Name = "GroupParticipation"
	groupGlow.Color = Color3.fromRGB(100, 255, 150)
	groupGlow.Brightness = 0.8 * participationLevel
	groupGlow.Range = 5
	groupGlow.Parent = humanoidRootPart
	
	-- Gentle pulsing to show active participation
	local pulseInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local pulseTween = TweenService:Create(groupGlow, pulseInfo, {
		Brightness = 1.2 * participationLevel
	})
	pulseTween:Play()
	
	-- Show group discussion thought occasionally
	if math.random() < 0.3 then
		local phrases = THOUGHT_PHRASES.groupDiscussion
		local phrase = phrases[math.random(1, #phrases)]
		JurorVisuals.showThoughtBubble(jurorModel, phrase, "groupDiscussion")
	end
	
	-- Auto-cleanup
	task.delay(8, function()
		if pulseTween then pulseTween:Cancel() end
		if groupGlow and groupGlow.Parent then
			groupGlow:Destroy()
		end
	end)
end

-- Create attention focus effect (when someone commands attention)
function JurorVisuals.createAttentionFocusEffect(focusModel, audienceModels)
	local focusRoot = focusModel:FindFirstChild("HumanoidRootPart")
	if not focusRoot then return end
	
	-- Create central attention beacon
	local beacon = Instance.new("PointLight")
	beacon.Name = "AttentionBeacon"
	beacon.Color = EFFECT_CONFIG.SocialEffects.attentionFocus.color
	beacon.Brightness = EFFECT_CONFIG.SocialEffects.attentionFocus.intensity
	beacon.Range = EFFECT_CONFIG.SocialEffects.attentionFocus.range
	beacon.Parent = focusRoot
	
	-- Create attention beams to audience members
	local beams = {}
	for _, audienceModel in ipairs(audienceModels) do
		local audienceRoot = audienceModel:FindFirstChild("HumanoidRootPart")
		if audienceRoot then
			-- Create attachment points
			local focusAttachment = Instance.new("Attachment")
			focusAttachment.Position = Vector3.new(0, 1, 0)
			focusAttachment.Parent = focusRoot
			
			local audienceAttachment = Instance.new("Attachment")
			audienceAttachment.Position = Vector3.new(0, 1, 0)
			audienceAttachment.Parent = audienceRoot
			
			-- Create beam
			local beam = Instance.new("Beam")
			beam.Attachment0 = focusAttachment
			beam.Attachment1 = audienceAttachment
			beam.Width0 = 0.1
			beam.Width1 = 0.1
			beam.Color = ColorSequence.new(EFFECT_CONFIG.SocialEffects.attentionFocus.color)
			beam.Transparency = NumberSequence.new(0.7)
			beam.FaceCamera = true
			beam.Parent = workspace
			
			table.insert(beams, {
				beam = beam,
				focusAttachment = focusAttachment,
				audienceAttachment = audienceAttachment
			})
		end
	end
	
	-- Pulse effect
	local pulseInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 3, true)
	local beaconTween = TweenService:Create(beacon, pulseInfo, {
		Brightness = EFFECT_CONFIG.SocialEffects.attentionFocus.intensity * 1.5
	})
	beaconTween:Play()
	
	-- Cleanup after effect
	task.delay(5, function()
		if beaconTween then beaconTween:Cancel() end
		if beacon and beacon.Parent then beacon:Destroy() end
		
		for _, beamData in ipairs(beams) do
			if beamData.beam and beamData.beam.Parent then beamData.beam:Destroy() end
			if beamData.focusAttachment and beamData.focusAttachment.Parent then beamData.focusAttachment:Destroy() end
			if beamData.audienceAttachment and beamData.audienceAttachment.Parent then beamData.audienceAttachment:Destroy() end
		end
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

	-- Show confusion thought
	if math.random() < 0.6 then
		local phrases = THOUGHT_PHRASES.lowCoherence
		local phrase = phrases[math.random(1, #phrases)]
		JurorVisuals.showThoughtBubble(jurorModel, phrase, "confusion")
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
	print("[JurorVisuals] Connected to all jury cognitive and social events")
end

return JurorVisuals