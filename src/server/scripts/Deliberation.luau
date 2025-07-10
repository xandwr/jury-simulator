-- ServerScriptService/Deliberation (Enhanced with Social Dynamics)

local JurySpawner = require(game.ServerStorage.JurySpawner)
local CaseFile = require(game.ServerStorage.CaseFile)
local SocialDynamics = require(game.ServerStorage.SocialDynamics)
local JurorVisuals = require(game.ServerStorage.JurorVisuals)

local Deliberation = {}
Deliberation.Active = false
Deliberation.Round = 0
Deliberation.Phase = "Initial" -- Initial, Discussion, Preliminary, Final
Deliberation.VotingHistory = {}
Deliberation.ConversationGroups = {}
Deliberation.SocialInfluenceHistory = {}

-- Enhanced statement generation that considers social context
local StatementTemplates = {
	-- Dominant speaker statements (when someone has the floor)
	DominantSpeaker = {
		opening = {
			"Listen, I need everyone to hear this...",
			"Hold on, let me explain something important...",
			"I've been thinking about this carefully, and here's what I believe...",
			"Everyone, please - this is crucial to understand...",
		},
		conviction = {
			"I'm absolutely certain about this - the evidence clearly shows...",
			"There's no question in my mind that...",
			"I've analyzed this from every angle, and...",
			"The facts leave no room for doubt...",
		},
		challenging = {
			"I have to respectfully disagree with what's been said...",
			"That interpretation doesn't align with the evidence...",
			"I think we're missing something important here...",
			"Let me offer a different perspective...",
		},
	},

	-- Deference statements (when yielding to dominant speaker)
	Deference = {
		agreement = {
			"You're absolutely right about that.",
			"I hadn't considered it from that angle.",
			"That's a compelling argument.",
			"You've convinced me to reconsider.",
		},
		hesitation = {
			"Well, when you put it that way...",
			"I suppose that could be true...",
			"That's one way to look at it...",
			"You might have a point there.",
		},
		questions = {
			"Can you explain that part again?",
			"What about the evidence that suggests...?",
			"How do you reconcile that with...?",
			"I'm not sure I follow your reasoning.",
		},
	},

	-- Group conversation statements
	GroupDiscussion = {
		building = {
			"Building on what you said...",
			"That reminds me of another piece of evidence...",
			"Yes, and furthermore...",
			"Exactly, plus we should consider...",
		},
		clarifying = {
			"So you're saying that...",
			"Let me make sure I understand...",
			"Are you suggesting that...?",
			"Help me understand how...",
		},
		synthesizing = {
			"So it sounds like we all agree that...",
			"The common thread I'm hearing is...",
			"If we combine these points...",
			"Looking at this together...",
		},
	},

	-- Interruption/challenge statements
	Interruption = {
		polite = {
			"Sorry to interrupt, but...",
			"If I may add something...",
			"Can I just say one thing?",
			"I need to jump in here...",
		},
		assertive = {
			"Hold on - that's not accurate.",
			"Wait, I have to stop you there.",
			"That's completely wrong.",
			"No, you're missing the point.",
		},
	},

	-- Social facilitation (helping conversation flow)
	Facilitation = {
		encouraging = {
			"What do you think about that?",
			"Does anyone else see it differently?",
			"Let's hear from someone who hasn't spoken yet.",
			"Are we all on the same page here?",
		},
		mediating = {
			"I think both perspectives have merit...",
			"Maybe we can find some middle ground...",
			"Let's step back and look at this objectively...",
			"We're all trying to reach the truth here.",
		},
	},
}

