-- ServerStorage/JurySpawner

local HumanGenerator = require(game.ServerStorage.HumanGenerator)
local Juror = require(game.ServerStorage.Juror)

local JurySpawner = {}

-- Central registry: [JurorId] = { juror, model }
JurySpawner.Registry = {}

-- Personality archetypes for diverse jury composition
local PersonalityArchetypes = {
	{
		name = "Analytical Thinker",
		traits = { Analytical = 0.9, Emotional = 0.2, Cautious = 0.7, Decisive = 0.6, Trusting = 0.5 },
		description = "Focuses on facts and logical reasoning",
	},
	{
		name = "Emotional Responder",
		traits = { Analytical = 0.3, Emotional = 0.9, Cautious = 0.8, Decisive = 0.4, Trusting = 0.7 },
		description = "Makes decisions based on feelings and empathy",
	},
	{
		name = "Skeptical Doubter",
		traits = { Analytical = 0.7, Emotional = 0.3, Cautious = 0.9, Decisive = 0.3, Trusting = 0.2 },
		description = "Questions everything, hard to convince",
	},
	{
		name = "Quick Decider",
		traits = { Analytical = 0.5, Emotional = 0.4, Cautious = 0.2, Decisive = 0.9, Trusting = 0.6 },
		description = "Makes fast decisions and sticks to them",
	},
	{
		name = "Authority Believer",
		traits = { Analytical = 0.4, Emotional = 0.3, Cautious = 0.6, Decisive = 0.7, Trusting = 0.9 },
		description = "Trusts police, lawyers, and the system",
	},
	{
		name = "Careful Weigher",
		traits = { Analytical = 0.8, Emotional = 0.5, Cautious = 0.9, Decisive = 0.5, Trusting = 0.6 },
		description = "Thoroughly considers all evidence",
	},
	{
		name = "People Person",
		traits = { Analytical = 0.4, Emotional = 0.8, Cautious = 0.5, Decisive = 0.6, Trusting = 0.8 },
		description = "Focuses on character and relationships",
	},
	{
		name = "Independent Thinker",
		traits = { Analytical = 0.6, Emotional = 0.4, Cautious = 0.7, Decisive = 0.8, Trusting = 0.3 },
		description = "Relies on own judgment, resists influence",
	},
}

local function playSitAnimation(humanoid: Humanoid)
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = humanoid
	local sitAnim = Instance.new("Animation")
	sitAnim.AnimationId = "rbxassetid://507768133"

	local track = animator:LoadAnimation(sitAnim)
	track:Play()
end

-- Apply personality archetype to a juror
local function applyPersonalityArchetype(juror, archetype)
	if not archetype then
		return
	end

	-- Override personality traits with archetype
	for trait, value in pairs(archetype.traits) do
		juror.PersonalityTraits[trait] = value + (math.random(-5, 5) / 100) -- Small random variation
	end

	-- Adjust initial beliefs based on personality
	if archetype.name == "Authority Believer" then
		juror.BeliefNodes["PoliceCompetence"] = math.min(0.9, juror.BeliefNodes["PoliceCompetence"] + 0.2)
		juror.BeliefNodes["JusticeSystem"] = math.min(0.9, juror.BeliefNodes["JusticeSystem"] + 0.2)
		juror.BeliefNodes["ProsecutorHonesty"] = math.min(0.9, juror.BeliefNodes["ProsecutorHonesty"] + 0.2)
	elseif archetype.name == "Skeptical Doubter" then
		juror.BeliefNodes["WitnessCredibility"] = math.max(0.1, juror.BeliefNodes["WitnessCredibility"] - 0.2)
		juror.BeliefNodes["EvidenceQuality"] = math.max(0.1, juror.BeliefNodes["EvidenceQuality"] - 0.1)
		juror.BeliefNodes["FearOfWrongVerdict"] = math.min(0.9, juror.BeliefNodes["FearOfWrongVerdict"] + 0.3)
	elseif archetype.name == "Emotional Responder" then
		juror.BeliefNodes["Empathy"] = math.min(0.9, juror.BeliefNodes["Empathy"] + 0.3)
		juror.BeliefNodes["DefendantCharacter"] = math.min(0.9, juror.BeliefNodes["DefendantCharacter"] + 0.1)
		juror.BeliefNodes["PersonalBias"] = math.min(0.9, juror.BeliefNodes["PersonalBias"] + 0.2)
	end

	-- Store archetype info
	juror.PersonalityArchetype = {
		name = archetype.name,
		description = archetype.description,
	}
end

