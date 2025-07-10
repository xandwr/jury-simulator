-- ServerScriptService/Deliberation

local JurySpawner = require(game.ServerStorage.JurySpawner)
local CaseFile = require(game.ServerStorage.CaseFile)

local Deliberation = {}
Deliberation.Active = false
Deliberation.Round = 0
Deliberation.Phase = "Initial" -- Initial, Discussion, Preliminary, Final
Deliberation.VotingHistory = {}

-- Statement generation templates based on cognitive state
local StatementTemplates = {
	-- High meaning + high coherence = strong conviction
	HighMeaningHighCoherence = {
		guilty = {
			"This evidence completely changes my perspective - he's definitely guilty.",
			"Everything clicks now. The timeline, the witness, it all points to Derek.",
			"I've been thinking about this carefully, and I'm convinced he did it."
		},
		notGuilty = {
			"Wait, this actually makes me doubt the whole prosecution case.",
			"Looking at all the evidence together, I don't think they've proved it.",
			"This new information makes me question everything we've heard."
		}
	},

	-- High meaning + low coherence = confusion but impact
	HighMeaningLowCoherence = {
		general = {
			"This is really confusing me more than helping...",
			"I don't know what to think anymore - this contradicts other evidence.",
			"My head is spinning trying to piece this all together."
		}
	},

	-- Low meaning + high coherence = measured response
	LowMeaningHighCoherence = {
		general = {
			"This doesn't really change my overall assessment.",
			"Interesting, but it fits with what I already believed.",
			"This confirms what I was already thinking."
		}
	},

	-- Low meaning + low coherence = struggle
	LowMeaningLowCoherence = {
		general = {
			"I'm having trouble following all of this...",
			"Can we go over the main points again?",
			"This is all getting jumbled in my mind."
		}
	},

	-- High processing load
	HighProcessingLoad = {
		"Give me a moment to think about this...",
		"There's a lot to process here.",
		"I need time to sort through all this information."
	},

	-- Personality-driven responses
	Analytical = {
		"Let's look at the facts systematically.",
		"The logical chain of evidence suggests...",
		"If we analyze this step by step..."
	},

	Emotional = {
		"I just can't imagine him doing something like this.",
		"This makes me feel terrible for everyone involved.",
		"My gut tells me something isn't right here."
	},

	Cautious = {
		"We need to be absolutely certain before we decide.",
		"I don't want to make a mistake that ruins someone's life.",
		"Are we sure we've considered every possibility?"
	},

	Decisive = {
		"We need to make a decision and stick with it.",
		"The evidence is clear enough - let's vote.",
		"I've heard enough. I know where I stand."
	}
}

