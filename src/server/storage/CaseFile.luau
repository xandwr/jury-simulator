-- ServerStorage/CaseFile

local CaseFile = {}

CaseFile.SuspectName = "Derek Mallory"
CaseFile.Charges = { "Second Degree Murder" }
CaseFile.Summary = [[
On the night of June 4th, Derek Mallory was seen fleeing the scene of a fatal stabbing in the alley behind Granger's Pub. 
One eyewitness claims to have seen him with a knife, while another says they're unsure. 
No weapon was recovered. DNA evidence is inconclusive.
]]

-- Enhanced evidence with complexity ratings and belief network targeting
CaseFile.Evidence = {
	{
		Id = "Witness1",
		Type = "Testimony",
		Text = "I saw Derek with a knife near the body. He was running away when I spotted him.",
		Direction = "For", -- For/Against/Neutral
		Strength = 0.6,
		Complexity = 0.4,
		AffectedNodes = { "WitnessCredibility", "PhysicalEvidence", "Opportunity" },
		Source = "Bar patron Sarah Jenkins",
		Reliability = 0.7, -- How reliable this evidence is considered
	},
	{
		Id = "Witness2",
		Type = "Testimony",
		Text = "It was dark, I couldn't really tell who it was. Could have been anyone.",
		Direction = "Against",
		Strength = 0.4,
		Complexity = 0.3,
		AffectedNodes = { "WitnessCredibility", "EvidenceQuality", "FearOfWrongVerdict" },
		Source = "Bar patron Mike Chen",
		Reliability = 0.6,
	},
	{
		Id = "PoliceReport",
		Type = "Document",
		Text = "No fingerprints recovered from the scene. DNA samples degraded due to rain.",
		Direction = "Against",
		Strength = 0.5,
		Complexity = 0.6,
		AffectedNodes = { "ForensicAccuracy", "PoliceCompetence", "PhysicalEvidence" },
		Source = "Detective Martinez crime scene report",
		Reliability = 0.9,
	},
	{
		Id = "Timeline",
		Type = "Timeline",
		Text = "Derek left the pub at 10:42pm. Victim's time of death estimated at 10:45-10:55pm.",
		Direction = "For",
		Strength = 0.7,
		Complexity = 0.5,
		AffectedNodes = { "Timeline", "Opportunity", "DefendantCharacter" },
		Source = "Security camera footage and medical examiner",
		Reliability = 0.95,
	},
	{
		Id = "BarFight",
		Type = "Testimony",
		Text = "Derek got into a heated argument with the victim earlier that night about money.",
		Direction = "For",
		Strength = 0.6,
		Complexity = 0.4,
		AffectedNodes = { "Motive", "DefendantCharacter", "PastBehavior" },
		Source = "Bartender testimony",
		Reliability = 0.8,
	},
	{
		Id = "CharacterWitness",
		Type = "Testimony",
		Text = "Derek's never been violent. He volunteers at the animal shelter every weekend.",
		Direction = "Against",
		Strength = 0.4,
		Complexity = 0.3,
		AffectedNodes = { "DefendantCharacter", "PastBehavior", "Empathy" },
		Source = "Derek's neighbor Mrs. Rodriguez",
		Reliability = 0.6,
	},
	{
		Id = "SecurityFootage",
		Type = "Physical",
		Text = "Blurry security footage shows a figure matching Derek's build fleeing the scene.",
		Direction = "For",
		Strength = 0.5,
		Complexity = 0.7,
		AffectedNodes = { "PhysicalEvidence", "ForensicAccuracy", "EvidenceQuality" },
		Source = "Granger's Pub security system",
		Reliability = 0.7,
	},
	{
		Id = "WeaponSearch",
		Type = "Document",
		Text = "Police searched Derek's home and vehicle. No weapon found.",
		Direction = "Against",
		Strength = 0.4,
		Complexity = 0.4,
		AffectedNodes = { "PhysicalEvidence", "PoliceCompetence", "ProsecutorHonesty" },
		Source = "Search warrant execution report",
		Reliability = 0.9,
	},
}

-- Jury-shared memory (what evidence has been presented)
CaseFile.SeenEvidence = {}
CaseFile.EvidenceRevealOrder = {} -- Track order of evidence presentation

-- Evidence presentation categories
CaseFile.EvidenceCategories = {
	Opening = { "Timeline", "BarFight" }, -- Set the scene
	Prosecution = { "Witness1", "SecurityFootage" }, -- Build case for guilt
	Defense = { "Witness2", "CharacterWitness", "WeaponSearch" }, -- Create doubt
	Technical = { "PoliceReport" }, -- Complex/technical evidence
}

function CaseFile.reveal(evidenceId)
	for _, evidence in ipairs(CaseFile.Evidence) do
		if evidence.Id == evidenceId then
			-- Check if already revealed
			for _, seen in ipairs(CaseFile.SeenEvidence) do
				if seen.Id == evidenceId then
					return seen -- Already revealed
				end
			end

			-- Add to seen evidence
			table.insert(CaseFile.SeenEvidence, evidence)
			table.insert(CaseFile.EvidenceRevealOrder, {
				evidence = evidence,
				timestamp = tick(),
				order = #CaseFile.EvidenceRevealOrder + 1,
			})

			return evidence
		end
	end
	return nil
