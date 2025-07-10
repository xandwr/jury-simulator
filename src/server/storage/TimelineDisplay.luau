-- ServerStorage/TimelineDisplay
-- In-world holographic timeline for case events and jury reactions

local TweenService = game:GetService("TweenService")

local TimelineDisplay = {}

-- Display configuration
local TIMELINE_CONFIG = {
	displayPart = nil, -- Will be set to courtroom display
	maxEvents = 10, -- Maximum events to show at once

	colors = {
		Opening = Color3.fromRGB(100, 100, 255), -- Blue
		Prosecution = Color3.fromRGB(255, 100, 100), -- Red
		Defense = Color3.fromRGB(100, 255, 100), -- Green
		Technical = Color3.fromRGB(255, 200, 100), -- Orange
		Deliberation = Color3.fromRGB(200, 100, 255), -- Purple
	},

	eventHeight = 60,
	transitionTime = 0.8,
	textSize = 14,
}

-- Event history
local eventHistory = {}
local currentPhase = "Pre-Trial"

-- Create or find the timeline display part
function TimelineDisplay.initialize()
	local displayPart = workspace:FindFirstChild("TimelineDisplay")

	if not displayPart then
		-- Create display part
		displayPart = Instance.new("Part")
		displayPart.Name = "TimelineDisplay"
		displayPart.Size = Vector3.new(12, 8, 0.2)
		displayPart.Material = Enum.Material.SmoothPlastic
		displayPart.Color = Color3.fromRGB(20, 20, 30)
		displayPart.Anchored = true
		displayPart.CanCollide = false

		-- Position in courtroom (adjust as needed)
		displayPart.CFrame = CFrame.new(0, 10, -20)
		displayPart.Parent = workspace

		-- Add glow effect
		local pointLight = Instance.new("PointLight")
		pointLight.Brightness = 0.5
		pointLight.Range = 15
		pointLight.Color = Color3.fromRGB(100, 150, 255)
		pointLight.Parent = displayPart
	end

	TIMELINE_CONFIG.displayPart = displayPart
	TimelineDisplay.createDisplayInterface()

	print("[TimelineDisplay] Initialized holographic display")
	return displayPart
end

-- Create the main display interface
function TimelineDisplay.createDisplayInterface()
	local displayPart = TIMELINE_CONFIG.displayPart
	if not displayPart then
		return
	end

	-- Clear existing GUI
	local existingGui = displayPart:FindFirstChild("TimelineGUI")
	if existingGui then
		existingGui:Destroy()
	end

	-- Create main surface GUI
	local gui = Instance.new("SurfaceGui")
	gui.Name = "TimelineGUI"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(1200, 800)
	gui.Parent = displayPart

	-- Background frame
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(10, 15, 25)
	background.BackgroundTransparency = 0.1
	background.BorderSizePixel = 0
	background.Parent = gui

	-- Add subtle gradient
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 20, 35)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 10, 20)),
	})
	gradient.Rotation = 45
	gradient.Parent = background

	-- Header
	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 80)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.BackgroundTransparency = 1
	header.Text = "CASE TIMELINE - LIVE"
	header.TextColor3 = Color3.fromRGB(100, 200, 255)
	header.TextScaled = true
	header.Font = Enum.Font.SourceSansBold
	header.Parent = background

	-- Phase indicator
	local phaseLabel = Instance.new("TextLabel")
	phaseLabel.Name = "PhaseLabel"
	phaseLabel.Size = UDim2.new(1, -20, 0, 40)
	phaseLabel.Position = UDim2.new(0, 10, 0, 80)
	phaseLabel.BackgroundTransparency = 1
	phaseLabel.Text = "Phase: " .. currentPhase
	phaseLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	phaseLabel.TextScaled = true
	phaseLabel.Font = Enum.Font.SourceSans
	phaseLabel.Parent = background

	-- Events container
	local eventsFrame = Instance.new("ScrollingFrame")
	eventsFrame.Name = "EventsFrame"
	eventsFrame.Size = UDim2.new(1, -20, 1, -140)
	eventsFrame.Position = UDim2.new(0, 10, 0, 130)
	eventsFrame.BackgroundTransparency = 1
	eventsFrame.BorderSizePixel = 0
	eventsFrame.ScrollBarThickness = 8
	eventsFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 150, 255)
	eventsFrame.Parent = background

	TimelineDisplay.refreshEvents()
end

