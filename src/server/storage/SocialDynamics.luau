-- ServerStorage/SocialDynamics (Fixed Version)
-- Enhanced error handling, removed duplicates, improved conversation management

local TweenService = game:GetService("TweenService")
local JurorVisuals = require(game.ServerStorage.JurorVisuals)

local SocialDynamics = {}

-- Social state tracking
SocialDynamics.ActiveConversations = {}
SocialDynamics.ConversationHistory = {}
SocialDynamics.LastSpeaker = nil
SocialDynamics.DominantSpeaker = nil
SocialDynamics.DominanceStartTime = 0
SocialDynamics.InfluenceNetwork = {}
SocialDynamics.ConversationLines = {}

-- Enhanced configuration
local SOCIAL_CONFIG = {
	dominanceThreshold = 0.75,
	dominanceDuration = 15,
	conversationRadius = 8,
	interruption = {
		threshold = 0.85,
		cooldown = 5,
	},
	groupFormation = {
		maxGroupSize = 4,
		formationChance = 0.3,
		stabilityDuration = 20,
	},
	visualEffects = {
		conversationLineWidth = 0.2,
		dominantGlowIntensity = 2.0,
		attentionBeamRange = 6,
	},
	influence = {
		maxInfluenceStrength = 0.4,
		decayRate = 0.1,
		propagationLimit = 2,
	},
}

-- Safe model access helper
local function safeGetPart(model, partName)
	if not model or not model:IsA("Model") then
		return nil
	end
	return model:FindFirstChild(partName)
end

-- Calculate enhanced social dominance
local function calculateDominance(juror, cognitiveState)
	if not juror or not cognitiveState then
		return 0
	end

	local personality = juror.PersonalityTraits or {}
	local archetype = juror.PersonalityArchetype

	-- Base dominance from personality (with nil checks)
	local baseDominance = (personality.Decisive or 0.5) * 0.4
		+ (personality.Analytical or 0.5) * 0.2
		+ ((1 - (personality.Cautious or 0.5)) * 0.2)
		+ (personality.Trusting or 0.5) * 0.1

	-- Archetype bonuses (with nil checks)
	if archetype and archetype.name then
		if archetype.name == "Quick Decider" then
			baseDominance += 0.3
		elseif archetype.name == "Analytical Thinker" then
			baseDominance += 0.2
		elseif archetype.name == "Authority Believer" or archetype.name == "Independent Thinker" then
			baseDominance += 0.15
		elseif archetype.name == "Skeptical Doubter" then
			baseDominance -= 0.1
		end
	end

	-- Cognitive state modifiers (with nil checks)
	local coherenceBonus = (cognitiveState.coherence or 0.5) * 0.3
	local recentMeaningBonus = (cognitiveState.recentMeaning or 0) * 0.4
	local processingLoadPenalty = (cognitiveState.processingLoad or 0) * 0.3

	-- Strong belief conviction increases dominance
	local convictionBonus = 0
	local guilt = cognitiveState.overallGuilt or 0.5
	if guilt > 0.8 or guilt < 0.2 then
		convictionBonus = 0.2
	end

	local totalDominance = baseDominance + coherenceBonus + recentMeaningBonus + convictionBonus - processingLoadPenalty

	return math.clamp(totalDominance, 0, 1)
end