-- Create diverse jury composition
local function generateDiverseJury(jurorCount)
	local selectedArchetypes = {}
	local usedArchetypes = {}

	-- Ensure we get a good mix of personalities
	for _i = 1, jurorCount do
		local availableArchetypes = {}
		for _j, archetype in ipairs(PersonalityArchetypes) do
			-- Limit each archetype to appear at most twice in larger juries
			local timesUsed = usedArchetypes[archetype.name] or 0
			if timesUsed < 2 or jurorCount <= 4 then
				table.insert(availableArchetypes, archetype)
			end
		end

		local selected = availableArchetypes[math.random(1, #availableArchetypes)]
		table.insert(selectedArchetypes, selected)
		usedArchetypes[selected.name] = (usedArchetypes[selected.name] or 0) + 1
	end

	return selectedArchetypes
end

-- Spawn a single juror at a position with optional personality
function JurySpawner.spawnJurorAt(position: Vector3, seatPart: Seat?, personalityArchetype)
	local model = HumanGenerator.Generate()
	local juror = Juror.new(model.Name)

	-- Apply personality archetype if provided
	if personalityArchetype then
		applyPersonalityArchetype(juror, personalityArchetype)
	end

	model:SetAttribute("JurorId", juror.Id)
	model:SetAttribute("IsJuror", true)
	if personalityArchetype then
		model:SetAttribute("PersonalityType", personalityArchetype.name)
	end

	model:PivotTo(CFrame.new(position))
	model.Parent = workspace:FindFirstChild("Jurors") or workspace

	-- Sit the model down if a Seat was provided
	if seatPart and seatPart:IsA("Seat") then
		local humanoid = model:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			seatPart:Sit(humanoid)
			playSitAnimation(humanoid)
		end
	end

	JurySpawner.Registry[juror.Id] = {
		juror = juror,
		model = model,
		personality = personalityArchetype,
	}

	-- Set up belief change logging for debugging
	juror.OnBeliefChanged:Connect(function(beliefName, oldValue, newValue, _context)
		local change = math.abs(newValue - oldValue)
		if change > 0.1 then -- Only log significant changes
			print(
				`[{juror.Id}] {beliefName}: {math.floor(oldValue * 100)}% → {math.floor(newValue * 100)}% (Δ{math.floor(
					change * 100
				)}%)`
			)
		end
	end)

	juror.OnCoherenceChanged:Connect(function(oldCoherence, newCoherence)
		local change = newCoherence - oldCoherence
		if math.abs(change) > 0.05 then
			print(
				`[{juror.Id}] Coherence: {math.floor(oldCoherence * 100)}% → {math.floor(newCoherence * 100)}% (Δ{math.floor(
					change * 100
				)}%)`
			)
		end
	end)

	return model
end

-- Bulk spawn a diverse jury at pre-defined seats
function JurySpawner.spawnJury()
	local seatsFolder = game.Workspace:FindFirstChild("Seats")
	if not seatsFolder then
		warn("Seats folder not found in Workspace!")
		return
	end
	local seatModels = seatsFolder:GetChildren()
	local baseParts = {}

	for _, model in ipairs(seatModels) do
		if model:IsA("Model") and model.PrimaryPart then
			table.insert(baseParts, model.PrimaryPart)
		end
	end

	local jurorCount = #baseParts
	local personalities = generateDiverseJury(jurorCount)

	print(`\n=== SPAWNING DIVERSE JURY ({jurorCount} jurors) ===`)

	for i, seat in ipairs(baseParts) do
		local personality = personalities[i]
		print(`Spawning {personality.name}: {personality.description}`)
		JurySpawner.spawnJurorAt(seat.Position, seat, personality)
	end

	print("\n=== JURY PERSONALITY BREAKDOWN ===")
	JurySpawner.printJuryComposition()
end

-- Print detailed jury composition
function JurySpawner.printJuryComposition()
	local personalityCounts = {}
	local avgTraits = { Analytical = 0, Emotional = 0, Cautious = 0, Decisive = 0, Trusting = 0 }
	local jurorCount = 0

	for _id, data in pairs(JurySpawner.Registry) do
		local juror = data.juror
		local personality = data.personality

		if personality then
			personalityCounts[personality.name] = (personalityCounts[personality.name] or 0) + 1
		end

		for trait, value in pairs(juror.PersonalityTraits) do
			avgTraits[trait] += value
		end
		jurorCount += 1
	end

	-- Print personality distribution
	for personalityType, count in pairs(personalityCounts) do
		print(`{personalityType}: {count} juror(s)`)
	end

	print("\n=== AVERAGE PERSONALITY TRAITS ===")
	for trait, total in pairs(avgTraits) do
		local avg = jurorCount > 0 and (total / jurorCount) or 0
		print(`{trait}: {math.floor(avg * 100)}%`)
	end
end

-- Get juror object by model (or id)
function JurySpawner.getJurorForModel(model: Model)
	local id = model:GetAttribute("JurorId")
	return id and JurySpawner.Registry[id] and JurySpawner.Registry[id].juror
end

function JurySpawner.getRandomJuror()
	local jurors = {}
	for _id, data in pairs(JurySpawner.Registry) do
		table.insert(jurors, data.juror)
	end
	if #jurors > 0 then
		return jurors[math.random(1, #jurors)]
	end
	return nil
end

-- Get juror by personality type
function JurySpawner.getJurorByPersonality(personalityName)
	for _id, data in pairs(JurySpawner.Registry) do
		if data.personality and data.personality.name == personalityName then
			return data.juror
		end
	end
	return nil
end

-- Get jury statistics for analysis
function JurySpawner.getJuryStats()
	local stats = {
		totalJurors = 0,
		avgCoherence = 0,
		avgGuilt = 0,
		personalityDistribution = {},
		beliefRanges = {},
	}

	local coherenceSum = 0
	local guiltSum = 0

	for _id, data in pairs(JurySpawner.Registry) do
		local juror = data.juror
		stats.totalJurors += 1

		coherenceSum += juror.CognitiveCoherence
		guiltSum += juror:calculateOverallGuilt()

		if data.personality then
			local pType = data.personality.name
			stats.personalityDistribution[pType] = (stats.personalityDistribution[pType] or 0) + 1
		end
	end

	if stats.totalJurors > 0 then
		stats.avgCoherence = coherenceSum / stats.totalJurors
		stats.avgGuilt = guiltSum / stats.totalJurors
	end

	return stats
end

-- Clear all jurors (for testing)
function JurySpawner.clearJury()
	for _id, data in pairs(JurySpawner.Registry) do
		if data.model and data.model.Parent then
			data.model:Destroy()
		end
	end
	JurySpawner.Registry = {}
	print("Jury cleared")
end

return JurySpawner