end

function CaseFile.revealCategory(categoryName)
	local category = CaseFile.EvidenceCategories[categoryName]
	if not category then
		warn(`Unknown evidence category: {categoryName}`)
		return {}
	end

	local revealedEvidence = {}
	for _, evidenceId in ipairs(category) do
		local evidence = CaseFile.reveal(evidenceId)
		if evidence then
			table.insert(revealedEvidence, evidence)
		end
	end

	return revealedEvidence
end

function CaseFile.getRandomKnownEvidence()
	if #CaseFile.SeenEvidence == 0 then
		return nil
	end
	return CaseFile.SeenEvidence[math.random(1, #CaseFile.SeenEvidence)]
end

-- Get evidence weighted by recency and importance
function CaseFile.getWeightedRandomEvidence()
	if #CaseFile.SeenEvidence == 0 then
		return nil
	end

	local weights = {}
	local totalWeight = 0

	for i, evidence in ipairs(CaseFile.SeenEvidence) do
		-- More recent evidence gets higher weight
		local recencyWeight = (i / #CaseFile.SeenEvidence) ^ 2
		-- Higher strength evidence gets higher weight
		local strengthWeight = evidence.Strength or 0.5
		-- Complex evidence gets slightly lower weight (harder to remember)
		local complexityPenalty = 1 - ((evidence.Complexity or 0.5) * 0.3)

		local weight = recencyWeight * strengthWeight * complexityPenalty
		weights[i] = weight
		totalWeight += weight
	end

	-- Weighted random selection
	local random = math.random() * totalWeight
	local accumulator = 0

	for i, weight in ipairs(weights) do
		accumulator += weight
		if random <= accumulator then
			return CaseFile.SeenEvidence[i]
		end
	end

	-- Fallback
	return CaseFile.SeenEvidence[#CaseFile.SeenEvidence]
end

-- Get evidence that would be interesting given current jury state
function CaseFile.getRelevantEvidence(jurorCognitiveStates)
	if #CaseFile.SeenEvidence == 0 then
		return nil
	end

	-- Analyze jury's current belief patterns
	local avgCoherence = 0
	local avgGuilt = 0
	local jurorCount = 0

	for _, state in pairs(jurorCognitiveStates) do
		avgCoherence += state.coherence
		avgGuilt += state.overallGuilt
		jurorCount += 1
	end

	if jurorCount > 0 then
		avgCoherence /= jurorCount
		avgGuilt /= jurorCount
	end

	-- Select evidence type based on jury state
	local targetEvidence = {}

	-- If jury is highly coherent but split, introduce complex evidence
	if avgCoherence > 0.7 and math.abs(avgGuilt - 0.5) < 0.2 then
		for _, evidence in ipairs(CaseFile.SeenEvidence) do
			if evidence.Complexity and evidence.Complexity > 0.6 then
				table.insert(targetEvidence, evidence)
			end
		end
	end

	-- If jury is leaning guilty, show defense evidence
	if avgGuilt > 0.6 then
		for _, evidence in ipairs(CaseFile.SeenEvidence) do
			if evidence.Direction == "Against" then
				table.insert(targetEvidence, evidence)
			end
		end
	end

	-- If jury is leaning not guilty, show prosecution evidence
	if avgGuilt < 0.4 then
		for _, evidence in ipairs(CaseFile.SeenEvidence) do
			if evidence.Direction == "For" then
				table.insert(targetEvidence, evidence)
			end
		end
	end

	-- Return random from relevant evidence, or fallback to any evidence
	if #targetEvidence > 0 then
		return targetEvidence[math.random(1, #targetEvidence)]
	else
		return CaseFile.getWeightedRandomEvidence()
	end
end

function CaseFile.getSummary()
	return CaseFile.Summary
end

-- Get evidence presentation statistics
function CaseFile.getEvidenceStats()
	local forCount, againstCount, neutralCount = 0, 0, 0
	local totalStrength = 0
	local totalComplexity = 0

	for _, evidence in ipairs(CaseFile.SeenEvidence) do
		if evidence.Direction == "For" then
			forCount += 1
		elseif evidence.Direction == "Against" then
			againstCount += 1
		else
			neutralCount += 1
		end

		totalStrength += (evidence.Strength or 0.5)
		totalComplexity += (evidence.Complexity or 0.5)
	end

	local count = #CaseFile.SeenEvidence

	return {
		total = count,
		forGuilty = forCount,
		againstGuilty = againstCount,
		neutral = neutralCount,
		avgStrength = count > 0 and (totalStrength / count) or 0,
		avgComplexity = count > 0 and (totalComplexity / count) or 0,
		prosecutionBias = count > 0 and ((forCount - againstCount) / count) or 0,
	}
end

return CaseFile