-- Enhanced dominant speaker identification with error handling
function SocialDynamics.identifyDominantSpeaker(juryRegistry)
	if not juryRegistry or not next(juryRegistry) then
		return nil, nil
	end

	local candidates = {}

	for id, data in pairs(juryRegistry) do
		local success, result = pcall(function()
			if not data or not data.juror then
				return nil
			end

			local juror = data.juror
			local state = juror:getCognitiveState()
			local dominance = calculateDominance(juror, state)

			-- Recent speakers get temporary dominance boost
			if SocialDynamics.LastSpeaker == id then
				dominance = math.min(1.0, dominance + 0.2)
			end

			return {
				id = id,
				data = data,
				dominance = dominance,
				state = state,
			}
		end)

		if success and result then
			table.insert(candidates, result)
		else
			warn(`[SocialDynamics] Error processing juror {id}: {result}`)
		end
	end

	if #candidates == 0 then
		return nil, nil
	end

	-- Sort by dominance
	table.sort(candidates, function(a, b)
		return a.dominance > b.dominance
	end)

	local topCandidate = candidates[1]
	if topCandidate and topCandidate.dominance > SOCIAL_CONFIG.dominanceThreshold then
		-- Check if this is a new dominant speaker
		if SocialDynamics.DominantSpeaker ~= topCandidate.id then
			local oldDominant = SocialDynamics.DominantSpeaker
			SocialDynamics.DominantSpeaker = topCandidate.id
			SocialDynamics.DominanceStartTime = tick()

			print(
				`[SocialDynamics] ${topCandidate.id} became dominant speaker (${math.floor(topCandidate.dominance * 100)}%)`
			)

			-- Clear old dominance effects
			if oldDominant then
				SocialDynamics.clearDominanceForJuror(juryRegistry, oldDominant)
			end

			-- Show new dominance effect
			local success = pcall(function()
				SocialDynamics.showDominanceEffect(topCandidate.data.model, topCandidate.dominance)
				SocialDynamics.triggerDeference(juryRegistry, topCandidate.id)
			end)

			if not success then
				warn(`[SocialDynamics] Error showing dominance effects for {topCandidate.id}`)
			end
		end

		return topCandidate.id, topCandidate.data
	else
		-- No clear dominant speaker
		if SocialDynamics.DominantSpeaker then
			print(`[SocialDynamics] Dominance period ended for ${SocialDynamics.DominantSpeaker}`)
			SocialDynamics.clearDominance(juryRegistry)
		end
		SocialDynamics.DominantSpeaker = nil
		return nil, nil
	end
end