-- Generate contextually appropriate statements based on social dynamics
local function generateSocialStatement(juror, evidence, evaluation, socialContext, influenceData)
	local state = juror:getCognitiveState()
	local meaning = evaluation.effectiveMeaning or evaluation.rawMeaning or 0
	local coherence = state.coherence or 0.5
	local guilt = state.overallGuilt or 0.5
	local personality = state.personality or {}

	-- Check for social influence in the evaluation
	local sociallyInfluenced = evaluation.socialInfluence and next(evaluation.socialInfluence)
	local influencedBy = evaluation.influencedBy

	-- Base statement selection
	local statement = ""
	local statementType = "general"

	-- Handle socially influenced statements
	if sociallyInfluenced and influencedBy then
		local influencerData = JurySpawner.Registry[influencedBy]
		local influencerName = influencerData and influencerData.personality and influencerData.personality.name or "someone"
		
		if socialContext.isDeferring then
			local templates = {
				`I'm starting to see {influencerName}'s point about this evidence.`,
				`That's a perspective I hadn't fully considered before.`,
				`You've helped me understand this differently.`,
				`I think I'm being swayed by the arguments I'm hearing.`
			}
			statement = templates[math.random(1, #templates)]
			statementType = "social_influence_deference"
			
		elseif socialContext.inGroup then
			local templates = {
				`Building on what we've been discussing...`,
				`The group conversation has helped me realize...`,
				`Hearing everyone's thoughts makes me think...`,
				`Our discussion is helping me see this more clearly.`
			}
			statement = templates[math.random(1, #templates)]
			statementType = "social_influence_group"
		else
			local templates = {
				`I'm finding my views shifting as I listen to others.`,
				`The discussion is really making me reconsider.`,
				`I'm being influenced by the compelling arguments I'm hearing.`,
				`Other perspectives are changing how I see this.`
			}
			statement = templates[math.random(1, #templates)]
			statementType = "social_influence_general"
		end
		
		-- Log social influence event
		table.insert(Deliberation.SocialInfluenceHistory, {
			round = Deliberation.Round,
			influenced = juror.Id,
			influencer = influencedBy,
			relationship = socialContext.relationship or "unknown",
			beliefChanges = evaluation.socialInfluence,
			statement = statement
		})
		
	-- Handle dominant speaker statements
	elseif socialContext.isDominant then
		if meaning > 0.6 then
			local templates = {
				`I need everyone to understand - this evidence clearly demonstrates...`,
				`Listen carefully - the facts undeniably show...`,
				`This is crucial for all of us to grasp...`,
				`I'm convinced beyond doubt that...`
			}
			statement = templates[math.random(1, #templates)]
			statementType = "dominant_conviction"
		else
			local templates = {
				`I want to make sure we're all considering...`,
				`It's important that we discuss...`,
				`We need to carefully examine...`,
				`Let me guide us through this evidence...`
			}
			statement = templates[math.random(1, #templates)]
			statementType = "dominant_guiding"
		end

	-- Handle group conversation
	elseif socialContext.inGroup then
		if socialContext.groupRole == "building" then
			local templates = {
				`Adding to our discussion...`,
				`That connects with what I was thinking...`,
				`Yes, and we should also consider...`,
				`Building on that point...`
			}
			statement = templates[math.random(1, #templates)]
			statementType = "group_building"
		else
			local templates = {
				`So what I'm hearing from our group is...`,
				`Are we all thinking along similar lines?`,
				`Let me clarify what we've established...`,
				`Our conversation suggests...`
			}
			statement = templates[math.random(1, #templates)]
			statementType = "group_synthesizing"
		end

	-- Handle deference (non-influenced)
	elseif socialContext.isDeferring then
		local templates = {
			`I want to hear more before I decide.`,
			`I'm listening carefully to all perspectives.`,
			`I'm still processing the arguments.`,
			`I respect the viewpoints being shared.`
		}
		statement = templates[math.random(1, #templates)]
		statementType = "deference_listening"

	-- Default content-based statements
	else
		if meaning > 0.5 and coherence > 0.6 then
			if guilt > 0.7 then
				statement = `This evidence strengthens my belief in guilt.`
			elseif guilt < 0.3 then
				statement = `This creates serious doubt in my mind.`
			else
				statement = `I'm carefully weighing all the evidence.`
			end
		else
			statement = `This is a complex decision that requires careful thought.`
		end
		statementType = "content_based"
	end

	-- Add evidence-specific context
	if evidence then
		local evidenceContext = ""
		if evidence.Direction == "For" then
			evidenceContext = " The prosecution's evidence"
		elseif evidence.Direction == "Against" then
			evidenceContext = " The defense's evidence"
		else
			evidenceContext = " This evidence"
		end
		
		if meaning > 0.4 then
			if guilt > 0.6 then
				statement = statement .. evidenceContext .. " reinforces my concerns about the defendant's guilt."
			else
				statement = statement .. evidenceContext .. " increases my reasonable doubt."
			end
		end
	end

	return statement, statementType
end

-- Analyze current social context for a juror
local function analyzeSocialContext(jurorId, activeInfluencers)
	local context = {
		isDominant = SocialDynamics.DominantSpeaker == jurorId,
		isDeferring = false,
		inGroup = false,
		groupRole = nil,
		isInterrupting = false,
		lastSpeaker = SocialDynamics.LastSpeaker,
		hasInfluencers = next(activeInfluencers) ~= nil,
		influencerCount = 0,
		dominantInfluencer = nil,
	}

	-- Count active influencers
	for influencerId, influenceData in pairs(activeInfluencers) do
		context.influencerCount += 1
		if influenceData.relationship == "dominant" then
			context.dominantInfluencer = influencerId
		end
	end

	-- Check if in active conversation group
	for groupId, conversation in pairs(SocialDynamics.ActiveConversations) do
		if conversation.participants[jurorId] then
			context.inGroup = true
			context.groupId = groupId

			-- Determine role in group conversation
			if conversation.dominantSpeaker == jurorId then
				context.groupRole = "leading"
			elseif conversation.lastSpeaker and conversation.lastSpeaker ~= jurorId then
				context.groupRole = math.random() < 0.5 and "building" or "clarifying"
			else
				context.groupRole = "synthesizing"
			end
			break
		end
	end

	-- Check if deferring to dominant speaker
	if SocialDynamics.DominantSpeaker and SocialDynamics.DominantSpeaker ~= jurorId then
		local jurorData = JurySpawner.Registry[jurorId]
		if jurorData and jurorData.juror then
			local traits = jurorData.juror.PersonalityTraits or {}
			local deferenceLevel = (traits.Cautious or 0.5) * 0.6 + (traits.Trusting or 0.5) * 0.4
			context.isDeferring = deferenceLevel > 0.5
		end
	end

	return context
end

-- Enhanced speaker selection using social dynamics
local function selectNextSpeaker(lastSpeakerId)
	-- Use SocialDynamics to select speaker and get influence data
	local speakerId, speakerData, activeInfluencers =
		SocialDynamics.selectNextSpeaker(JurySpawner.Registry, lastSpeakerId)

	if speakerId and speakerData then
		return speakerId, speakerData, activeInfluencers or {}
	end

	-- Fallback to random selection
	local candidates = {}
	for id, data in pairs(JurySpawner.Registry) do
		if id ~= lastSpeakerId then
			table.insert(candidates, { id = id, data = data })
		end
	end

	if #candidates > 0 then
		local selected = candidates[math.random(1, #candidates)]
		return selected.id, selected.data, {}
	end

	return nil, nil, {}
end

function calculateSocialStability()
	local socialStatus = SocialDynamics.getStatus()

	-- Factors that contribute to stability
	local hasStableDominant = SocialDynamics.DominantSpeaker and (tick() - SocialDynamics.DominanceStartTime) > 10
	local hasActiveConversations = socialStatus.activeConversations > 0
	local hasRecentSpeaker = socialStatus.lastSpeaker ~= nil

	local stabilityScore = 0
	if hasStableDominant then
		stabilityScore += 0.4
	end
	if hasActiveConversations then
		stabilityScore += 0.3
	end
	if hasRecentSpeaker then
		stabilityScore += 0.3
	end

	return stabilityScore
end

-- Calculate jury consensus level
function calculateConsensus()
	local registry = JurySpawner.Registry
	local guiltBeliefs = {}

	for _, data in pairs(registry) do
		if data and data.juror then
			local guilt = data.juror:calculateOverallGuilt()
			table.insert(guiltBeliefs, guilt)
		end
	end

	if #guiltBeliefs == 0 then
		return 0
	end

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

	-- Consensus is inverse of standard deviation
	return math.max(0, 1 - (stdDev * 2))
end

-- Conduct a jury vote with social dynamics
local function conductVote(voteType)
	local registry = JurySpawner.Registry
	local votes = { guilty = 0, notGuilty = 0, undecided = 0 }
	local voterDetails = {}

	-- Clear conversation lines during voting
	SocialDynamics.clearConversationLines()

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
			coherence = coherence,
		}

		-- Show voting visual effects
		local beliefType = vote == "guilty" and "guilt" or (vote == "notGuilty" and "doubt" or "confusion")
		JurorVisuals.createBeliefHalo(data.model, beliefType, coherence)
	end

	local result = {
		type = voteType,
		votes = votes,
		details = voterDetails,
		timestamp = tick(),
		consensus = calculateConsensus(),
		unanimous = (votes.guilty == 0 or votes.notGuilty == 0) and votes.undecided == 0,
	}

	table.insert(Deliberation.VotingHistory, result)
	return result
end

-- Announce vote results with social dynamics
local function announceVoteResults(voteResult)
	local total = voteResult.votes.guilty + voteResult.votes.notGuilty + voteResult.votes.undecided
	local guiltyPercent = math.floor((voteResult.votes.guilty / total) * 100)
	local notGuiltyPercent = math.floor((voteResult.votes.notGuilty / total) * 100)

	print(`\n--- {voteResult.type} Vote Results ---`)
	print(`Guilty: {voteResult.votes.guilty} ({guiltyPercent}%)`)
	print(`Not Guilty: {voteResult.votes.notGuilty} ({notGuiltyPercent}%)`)
	print(`Undecided: {voteResult.votes.undecided}`)
	print(`Consensus Level: {math.floor(voteResult.consensus * 100)}%`)

	-- Show social dynamics status
	local socialStatus = SocialDynamics.getStatus()
	print(
		`Social Dynamics: ${socialStatus.activeConversations} groups, Dominant: ${socialStatus.dominantSpeaker or "None"}`
	)

	if voteResult.unanimous then
		print("UNANIMOUS VERDICT REACHED!")
		-- Clear all social effects for unanimous decision
		SocialDynamics.clearConversationLines()
		SocialDynamics.clearDominance(JurySpawner.Registry)
		return true
	end

	return false
end

function Deliberation.begin()
	Deliberation.Active = true
	Deliberation.Round = 0
	Deliberation.Phase = "Initial"
	Deliberation.SocialInfluenceHistory = {}

	print("\n=== ENHANCED JURY DELIBERATION BEGINS ===")
	print("Featuring:")
	print("• Social influence on belief networks")
	print("• Dynamic conversation groups")
	print("• Dominant speaker effects")
	print("• Realistic deference mechanics")
	print(`Case: {CaseFile.SuspectName} - {table.concat(CaseFile.Charges, ", ")}`)

	task.spawn(function()
		local lastSpeakerId = nil
		local consecutiveRoundsWithoutProgress = 0
		local socialDynamicsTimer = 0
		local totalSocialInfluenceEvents = 0

		while Deliberation.Active and Deliberation.Round < 25 do
			Deliberation.Round += 1
			socialDynamicsTimer += 1

			-- Phase transitions with social effects
			if Deliberation.Round == 5 then
				Deliberation.Phase = "Discussion"
				print("\n--- Moving to open discussion phase ---")
				SocialDynamics.formConversationGroups(JurySpawner.Registry)
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

			-- Update social dynamics periodically
			if socialDynamicsTimer >= 3 then
				SocialDynamics.formConversationGroups(JurySpawner.Registry)
				socialDynamicsTimer = 0
			end

			-- Select speaker with social influence data
			local speakerId, speakerData, activeInfluencers = selectNextSpeaker(lastSpeakerId)

			if not speakerId or not speakerData then
				print("No speaker selected, ending deliberation")
				break
			end

			local juror = speakerData.juror

			-- Analyze social context for this speaker
			local socialContext = analyzeSocialContext(speakerId, activeInfluencers)

			-- Get current jury cognitive states for evidence selection
			local jurorStates = {}
			for id, data in pairs(JurySpawner.Registry) do
				if data and data.juror then
					jurorStates[id] = data.juror:getCognitiveState()
				end
			end

			-- Select evidence based on current jury state
			local evidence = CaseFile.getRelevantEvidence(jurorStates)

			if evidence then
				-- Enhanced evidence evaluation with social context
				local evaluation
				if next(activeInfluencers) and juror.EvaluateEvidenceWithSocialContext then
					-- Use enhanced social evaluation if available
					evaluation = juror:EvaluateEvidenceWithSocialContext(evidence, socialContext, activeInfluencers)
				else
					-- Fall back to standard evaluation
					evaluation = juror:EvaluateEvidence(evidence)
				end

				-- Generate socially-aware statement
				local statement, statementType =
					generateSocialStatement(juror, evidence, evaluation, socialContext, activeInfluencers)
				juror:Speak(statement)

				-- Enhanced social effect display
				if evaluation.socialInfluence and next(evaluation.socialInfluence) then
					totalSocialInfluenceEvents += 1
					print(`[Social Influence] {juror.Id} influenced by {evaluation.influencedBy} - beliefs changed:`)
					for belief, change in pairs(evaluation.socialInfluence) do
						print(`  {belief}: {math.floor(change * 100)}% change`)
					end

					-- Show visual effect for social influence
					JurorVisuals.triggerInsightEffect(speakerData.model, 0.6)
				end

				-- Show social interaction effects
				if socialContext.isDominant then
					print(`[Dominant Speaker] {juror.Id} commanding attention`)
				elseif socialContext.inGroup then
					print(
						`[Group Discussion] {juror.Id} in group {socialContext.groupId}, role: {socialContext.groupRole}`
					)
				elseif socialContext.isDeferring then
					print(`[Deference] {juror.Id} yielding to {SocialDynamics.DominantSpeaker}`)
				end

				-- Check for high-impact moments
				local totalMeaning = evaluation.totalMeaning
					or evaluation.effectiveMeaning
					or evaluation.rawMeaning
					or 0
				if totalMeaning > 0.7 then
					consecutiveRoundsWithoutProgress = 0
					print(`[High Impact] {juror.Id}: Total meaning = {math.floor(totalMeaning * 100)}%`)

					if evaluation.socialMeaning and evaluation.socialMeaning > 0.3 then
						print(`  Social component: {math.floor(evaluation.socialMeaning * 100)}%`)
					end

					-- High impact moments can shift social dynamics
					if math.random() < 0.3 then
						JurorVisuals.triggerInsightEffect(speakerData.model, totalMeaning)
					end
				else
					consecutiveRoundsWithoutProgress += 1
				end
			else
				-- Fallback discussion
				local statement = "I'm still considering all the evidence we've heard."
				juror:Speak(statement)
				consecutiveRoundsWithoutProgress += 1
			end

			lastSpeakerId = speakerId

			-- Check for early consensus with social stability
			local currentConsensus = calculateConsensus()
			local socialStability = calculateSocialStability()

			if currentConsensus > 0.85 and socialStability > 0.7 and Deliberation.Round > 8 then
				print(`\nHigh consensus + social stability detected - moving to final vote`)
				print(
					`Consensus: {math.floor(currentConsensus * 100)}%, Social Stability: {math.floor(
						socialStability * 100
					)}%`
				)
				break
			end

			-- End if no progress and low social activity
			if consecutiveRoundsWithoutProgress > 5 and socialStability < 0.3 then
				print("\nDeliberation stalled with low social activity - calling final vote")
				break
			end

			task.wait(math.random(3, 6))
		end

		-- Final vote with social context
		print("\n=== FINAL VOTE ===")
		SocialDynamics.clearConversationLines()
		local finalResult = conductVote("Final")
		announceVoteResults(finalResult)

		-- Print comprehensive social influence statistics
		print(`\n=== SOCIAL INFLUENCE ANALYSIS ===`)
		print(`Total social influence events: {totalSocialInfluenceEvents}`)

		local influenceByType = {}
		local influenceByJuror = {}

		for _, event in ipairs(Deliberation.SocialInfluenceHistory) do
			influenceByType[event.relationship] = (influenceByType[event.relationship] or 0) + 1
			influenceByJuror[event.influenced] = (influenceByJuror[event.influenced] or 0) + 1
		end

		print("Influence by relationship type:")
		for relType, count in pairs(influenceByType) do
			print(`  {relType}: {count} events`)
		end

		print("Most influenced jurors:")
		local sortedInfluenced = {}
		for jurorId, count in pairs(influenceByJuror) do
			table.insert(sortedInfluenced, { id = jurorId, count = count })
		end
		table.sort(sortedInfluenced, function(a, b)
			return a.count > b.count
		end)

		for i = 1, math.min(3, #sortedInfluenced) do
			local entry = sortedInfluenced[i]
			local jurorData = JurySpawner.Registry[entry.id]
			local personalityType = jurorData and jurorData.personality and jurorData.personality.name or "Unknown"
			print(`  {entry.id} ({personalityType}): {entry.count} times influenced`)
		end

		Deliberation.Active = false
	end)
end

function Deliberation.forceVote()
	if not Deliberation.Active then
		return
	end

	SocialDynamics.clearConversationLines()
	local result = conductVote("Forced")
	announceVoteResults(result)
	return result
end

function Deliberation.getStatus()
	local socialStatus = SocialDynamics.getStatus()

	return {
		active = Deliberation.Active,
		round = Deliberation.Round,
		phase = Deliberation.Phase,
		consensus = calculateConsensus(),
		votingHistory = Deliberation.VotingHistory,
		socialDynamics = socialStatus,
	}
end

return Deliberation
