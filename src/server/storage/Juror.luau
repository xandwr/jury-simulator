-- ServerStorage/Juror

local createSignal = require(game.ReplicatedStorage.Signal)

local Juror = {}
Juror.__index = Juror

-- Belief node definitions for legal reasoning
local BELIEF_NODES = {
	-- Evidence-related beliefs
	"WitnessCredibility", "PhysicalEvidence", "Timeline", "ForensicAccuracy",

	-- Defendant-related beliefs  
	"DefendantCharacter", "Motive", "Opportunity", "PastBehavior",

	-- System-related beliefs
	"PoliceCompetence", "ProsecutorHonesty", "JusticeSystem", "LegalProcess",

	-- Personal/emotional beliefs
	"FearOfWrongVerdict", "SocialPressure", "PersonalBias", "Empathy",

	-- Meta-cognitive beliefs
	"EvidenceQuality", "CaseComplexity", "TimeToDecide", "GroupConsensus"
}

-- Define which beliefs should correlate (simplified belief network)
local BELIEF_CONNECTIONS = {
	{from = "WitnessCredibility", to = "PhysicalEvidence", weight = 0.6},
	{from = "PhysicalEvidence", to = "ForensicAccuracy", weight = 0.8},
	{from = "Timeline", to = "Opportunity", weight = 0.7},
	{from = "DefendantCharacter", to = "Motive", weight = 0.5},
	{from = "PoliceCompetence", to = "JusticeSystem", weight = 0.7},
	{from = "ProsecutorHonesty", to = "LegalProcess", weight = 0.6},
	{from = "FearOfWrongVerdict", to = "EvidenceQuality", weight = -0.4},
	{from = "SocialPressure", to = "GroupConsensus", weight = 0.5},
	{from = "PersonalBias", to = "Empathy", weight = -0.3},
	{from = "CaseComplexity", to = "TimeToDecide", weight = 0.4},
}

function Juror.new(id: string)
	local self = setmetatable({}, Juror)
	self.Id = id

	-- Initialize belief network
	self.BeliefNodes = {}
	for _, node in ipairs(BELIEF_NODES) do
		-- Random initial beliefs with some personality bias
		self.BeliefNodes[node] = math.random(20, 80) / 100
	end

	-- Store belief connections for this juror
	self.BeliefConnections = {}
	for _, connection in ipairs(BELIEF_CONNECTIONS) do
		local key = connection.from .. "->" .. connection.to
		self.BeliefConnections[key] = connection.weight + (math.random(-10, 10) / 100) -- Add personality variance
	end

	-- Cognitive state variables
	self.CognitiveCoherence = 0.5
	self.LastCoherenceChange = 0
	self.ProcessingLoad = 0

	-- Track belief changes for meaning calculation
	self.BeliefHistory = {}

	-- Personality factors that affect reasoning
	self.PersonalityTraits = {
		Analytical = math.random(30, 90) / 100,
		Emotional = math.random(20, 80) / 100,
		Cautious = math.random(40, 85) / 100,
		Decisive = math.random(25, 75) / 100,
		Trusting = math.random(30, 80) / 100
	}

	-- Signals for belief changes
	self.OnBeliefChanged = createSignal() -- Signal<string, number, number, table>
	self.OnCoherenceChanged = createSignal() -- Signal<number, number>

	return self
end

-- Calculate cognitive coherence C(t) = Ψ(D;M) × D*_KL/Δt
function Juror:calculateCoherence()
	local beliefInconsistencies = 0
	local totalConnections = 0
	local maxInconsistency = 0

	-- Check belief consistency across connected nodes
	for connectionKey, expectedWeight in pairs(self.BeliefConnections) do
		local nodes = string.split(connectionKey, "->")
		local fromNode, toNode = nodes[1], nodes[2]

		local prob1 = self.BeliefNodes[fromNode] or 0.5
		local prob2 = self.BeliefNodes[toNode] or 0.5

		-- Calculate expected relationship vs actual
		local actualRelation = prob2 - prob1
		local expectedSign = expectedWeight > 0 and 1 or -1
		local expectedMagnitude = math.abs(expectedWeight)

		-- Inconsistency when beliefs don't follow expected pattern
		local inconsistency = 0
		if expectedSign > 0 and actualRelation < -0.2 then
			inconsistency = math.abs(actualRelation + 0.2) * expectedMagnitude
		elseif expectedSign < 0 and actualRelation > 0.2 then
			inconsistency = math.abs(actualRelation - 0.2) * expectedMagnitude
		end

		beliefInconsistencies += inconsistency
		maxInconsistency += expectedMagnitude
		totalConnections += 1
	end

	-- Normalize coherence (1 = perfectly coherent, 0 = completely incoherent)
	local rawCoherence = 1 - (beliefInconsistencies / math.max(maxInconsistency, 0.01))

	-- Apply personality effects
	local analyticalBonus = self.PersonalityTraits.Analytical * 0.2
	local emotionalPenalty = self.PersonalityTraits.Emotional * 0.1

	local oldCoherence = self.CognitiveCoherence
	self.CognitiveCoherence = math.clamp(rawCoherence + analyticalBonus - emotionalPenalty, 0, 1)
	self.LastCoherenceChange = self.CognitiveCoherence - oldCoherence

	self.OnCoherenceChanged:Fire(oldCoherence, self.CognitiveCoherence)

	return self.CognitiveCoherence