-- Enhanced dominance effect with error handling
function SocialDynamics.showDominanceEffect(jurorModel, dominanceLevel)
	local humanoidRootPart = safeGetPart(jurorModel, "HumanoidRootPart")
	if not humanoidRootPart then
		warn(`[SocialDynamics] Cannot show dominance - no HumanoidRootPart for {jurorModel.Name}`)
		return nil
	end

	-- Remove existing dominance effect
	local existingEffect = humanoidRootPart:FindFirstChild("DominanceEffect")
	if existingEffect then
		existingEffect:Destroy()
	end

	local existingGlow = humanoidRootPart:FindFirstChild("AuthorityGlow")
	if existingGlow then
		existingGlow:Destroy()
	end

	-- Create dominance aura
	local aura = Instance.new("SelectionBox")
	aura.Name = "DominanceEffect"
	aura.Adornee = jurorModel
	aura.Color3 = Color3.fromRGB(255, 215, 0)
	aura.LineThickness = 0.3 * dominanceLevel
	aura.Transparency = 0.2
	aura.Parent = humanoidRootPart

	-- Enhanced pulsing effect
	local pulseInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local pulseTween = TweenService:Create(aura, pulseInfo, {
		Transparency = 0.05,
		LineThickness = 0.6 * dominanceLevel,
	})
	pulseTween:Play()

	-- Add authority spotlight effect
	local spotlight = Instance.new("PointLight")
	spotlight.Name = "AuthorityGlow"
	spotlight.Color = Color3.fromRGB(255, 215, 0)
	spotlight.Brightness = SOCIAL_CONFIG.visualEffects.dominantGlowIntensity * dominanceLevel
	spotlight.Range = SOCIAL_CONFIG.visualEffects.attentionBeamRange
	spotlight.Parent = humanoidRootPart

	-- Show authority thought bubble
	local success = pcall(function()
		local phrases = {
			"I need everyone to hear this.",
			"This is important to understand.",
			"Let me explain this clearly.",
			"We need to focus on this evidence.",
		}
		local phrase = phrases[math.random(1, #phrases)]
		JurorVisuals.showThoughtBubble(jurorModel, phrase, "authority")
	end)

	if not success then
		warn(`[SocialDynamics] Error showing thought bubble for dominance`)
	end

	return { aura = aura, spotlight = spotlight, pulseTween = pulseTween }
end

-- Enhanced deference with improved error handling
function SocialDynamics.triggerDeference(juryRegistry, dominantId)
	if not juryRegistry or not dominantId then
		return
	end

	for id, data in pairs(juryRegistry) do
		if id ~= dominantId and data and data.juror and data.model then
			local success = pcall(function()
				local juror = data.juror
				local model = data.model

				-- Calculate deference based on personality
				local personality = juror.PersonalityTraits or {}
				local deferenceLevel = (personality.Cautious or 0.5) * 0.6 + (personality.Trusting or 0.5) * 0.4

				if deferenceLevel > 0.5 then
					-- Show visual deference
					SocialDynamics.showDeferenceEffect(model, deferenceLevel)

					-- Show deference thoughts occasionally
					if math.random() < 0.3 then
						local deferenceThoughts = {
							"Let them finish...",
							"They make a good point.",
							"I'll wait my turn.",
							"They seem sure about this.",
						}
						local thought = deferenceThoughts[math.random(1, #deferenceThoughts)]
						JurorVisuals.showThoughtBubble(model, thought, "deference")
					end
				elseif deferenceLevel < 0.3 and (personality.Decisive or 0.5) > 0.7 then
					-- Potential interruption candidate
					if math.random() < 0.1 then
						JurorVisuals.showThoughtBubble(model, "I need to interject here...", "interruption")
					end
				end
			end)

			if not success then
				warn(`[SocialDynamics] Error triggering deference for {id}`)
			end
		end
	end
end

-- Fixed deference effect (removed duplicate)
function SocialDynamics.showDeferenceEffect(jurorModel, deferenceLevel)
	local humanoidRootPart = safeGetPart(jurorModel, "HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	-- Remove existing deference effect
	local existingEffect = humanoidRootPart:FindFirstChild("DeferenceEffect")
	if existingEffect then
		existingEffect:Destroy()
	end

	-- Create subtle deference lighting
	local dimEffect = Instance.new("PointLight")
	dimEffect.Name = "DeferenceEffect"
	dimEffect.Color = Color3.fromRGB(100, 100, 200)
	dimEffect.Brightness = 0.3 * deferenceLevel
	dimEffect.Range = 3
	dimEffect.Parent = humanoidRootPart

	-- Show subtle deference aura
	local deferenceAura = Instance.new("SelectionBox")
	deferenceAura.Name = "DeferenceAura"
	deferenceAura.Adornee = jurorModel
	deferenceAura.Color3 = Color3.fromRGB(150, 150, 255)
	deferenceAura.LineThickness = 0.1
	deferenceAura.Transparency = 0.7
	deferenceAura.Parent = humanoidRootPart

	-- Gentle fade effect
	local fadeTween = TweenService:Create(deferenceAura, TweenInfo.new(3), {
		Transparency = 0.9,
	})
	fadeTween:Play()

	-- Auto-remove after time
	task.delay(4, function()
		if dimEffect and dimEffect.Parent then
			dimEffect:Destroy()
		end
		if deferenceAura and deferenceAura.Parent then
			deferenceAura:Destroy()
		end
	end)
end

-- Enhanced conversation group formation with better error handling
function SocialDynamics.formConversationGroups(juryRegistry)
	if not juryRegistry or not next(juryRegistry) then
		warn("[SocialDynamics] Cannot form conversation groups - invalid registry")
		return
	end

	-- Clear existing conversations and lines
	SocialDynamics.clearConversationLines()
	SocialDynamics.ActiveConversations = {}

	local allJurors = {}
	for id, data in pairs(juryRegistry) do
		local success, position = pcall(function()
			if not data or not data.model then
				return nil
			end
			local pivot = data.model:GetPivot()
			return pivot.Position
		end)

		if success and position then
			table.insert(allJurors, {
				id = id,
				data = data,
				position = position,
				assigned = false,
			})
		else
			warn(`[SocialDynamics] Error getting position for {id}`)
		end
	end

	local groupId = 1

	-- Form groups based on proximity and personality
	for _, primaryJuror in ipairs(allJurors) do
		if not primaryJuror.assigned and math.random() < SOCIAL_CONFIG.groupFormation.formationChance then
			local group = { primaryJuror }
			primaryJuror.assigned = true

			-- Find compatible nearby jurors
			for _, otherJuror in ipairs(allJurors) do
				if not otherJuror.assigned and #group < SOCIAL_CONFIG.groupFormation.maxGroupSize then
					local distance = (primaryJuror.position - otherJuror.position).Magnitude

					if distance <= SOCIAL_CONFIG.conversationRadius then
						-- Check personality compatibility
						local compatibility =
							SocialDynamics.calculateCompatibility(primaryJuror.data.juror, otherJuror.data.juror)

						if compatibility > 0.4 and math.random() < compatibility then
							table.insert(group, otherJuror)
							otherJuror.assigned = true
						end
					end
				end
			end

			-- Create conversation group if we have at least 2 people
			if #group >= 2 then
				local participants = {}
				for _, member in ipairs(group) do
					participants[member.id] = member.data
				end

				SocialDynamics.ActiveConversations[groupId] = {
					participants = participants,
					dominantSpeaker = nil,
					startTime = tick(),
					topic = SocialDynamics.generateConversationTopic(group),
				}

				-- Create visual conversation network
				local success = pcall(function()
					SocialDynamics.createConversationLines(group, groupId)
				end)

				if not success then
					warn(`[SocialDynamics] Error creating conversation lines for group {groupId}`)
				end

				print(`[SocialDynamics] Formed conversation group ${groupId} with ${#group} participants`)
				groupId += 1
			end
		end
	end
end

-- Rest of the compatibility calculation and other helper functions remain the same
-- but with added error handling...

function SocialDynamics.calculateCompatibility(juror1, juror2)
	if not juror1 or not juror2 or not juror1.PersonalityTraits or not juror2.PersonalityTraits then
		return 0.5 -- Default compatibility
	end

	local traits1 = juror1.PersonalityTraits
	local traits2 = juror2.PersonalityTraits

	local analyticalCompatibility = 1 - math.abs((traits1.Analytical or 0.5) - (traits2.Analytical or 0.5))
	local emotionalCompatibility = 0.5 + math.abs((traits1.Emotional or 0.5) - (traits2.Emotional or 0.5)) * 0.5
	local cautionCompatibility = 1 - math.abs((traits1.Cautious or 0.5) - (traits2.Cautious or 0.5)) * 0.5
	local decisiveCompatibility = 0.7 + math.abs((traits1.Decisive or 0.5) - (traits2.Decisive or 0.5)) * 0.3
	local trustCompatibility = 1 - math.abs((traits1.Trusting or 0.5) - (traits2.Trusting or 0.5)) * 0.7

	local overallCompatibility = (
		analyticalCompatibility
		+ emotionalCompatibility
		+ cautionCompatibility
		+ decisiveCompatibility
		+ trustCompatibility
	) / 5

	return math.clamp(overallCompatibility, 0, 1)
end

-- Clear dominance for specific juror
function SocialDynamics.clearDominanceForJuror(juryRegistry, jurorId)
	if not juryRegistry or not jurorId then
		return
	end

	local data = juryRegistry[jurorId]
	if data and data.model then
		local humanoidRootPart = safeGetPart(data.model, "HumanoidRootPart")
		if humanoidRootPart then
			local dominanceEffect = humanoidRootPart:FindFirstChild("DominanceEffect")
			if dominanceEffect then
				dominanceEffect:Destroy()
			end

			local authorityGlow = humanoidRootPart:FindFirstChild("AuthorityGlow")
			if authorityGlow then
				authorityGlow:Destroy()
			end
		end
	end
end

-- Enhanced clear dominance with error handling
function SocialDynamics.clearDominance(juryRegistry)
	if not juryRegistry then
		return
	end

	for id, data in pairs(juryRegistry) do
		local success = pcall(function()
			SocialDynamics.clearDominanceForJuror(juryRegistry, id)
		end)

		if not success then
			warn(`[SocialDynamics] Error clearing dominance for {id}`)
		end
	end
end

-- Enhanced conversation line clearing
function SocialDynamics.clearConversationLines()
	for i = #SocialDynamics.ConversationLines, 1, -1 do
		local conversationLine = SocialDynamics.ConversationLines[i]
		local success = pcall(function()
			if conversationLine.pulseTween then
				conversationLine.pulseTween:Cancel()
			end
			if conversationLine.beam and conversationLine.beam.Parent then
				conversationLine.beam:Destroy()
			end
			if conversationLine.attachment1 and conversationLine.attachment1.Parent then
				conversationLine.attachment1:Destroy()
			end
			if conversationLine.attachment2 and conversationLine.attachment2.Parent then
				conversationLine.attachment2:Destroy()
			end
		end)

		if not success then
			warn(`[SocialDynamics] Error clearing conversation line {i}`)
		end

		table.remove(SocialDynamics.ConversationLines, i)
	end
end

-- Enhanced speaker selection with social influence tracking
function SocialDynamics.selectNextSpeaker(juryRegistry, lastSpeakerId)
	if not juryRegistry or not next(juryRegistry) then
		return nil, nil
	end

	-- Track active influences for belief propagation
	local activeInfluencers = {}

	-- Check for dominant speaker first
	local dominantId, dominantData = SocialDynamics.identifyDominantSpeaker(juryRegistry)

	if dominantId and (not lastSpeakerId or dominantId ~= lastSpeakerId) then
		-- Dominant speaker takes priority
		SocialDynamics.LastSpeaker = dominantId

		-- Set up influence data
		activeInfluencers[dominantId] = {
			juror = dominantData.juror,
			relationship = "dominant",
			strength = SOCIAL_CONFIG.influence.maxInfluenceStrength,
		}

		return dominantId, dominantData, activeInfluencers
	end

	-- Form conversation groups periodically
	if math.random() < SOCIAL_CONFIG.groupFormation.formationChance then
		SocialDynamics.formConversationGroups(juryRegistry)
	end

	-- Select from active conversations
	for groupId, conversation in pairs(SocialDynamics.ActiveConversations) do
		if tick() - conversation.startTime < SOCIAL_CONFIG.groupFormation.stabilityDuration then
			-- Select speaker from this conversation group
			local participants = {}
			for id, data in pairs(conversation.participants) do
				if id ~= lastSpeakerId then
					table.insert(participants, { id = id, data = data })
				end
			end

			if #participants > 0 then
				local selected = participants[math.random(1, #participants)]
				SocialDynamics.LastSpeaker = selected.id

				-- Set up group influence data
				for id, data in pairs(conversation.participants) do
					if id ~= selected.id then
						activeInfluencers[id] = {
							juror = data.juror,
							relationship = "group_member",
							strength = SOCIAL_CONFIG.influence.maxInfluenceStrength * 0.6,
						}
					end
				end

				return selected.id, selected.data, activeInfluencers
			end
		end
	end

	-- Fallback to original selection method
	return SocialDynamics.fallbackSpeakerSelection(juryRegistry, lastSpeakerId)
end

-- Add other missing functions with error handling...
function SocialDynamics.generateConversationTopic(group)
	local topics = {
		"evidence_credibility",
		"defendant_character",
		"witness_reliability",
		"reasonable_doubt",
		"legal_process",
		"jury_responsibility",
	}

	if not group or #group == 0 then
		return topics[math.random(1, #topics)]
	end

	-- Weight topics based on group's dominant personality traits
	local dominantTrait = "Analytical"
	local maxTraitValue = 0

	for _, member in ipairs(group) do
		if member.data and member.data.juror and member.data.juror.PersonalityTraits then
			local traits = member.data.juror.PersonalityTraits
			for trait, value in pairs(traits) do
				if value > maxTraitValue then
					maxTraitValue = value
					dominantTrait = trait
				end
			end
		end
	end

	-- Select appropriate topic
	if dominantTrait == "Analytical" then
		return math.random() < 0.5 and "evidence_credibility" or "legal_process"
	elseif dominantTrait == "Emotional" then
		return math.random() < 0.5 and "defendant_character" or "jury_responsibility"
	elseif dominantTrait == "Cautious" then
		return "reasonable_doubt"
	else
		return topics[math.random(1, #topics)]
	end
end

function SocialDynamics.fallbackSpeakerSelection(juryRegistry, lastSpeakerId)
	local candidates = {}

	for id, data in pairs(juryRegistry) do
		if id ~= lastSpeakerId and data and data.juror then
			local success, result = pcall(function()
				local state = data.juror:getCognitiveState()
				local weight = 1.0

				if (state.recentMeaning or 0) > 0.4 then
					weight *= 2.0
				end
				if (state.coherence or 0.5) > 0.6 then
					weight *= 1.5
				end
				if (state.personality and state.personality.Decisive or 0.5) > 0.7 then
					weight *= 1.3
				end
				if (state.processingLoad or 0) > 0.8 then
					weight *= 0.3
				end

				return { id = id, data = data, weight = weight }
			end)

			if success and result then
				table.insert(candidates, result)
			end
		end
	end

	if #candidates == 0 then
		return nil, nil, {}
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
			SocialDynamics.LastSpeaker = candidate.id
			return candidate.id, candidate.data, {}
		end
	end

	-- Final fallback
	local randomCandidate = candidates[math.random(1, #candidates)]
	SocialDynamics.LastSpeaker = randomCandidate.id
	return randomCandidate.id, randomCandidate.data, {}
end

-- Add missing helper functions for conversation lines etc.
function SocialDynamics.createConversationLines(group, groupId)
	for i = 1, #group do
		for j = i + 1, #group do
			local juror1 = group[i]
			local juror2 = group[j]

			local beam = SocialDynamics.createConversationBeam(juror1.data.model, juror2.data.model, groupId)

			if beam then
				table.insert(SocialDynamics.ConversationLines, beam)
			end
		end
	end
end

function SocialDynamics.createConversationBeam(model1, model2, groupId)
	local humanoidRootPart1 = safeGetPart(model1, "HumanoidRootPart")
	local humanoidRootPart2 = safeGetPart(model2, "HumanoidRootPart")

	if not humanoidRootPart1 or not humanoidRootPart2 then
		return nil
	end

	-- Create attachments
	local attachment1 = Instance.new("Attachment")
	attachment1.Name = "ConversationPoint"
	attachment1.Position = Vector3.new(0, 1, 0)
	attachment1.Parent = humanoidRootPart1

	local attachment2 = Instance.new("Attachment")
	attachment2.Name = "ConversationPoint"
	attachment2.Position = Vector3.new(0, 1, 0)
	attachment2.Parent = humanoidRootPart2

	-- Create beam
	local beam = Instance.new("Beam")
	beam.Name = "ConversationBeam_" .. groupId
	beam.Attachment0 = attachment1
	beam.Attachment1 = attachment2
	beam.Width0 = SOCIAL_CONFIG.visualEffects.conversationLineWidth
	beam.Width1 = SOCIAL_CONFIG.visualEffects.conversationLineWidth
	beam.Transparency = NumberSequence.new(0.3)
	beam.Color = ColorSequence.new(Color3.fromRGB(100, 200, 255))
	beam.FaceCamera = true
	beam.Parent = workspace

	-- Subtle pulsing animation
	local pulseInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local pulseTween = TweenService:Create(beam, pulseInfo, {
		Transparency = NumberSequence.new(0.6),
		Width0 = SOCIAL_CONFIG.visualEffects.conversationLineWidth * 1.5,
		Width1 = SOCIAL_CONFIG.visualEffects.conversationLineWidth * 1.5,
	})
	pulseTween:Play()

	return {
		beam = beam,
		attachment1 = attachment1,
		attachment2 = attachment2,
		pulseTween = pulseTween,
	}
end

function SocialDynamics.getStatus()
	return {
		dominantSpeaker = SocialDynamics.DominantSpeaker,
		activeConversations = #SocialDynamics.ActiveConversations,
		conversationLines = #SocialDynamics.ConversationLines,
		lastSpeaker = SocialDynamics.LastSpeaker,
	}
end

return SocialDynamics