-- Add new event to timeline
function TimelineDisplay.addEvent(eventType, title, details, juryReaction)
	local timestamp = tick()
	local event = {
		type = eventType,
		title = title or "Unknown Event",
		details = details or "",
		juryReaction = juryReaction or {},
		timestamp = timestamp,
		timeString = os.date("%H:%M:%S", timestamp),
	}

	table.insert(eventHistory, event)

	-- Keep only recent events
	if #eventHistory > TIMELINE_CONFIG.maxEvents then
		table.remove(eventHistory, 1)
	end

	-- Update phase if needed
	if eventType ~= currentPhase and eventType ~= "Evidence" then
		TimelineDisplay.setPhase(eventType)
	end

	TimelineDisplay.refreshEvents()
	TimelineDisplay.animateNewEvent()

	print(`[TimelineDisplay] Added event: {title}`)
end

-- Set current phase
function TimelineDisplay.setPhase(newPhase)
	currentPhase = newPhase

	local displayPart = TIMELINE_CONFIG.displayPart
	if not displayPart then
		return
	end

	local gui = displayPart:FindFirstChild("TimelineGUI")
	if not gui then
		return
	end

	local phaseLabel = gui.Background:FindFirstChild("PhaseLabel")
	if phaseLabel then
		phaseLabel.Text = "Phase: " .. currentPhase

		-- Color code by phase
		local color = TIMELINE_CONFIG.colors[newPhase] or Color3.fromRGB(200, 200, 200)
		phaseLabel.TextColor3 = color

		-- Pulse effect
		local pulseTween = TweenService:Create(phaseLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
			TextTransparency = 0.3,
		})
		pulseTween:Play()
		pulseTween.Completed:Connect(function()
			local returnTween = TweenService:Create(phaseLabel, TweenInfo.new(0.5), {
				TextTransparency = 0,
			})
			returnTween:Play()
		end)
	end
end

-- Refresh the events display
function TimelineDisplay.refreshEvents()
	local displayPart = TIMELINE_CONFIG.displayPart
	if not displayPart then
		return
	end

	local gui = displayPart:FindFirstChild("TimelineGUI")
	if not gui then
		return
	end

	local eventsFrame = gui.Background:FindFirstChild("EventsFrame")
	if not eventsFrame then
		return
	end

	-- Clear existing events
	for _, child in ipairs(eventsFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Add events in reverse chronological order (newest first)
	for i = #eventHistory, 1, -1 do
		local event = eventHistory[i]
		local eventIndex = #eventHistory - i + 1

		TimelineDisplay.createEventFrame(eventsFrame, event, eventIndex)
	end

	-- Update canvas size
	eventsFrame.CanvasSize = UDim2.new(0, 0, 0, #eventHistory * TIMELINE_CONFIG.eventHeight)
end

-- Create individual event frame
function TimelineDisplay.createEventFrame(parent, event, index)
	local yPos = (index - 1) * TIMELINE_CONFIG.eventHeight

	-- Main event frame
	local eventFrame = Instance.new("Frame")
	eventFrame.Name = "Event_" .. index
	eventFrame.Size = UDim2.new(1, -10, 0, TIMELINE_CONFIG.eventHeight - 10)
	eventFrame.Position = UDim2.new(0, 5, 0, yPos + 5)
	eventFrame.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
	eventFrame.BorderSizePixel = 0
	eventFrame.Parent = parent

	-- Round corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = eventFrame

	-- Color stripe based on event type
	local colorStripe = Instance.new("Frame")
	colorStripe.Size = UDim2.new(0, 5, 1, 0)
	colorStripe.Position = UDim2.new(0, 0, 0, 0)
	colorStripe.BackgroundColor3 = TIMELINE_CONFIG.colors[event.type] or Color3.fromRGB(100, 100, 100)
	colorStripe.BorderSizePixel = 0
	colorStripe.Parent = eventFrame

	local stripeCorner = Instance.new("UICorner")
	stripeCorner.CornerRadius = UDim.new(0, 8)
	stripeCorner.Parent = colorStripe

	-- Timestamp
	local timeLabel = Instance.new("TextLabel")
	timeLabel.Size = UDim2.new(0, 80, 0, 20)
	timeLabel.Position = UDim2.new(0, 15, 0, 5)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Text = event.timeString
	timeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	timeLabel.TextScaled = true
	timeLabel.Font = Enum.Font.SourceSans
	timeLabel.TextXAlignment = Enum.TextXAlignment.Left
	timeLabel.Parent = eventFrame

	-- Event type badge
	local typeBadge = Instance.new("TextLabel")
	typeBadge.Size = UDim2.new(0, 100, 0, 20)
	typeBadge.Position = UDim2.new(0, 15, 0, 25)
	typeBadge.BackgroundColor3 = TIMELINE_CONFIG.colors[event.type] or Color3.fromRGB(100, 100, 100)
	typeBadge.Text = event.type:upper()
	typeBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
	typeBadge.TextScaled = true
	typeBadge.Font = Enum.Font.SourceSansBold
	typeBadge.Parent = eventFrame

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 4)
	badgeCorner.Parent = typeBadge

	-- Event title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -130, 0, 20)
	titleLabel.Position = UDim2.new(0, 125, 0, 25)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = event.title
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = eventFrame

	-- Event details (if any)
	if event.details ~= "" then
		local detailsLabel = Instance.new("TextLabel")
		detailsLabel.Size = UDim2.new(1, -20, 0, 15)
		detailsLabel.Position = UDim2.new(0, 15, 1, -20)
		detailsLabel.BackgroundTransparency = 1
		detailsLabel.Text = event.details
		detailsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		detailsLabel.TextScaled = true
		detailsLabel.Font = Enum.Font.SourceSans
		detailsLabel.TextXAlignment = Enum.TextXAlignment.Left
		detailsLabel.Parent = eventFrame
	end