end

-- Calculate meaning μ(D) - how much beliefs changed
function Juror:calculateMeaning(priorBeliefs)
	local totalMeaning = 0
	local changedNodes = 0

	for node, currentProb in pairs(self.BeliefNodes) do
		local priorProb = priorBeliefs[node] or currentProb
		local change = math.abs(currentProb - priorProb)
		totalMeaning += change

		if change > 0.05 then -- Meaningful change threshold
			changedNodes += 1
		end
	end

	-- Weight by number of nodes affected (more comprehensive changes = higher meaning)
	local comprehensiveness = changedNodes / #BELIEF_NODES
	return totalMeaning * (1 + comprehensiveness)
end

-- Calculate effective meaning μ*(D) = μ(D) × σ(β ΔC_norm)
function Juror:calculateEffectiveMeaning(rawMeaning, coherenceChange)
	-- Sigmoid function to weight meaning by coherence change
	local beta = 2.0 -- Sensitivity parameter
	local coherenceWeight = 1 / (1 + math.exp(-beta * coherenceChange))

	-- High coherence increase amplifies meaning (aha moments)
	-- Low coherence decrease dampens meaning (confusion)
	return rawMeaning * coherenceWeight
end

-- Get belief nodes affected by specific evidence
function Juror:getAffectedNodes(evidence)
	local affected = {}

	-- Map evidence types to affected belief nodes
	if evidence.Type == "Testimony" then
		table.insert(affected, "WitnessCredibility")
		if evidence.TargetBelief then
			table.insert(affected, evidence.TargetBelief)
		end
	elseif evidence.Type == "Physical" then
		table.insert(affected, "PhysicalEvidence")
		table.insert(affected, "ForensicAccuracy")
	elseif evidence.Type == "Document" then
		table.insert(affected, "PoliceCompetence")
		table.insert(affected, "LegalProcess")
	elseif evidence.Type == "Timeline" then
		table.insert(affected, "Timeline")
		table.insert(affected, "Opportunity")
	end

	-- Add any specifically targeted beliefs
	if evidence.AffectedNodes then
		for _, node in ipairs(evidence.AffectedNodes) do
			if not table.find(affected, node) then
				table.insert(affected, node)
			end
		end
	end

	return affected
end

-- Calculate evidence strength based on juror personality and current state
function Juror:calculateEvidenceStrength(evidence, _targetNode)
	local baseStrength = evidence.Strength or 0.3

	-- Personality modifiers
	local personalityMod = 1.0
	if evidence.Type == "Testimony" then
		personalityMod *= (1 + self.PersonalityTraits.Trusting * 0.5)
		personalityMod *= (1 + self.PersonalityTraits.Emotional * 0.3)
	elseif evidence.Type == "Physical" then
		personalityMod *= (1 + self.PersonalityTraits.Analytical * 0.6)
	end

	-- Coherence affects processing efficiency
	local coherenceMod = 0.7 + (self.CognitiveCoherence * 0.6)

	-- Processing load affects attention
	local loadMod = math.max(0.3, 1.0 - self.ProcessingLoad)

	-- Random variation (smaller than original system)
	local randomJolt = (math.random() - 0.5) * 0.2

	return (baseStrength * personalityMod * coherenceMod * loadMod) + randomJolt
end

-- Propagate belief changes through the network
function Juror:propagateBeliefChanges(changedNodes)
	local propagationRounds = 2 -- Limit propagation to prevent infinite loops

	for round = 1, propagationRounds do
		local newChanges = {}

		for _, sourceNode in ipairs(changedNodes) do
			-- Find connections from this node
			for connectionKey, weight in pairs(self.BeliefConnections) do
				local nodes = string.split(connectionKey, "->")
				local fromNode, toNode = nodes[1], nodes[2]

				if fromNode == sourceNode then
					local sourceProb = self.BeliefNodes[sourceNode]
					local targetProb = self.BeliefNodes[toNode]

					-- Calculate influence (stronger connections = more influence)
					local influence = weight * 0.1 * (1 / round) -- Diminishing influence over rounds
					local expectedTarget = sourceProb + (weight * 0.3)
					local targetAdjustment = (expectedTarget - targetProb) * influence

					local newTargetProb = math.clamp(targetProb + targetAdjustment, 0, 1)

					if math.abs(newTargetProb - targetProb) > 0.01 then
						self.BeliefNodes[toNode] = newTargetProb
						table.insert(newChanges, toNode)
					end
				end
			end
		end

		changedNodes = newChanges
		if #changedNodes == 0 then break end -- No more changes to propagate
	end