-- Generate sophisticated statements based on cognitive state
local function generateCognitiveStatement(juror, _evidence, evaluation)
	local state = juror:getCognitiveState()
	local meaning = evaluation.effectiveMeaning
	local coherence = state.coherence
	local guilt = state.overallGuilt

	-- Determine response category
	local templates = {}

	-- High impact responses (meaning > 0.5)
	if meaning > 0.5 then
		if coherence > 0.6 then
			-- Clear strong reaction
			if guilt > 0.7 then
				templates = StatementTemplates.HighMeaningHighCoherence.guilty
			elseif guilt < 0.3 then
				templates = StatementTemplates.HighMeaningHighCoherence.notGuilty
			else
				-- Use a general high meaning, high coherence neutral statement if available, otherwise fallback
				templates = StatementTemplates.LowMeaningHighCoherence.general
			end
		else
			-- Confused but impacted
			templates = StatementTemplates.HighMeaningLowCoherence.general
		end
	else
		-- Lower impact responses
		if coherence > 0.6 then
			templates = StatementTemplates.LowMeaningHighCoherence.general
		else
			templates = StatementTemplates.LowMeaningLowCoherence.general
		end
	end

	-- Override with processing load responses if overwhelmed
	if state.processingLoad > 0.7 then
		templates = StatementTemplates.HighProcessingLoad
	end

	-- Add personality flavor 25% of the time
	if math.random() < 0.25 then
		local personality = state.personality
		local maxPersonality = ""
		local maxValue = 0

		for trait, value in pairs(personality) do
			if value > maxValue then
				maxValue = value
				maxPersonality = trait
			end
		end

		if StatementTemplates[maxPersonality] then
			templates = StatementTemplates[maxPersonality]
		end
	end

	-- Select random template from chosen category
	if #templates > 0 then
		return templates[math.random(1, #templates)]
	else
		return "I need to think about this more."
	end
end

-- Calculate jury consensus level
local function calculateConsensus()
	local registry = JurySpawner.Registry
	local guiltBeliefs = {}

	for _, data in pairs(registry) do
		local guilt = data.juror:calculateOverallGuilt()
		table.insert(guiltBeliefs, guilt)
	end

	if #guiltBeliefs == 0 then return 0 end

	-- Calculate standard deviation of guilt beliefs
	local mean = 0
	for _, guilt in ipairs(guiltBeliefs) do
		mean += guilt
	end
	mean /= #guiltBeliefs

	local variance = 0
	for _, guilt in ipairs(guiltBeliefs) do
		variance += (guilt - mean) ^ 2
	end
	variance /= #guiltBeliefs

	local stdDev = math.sqrt(variance)

	-- Consensus is inverse of standard deviation (0 = no consensus, 1 = perfect consensus)
	return math.max(0, 1 - (stdDev * 2))
end

-- Conduct a jury vote
local function conductVote(voteType)
	local registry = JurySpawner.Registry
	local votes = {guilty = 0, notGuilty = 0, undecided = 0}
	local voterDetails = {}

	for id, data in pairs(registry) do
		local guilt = data.juror:calculateOverallGuilt()
		local coherence = data.juror.CognitiveCoherence

		local vote
		if guilt > 0.55 and coherence > 0.4 then
			vote = "guilty"
			votes.guilty += 1
		elseif guilt < 0.45 and coherence > 0.4 then
			vote = "notGuilty" 
			votes.notGuilty += 1
		else
			vote = "undecided"
			votes.undecided += 1
		end

		voterDetails[id] = {
			vote = vote,
			guilt = guilt,
			coherence = coherence
		}
	end

	local result = {
		type = voteType,
		votes = votes,
		details = voterDetails,
		timestamp = tick(),
		consensus = calculateConsensus(),
		unanimous = (votes.guilty == 0 or votes.notGuilty == 0) and votes.undecided == 0
	}

	table.insert(Deliberation.VotingHistory, result)
	return result
end

-- Announce vote results
local function announceVoteResults(voteResult)
	local total = voteResult.votes.guilty + voteResult.votes.notGuilty + voteResult.votes.undecided
	local guiltyPercent = math.floor((voteResult.votes.guilty / total) * 100)
	local notGuiltyPercent = math.floor((voteResult.votes.notGuilty / total) * 100)

	print(`\n--- {voteResult.type} Vote Results ---`)
	print(`Guilty: {voteResult.votes.guilty} ({guiltyPercent}%)`)
	print(`Not Guilty: {voteResult.votes.notGuilty} ({notGuiltyPercent}%)`)
	print(`Undecided: {voteResult.votes.undecided}`)
	print(`Consensus Level: {math.floor(voteResult.consensus * 100)}%`)

	if voteResult.unanimous then
		print("UNANIMOUS VERDICT REACHED!")
		return true
	end

	return false
end

-- Select next speaker based on cognitive dynamics
local function selectNextSpeaker(lastSpeakerId)
	local registry = JurySpawner.Registry
	local candidates = {}

	for id, data in pairs(registry) do
		if id ~= lastSpeakerId then
			local state = data.juror:getCognitiveState()

			-- Weight speaker selection by:
			-- 1. Recent high meaning (want to share insights)
			-- 2. High coherence (clear thoughts to express)  
			-- 3. Personality traits (decisive people speak more)
			local weight = 1.0

			if state.recentMeaning > 0.4 then
				weight *= 2.0 -- Strong recent insight
			end

			if state.coherence > 0.6 then
				weight *= 1.5 -- Clear thinking
			end

			if state.personality.Decisive > 0.7 then
				weight *= 1.3 -- Decisive personality
			end

			if state.processingLoad > 0.8 then
				weight *= 0.3 -- Overwhelmed, less likely to speak
			end

			table.insert(candidates, {id = id, data = data, weight = weight})
		end
	end

	-- Weighted random selection
	local totalWeight = 0
	for _, candidate in ipairs(candidates) do
		totalWeight += candidate.weight
	end

	local random = math.random() * totalWeight
	local accumulator = 0

	for _, candidate in ipairs(candidates) do
		accumulator += candidate.weight
		if random <= accumulator then
			return candidate.id, candidate.data
		end
	end

	-- Fallback to random selection
	local randomCandidate = candidates[math.random(1, #candidates)]
	return randomCandidate.id, randomCandidate.data
end

function Deliberation.begin()
	Deliberation.Active = true
	Deliberation.Round = 0
	Deliberation.Phase = "Initial"

	print("\n=== JURY DELIBERATION BEGINS ===")
	print(`Case: {CaseFile.SuspectName} - {table.concat(CaseFile.Charges, ", ")}`)

	task.spawn(function()
		local lastSpeakerId = nil
		local consecutiveRoundsWithoutProgress = 0

		while Deliberation.Active and Deliberation.Round < 25 do
			Deliberation.Round += 1

			-- Phase transitions
			if Deliberation.Round == 5 then
				Deliberation.Phase = "Discussion"
				print("\n--- Moving to open discussion phase ---")
			elseif Deliberation.Round == 12 then
				Deliberation.Phase = "Preliminary"
				print("\n--- Conducting preliminary vote ---")
				local prelimResult = conductVote("Preliminary")
				local unanimous = announceVoteResults(prelimResult)
				if unanimous then
					Deliberation.Active = false
					break
				end
			elseif Deliberation.Round == 20 then
				Deliberation.Phase = "Final"
				print("\n--- Final deliberation phase ---")
			end

			-- Select speaker based on cognitive dynamics
			local speakerId, speakerData = selectNextSpeaker(lastSpeakerId)
			local juror = speakerData.juror

			-- Get current jury cognitive states for evidence selection
			local jurorStates = {}
			for id, data in pairs(JurySpawner.Registry) do
				jurorStates[id] = data.juror:getCognitiveState()
			end

			-- Select evidence based on current jury state
			local evidence = CaseFile.getRelevantEvidence(jurorStates)

			if evidence then
				-- Juror evaluates evidence using cognitive framework
				local evaluation = juror:EvaluateEvidence(evidence)

				-- Generate sophisticated statement
				local statement = generateCognitiveStatement(juror, evidence, evaluation)
				juror:Speak(statement)

				-- Check for high-impact moments
				if evaluation.effectiveMeaning > 0.7 then
					consecutiveRoundsWithoutProgress = 0
					print(`[High Impact] {juror.Id}: Effective meaning = {math.floor(evaluation.effectiveMeaning * 100)}%`)
				else
					consecutiveRoundsWithoutProgress += 1
				end

			else
				-- Fallback discussion when no evidence available
				local state = juror:getCognitiveState()
				if state.overallGuilt > 0.6 then
					juror:Speak("I keep coming back to the same conclusion - the evidence points to guilt.")
				elseif state.overallGuilt < 0.4 then
					juror:Speak("I still have too many doubts to convict.")
				else
					juror:Speak("I'm really struggling with this decision...")
				end
				consecutiveRoundsWithoutProgress += 1
			end

			lastSpeakerId = speakerId

			-- Check for early consensus
			local currentConsensus = calculateConsensus()
			if currentConsensus > 0.85 and Deliberation.Round > 8 then
				print(`\nHigh consensus detected (${math.floor(currentConsensus * 100)}%) - moving to final vote`)
				break
			end

			-- End if no progress
			if consecutiveRoundsWithoutProgress > 5 then
				print("\nDeliberation appears stuck - calling final vote")
				break
			end

			task.wait(math.random(4, 8)) -- Variable timing for realism
		end

		-- Final vote
		print("\n=== FINAL VOTE ===")
		local finalResult = conductVote("Final")
		announceVoteResults(finalResult)

		-- Print case statistics
		local stats = CaseFile.getEvidenceStats()
		print(`\nCase Statistics:`)
		print(`Evidence presented: {stats.total}`)
		print(`Prosecution bias: {math.floor(stats.prosecutionBias * 100)}%`)
		print(`Average complexity: {math.floor(stats.avgComplexity * 100)}%`)

		Deliberation.Active = false
	end)
end

function Deliberation.forceVote()
	if not Deliberation.Active then return end

	local result = conductVote("Forced")
	announceVoteResults(result)
	return result
end

function Deliberation.getStatus()
	return {
		active = Deliberation.Active,
		round = Deliberation.Round,
		phase = Deliberation.Phase,
		consensus = calculateConsensus(),
		votingHistory = Deliberation.VotingHistory
	}
end

return Deliberation