end

-- Animate new event appearance
function TimelineDisplay.animateNewEvent()
	local displayPart = TIMELINE_CONFIG.displayPart
	if not displayPart then
		return
	end

	local gui = displayPart:FindFirstChild("TimelineGUI")
	if not gui then
		return
	end

	local eventsFrame = gui.Background:FindFirstChild("EventsFrame")
	if not eventsFrame then
		return
	end

	local latestEvent = eventsFrame:FindFirstChild("Event_1")
	if not latestEvent then
		return
	end

	-- Start invisible and slide in
	latestEvent.Position = latestEvent.Position + UDim2.new(1, 0, 0, 0)
	latestEvent.BackgroundTransparency = 1

	-- Animate appearance
	local slideTween =
		TweenService:Create(latestEvent, TweenInfo.new(TIMELINE_CONFIG.transitionTime, Enum.EasingStyle.Quart), {
			Position = latestEvent.Position - UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 0,
		})
	slideTween:Play()

	-- Flash effect
	local originalColor = latestEvent.BackgroundColor3
	latestEvent.BackgroundColor3 = Color3.fromRGB(100, 200, 255)

	task.delay(0.5, function()
		local colorTween = TweenService:Create(latestEvent, TweenInfo.new(1), {
			BackgroundColor3 = originalColor,
		})
		colorTween:Play()
	end)
end

-- Add jury reaction summary to latest event
function TimelineDisplay.addJuryReaction(summary)
	if #eventHistory == 0 then
		return
	end

	local latestEvent = eventHistory[#eventHistory]
	latestEvent.juryReaction = summary
	latestEvent.details =
		`Jury Impact: ${summary.highImpactJurors or 0} strong reactions, ${summary.averageCoherence or 0}% avg coherence`

	TimelineDisplay.refreshEvents()
end

-- Helper function to integrate with evidence presentation
function TimelineDisplay.onEvidencePresented(evidence, juryReactions)
	local _evidenceType = evidence.Type or "Evidence"
	local title = evidence.Id or "Unknown Evidence"
	local direction = evidence.Direction == "For" and "PROSECUTION" or "DEFENSE"

	TimelineDisplay.addEvent(
		"Evidence",
		`${direction}: ${title}`,
		`Strength: ${math.floor((evidence.Strength or 0) * 100)}% | Complexity: ${math.floor(
			(evidence.Complexity or 0) * 100
		)}%`,
		juryReactions
	)
end

-- Helper function to integrate with deliberation phases
function TimelineDisplay.onDeliberationPhase(phase, details)
	TimelineDisplay.addEvent("Deliberation", `${phase} Phase`, details or "")
end

-- Helper function to show voting results
function TimelineDisplay.onVote(voteResult)
	local voteDetails =
		`Guilty: ${voteResult.votes.guilty} | Not Guilty: ${voteResult.votes.notGuilty} | Undecided: ${voteResult.votes.undecided}`
	TimelineDisplay.addEvent("Deliberation", `${voteResult.type} Vote`, voteDetails)
end

-- Get current display state for debugging
function TimelineDisplay.getStatus()
	return {
		initialized = TIMELINE_CONFIG.displayPart ~= nil,
		eventCount = #eventHistory,
		currentPhase = currentPhase,
		displayPosition = TIMELINE_CONFIG.displayPart and TIMELINE_CONFIG.displayPart.Position or Vector3.new(),
	}
end

return TimelineDisplay