end

-- Enhanced evidence evaluation using Hum and Jolt Theory
function Juror:EvaluateEvidence(evidence)
	-- Store prior beliefs for meaning calculation
	local priorBeliefs = table.clone(self.BeliefNodes)
	local priorCoherence = self.CognitiveCoherence

	-- Increase processing load temporarily
	self.ProcessingLoad = math.min(1.0, self.ProcessingLoad + (evidence.Complexity or 0.3))

	-- Get affected belief nodes
	local affectedNodes = self:getAffectedNodes(evidence)

	-- Apply evidence to each affected node
	for _, node in ipairs(affectedNodes) do
		local oldProb = self.BeliefNodes[node]
		local evidenceStrength = self:calculateEvidenceStrength(evidence, node)

		-- Apply directional change based on evidence
		local changeDirection = 1
		if evidence.Direction == "Against" then
			changeDirection = -1
		elseif evidence.Direction == "Neutral" then
			changeDirection = (math.random() > 0.5) and 1 or -1
		end

		local beliefChange = evidenceStrength * changeDirection
		local newProb = math.clamp(oldProb + beliefChange, 0, 1)

		self.BeliefNodes[node] = newProb

		-- Fire belief change signal
		self.OnBeliefChanged:Fire(node, oldProb, newProb, {
			evidence = evidence,
			strength = evidenceStrength,
			meaning = math.abs(newProb - oldProb)
		})
	end

	-- Propagate changes through belief network
	self:propagateBeliefChanges(affectedNodes)

	-- Recalculate cognitive coherence
	local newCoherence = self:calculateCoherence()
	local coherenceChange = newCoherence - priorCoherence

	-- Calculate meaning measures
	local rawMeaning = self:calculateMeaning(priorBeliefs)
	local effectiveMeaning = self:calculateEffectiveMeaning(rawMeaning, coherenceChange)

	-- Reduce processing load over time
	task.delay(2, function()
		self.ProcessingLoad = math.max(0, self.ProcessingLoad - 0.2)
	end)

	-- Store in belief history for pattern analysis
	table.insert(self.BeliefHistory, {
		timestamp = tick(),
		evidence = evidence,
		rawMeaning = rawMeaning,
		effectiveMeaning = effectiveMeaning,
		coherenceChange = coherenceChange,
		affectedNodes = affectedNodes
	})

	return {
		affectedNodes = affectedNodes,
		rawMeaning = rawMeaning,
		effectiveMeaning = effectiveMeaning,
		coherenceChange = coherenceChange,
		newCoherence = newCoherence
	}
end

-- Calculate overall guilt belief from network state
function Juror:calculateOverallGuilt()
	-- Weight different belief nodes for overall guilt assessment
	local guiltWeight = 0
	local totalWeight = 0

	local guiltRelevantBeliefs = {
		PhysicalEvidence = 0.3,
		WitnessCredibility = 0.25,
		Timeline = 0.2,
		Motive = 0.15,
		Opportunity = 0.1
	}

	for node, weight in pairs(guiltRelevantBeliefs) do
		local belief = self.BeliefNodes[node] or 0.5
		guiltWeight += belief * weight
		totalWeight += weight
	end

	return guiltWeight / totalWeight
end

-- Get cognitive state summary for statement generation
function Juror:getCognitiveState()
	return {
		overallGuilt = self:calculateOverallGuilt(),
		coherence = self.CognitiveCoherence,
		processingLoad = self.ProcessingLoad,
		recentMeaning = self.BeliefHistory[#self.BeliefHistory] and 
			self.BeliefHistory[#self.BeliefHistory].effectiveMeaning or 0,
		personality = self.PersonalityTraits
	}
end

-- Simplified speak function using native chat
function Juror:Speak(text: string)
	local jurorsFolder = workspace:FindFirstChild("Jurors")
	if not jurorsFolder then
		warn("[Juror] Cannot speak — 'Jurors' folder not found in workspace")
		return
	end

	local model = jurorsFolder:FindFirstChild(self.Id)
	if not model then
		warn(`[Juror] Cannot speak — model not found for {self.Id}`)
		return
	end

	local head = model:FindFirstChild("Head")
	if not head then
		warn(`[Juror] Model {self.Id} has no Head part.`)
		return
	end

	local ChatService = game:GetService("Chat")
	ChatService:Chat(head, text, Enum.ChatColor.White)
end

return Juror