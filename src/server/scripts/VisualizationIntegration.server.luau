-- ServerScriptService/SocialDynamicsIntegration (Integration Guide)
-- Shows how to integrate the enhanced social dynamics system

local JurySpawner = require(game.ServerStorage.JurySpawner)
local SocialDynamics = require(game.ServerStorage.SocialDynamics)
local JurorVisuals = require(game.ServerStorage.JurorVisuals)
local Deliberation = require(game.ServerScriptService.Deliberation) -- Enhanced version
local CaseFile = require(game.ServerStorage.CaseFile)
local TimelineDisplay = require(game.ServerStorage.TimelineDisplay)

print("=== INITIALIZING SOCIAL JURY SIMULATION ===")
print("Enhanced with:")
print("• Dominant Speaker Detection")
print("• Conversation Group Formation") 
print("• Social Deference Mechanics")
print("• Visual Conversation Networks")
print("• Realistic Interruption Dynamics")
print("By Xander - Advanced Social Dynamics in Legal Reasoning\n")

-- Enhanced initialization with social dynamics monitoring
task.spawn(function()
	-- Wait for jury to be seated
	task.wait(2)

	-- Spawn diverse jury with personality archetypes
	JurySpawner.spawnJury()
	
	-- Connect visual effects to all jurors (including social effects)
	JurorVisuals.connectToAllJurors(JurySpawner.Registry)
	
	-- Initialize timeline display
	TimelineDisplay.initialize()
	TimelineDisplay.setPhase("Pre-Trial")

	task.wait(3)

	print("\n=== SOCIAL DYNAMICS FEATURES DEMO ===")
	
	-- Demonstrate dominant speaker identification
	task.spawn(function()
		task.wait(5)
		print("\n[DEMO] Identifying initial dominant speakers...")
		
		local dominantId, dominantData = SocialDynamics.identifyDominantSpeaker(JurySpawner.Registry)
		if dominantId then
			print(`Initial dominant speaker: ${dominantId} (${dominantData.personality and dominantData.personality.name or "Unknown personality"})`)
			
			-- Show dominance effect
			SocialDynamics.showDominanceEffect(dominantData.model, 0.8)
			
			-- Trigger deference from others
			SocialDynamics.triggerDeference(JurySpawner.Registry, dominantId)
		else
			print("No clear dominant speaker initially - good jury balance!")
		end
	end)

	-- Demonstrate conversation group formation
	task.spawn(function()
		task.wait(8)
		print("\n[DEMO] Forming initial conversation groups...")
		
		SocialDynamics.formConversationGroups(JurySpawner.Registry)
		
		local socialStatus = SocialDynamics.getStatus()
		print(`Formed ${socialStatus.activeConversations} conversation groups`)
		print(`Active conversation lines: ${socialStatus.conversationLines}`)
	end)

	-- Case presentation with social dynamics
	task.wait(10)
	
	print("\n=== CASE OVERVIEW ===")
	print(`Defendant: {CaseFile.SuspectName}`)
	print(`Charges: {table.concat(CaseFile.Charges, ", ")}`)
	print(CaseFile.getSummary())

	-- Enhanced evidence presentation with social monitoring
	task.spawn(function()
		task.wait(2)

		print("\n=== EVIDENCE PRESENTATION WITH SOCIAL DYNAMICS ===")

		-- Phase 1: Opening Evidence
		print("\n--- Opening: Setting the Scene ---")
		CaseFile.revealCategory("Opening")
		
		-- Monitor social reactions to opening evidence
		task.wait(3)
		local socialStatus = SocialDynamics.getStatus()
		print(`Social reaction: ${socialStatus.activeConversations} groups discussing, dominant speaker: ${socialStatus.dominantSpeaker or "None"}`)
		
		task.wait(2)

		-- Phase 2: Prosecution Case
		print("\n--- Prosecution: Building the Case ---") 
		CaseFile.revealCategory("Prosecution")
		
		-- Strong prosecution evidence might create dominant speakers
		task.wait(3)
		print("Monitoring for strong reactions and potential dominant speakers...")
		local dominantId, dominantData = SocialDynamics.identifyDominantSpeaker(JurySpawner.Registry)
		if dominantId then
			print(`Strong evidence created dominant speaker: ${dominantId}`)
			
			-- Show visual effects
			JurorVisuals.showThoughtBubble(dominantData.model, "This evidence is compelling!", "authority")
		end
		
		task.wait(4)

		-- Phase 3: Defense Response
		print("\n--- Defense: Creating Reasonable Doubt ---")
		CaseFile.revealCategory("Defense")
		
		-- Defense evidence might cause interruptions or challenges
		task.wait(3)
		print("Defense evidence may trigger interruptions and challenges...")
		
		-- Simulate potential interruption
		for id, data in pairs(JurySpawner.Registry) do
			local juror = data.juror
			if juror.PersonalityTraits.Decisive > 0.8 and math.random() < 0.3 then
				print(`${id} (${data.personality.name}) attempting to interrupt with counterpoint`)
				JurorVisuals.showInterruptionEffect(data.model, 0.7)
				break
			end
		end
		
		task.wait(4)

		-- Phase 4: Technical Evidence
		print("\n--- Technical: Complex Forensic Evidence ---")
		CaseFile.revealCategory("Technical")
		
		-- Complex evidence affects group dynamics
		task.wait(3)
		print("Technical evidence creating confusion - reforming conversation groups...")
		SocialDynamics.formConversationGroups(JurySpawner.Registry)
		
		-- Show confusion effects on overwhelmed jurors
		for id, data in pairs(JurySpawner.Registry) do
			local state = data.juror:getCognitiveState()
			if state.processingLoad > 0.7 then
				print(`${id} showing confusion from complex evidence`)
				JurorVisuals.showCoherenceCracks(data.model, state.coherence)
			end
		end

		task.wait(3)

		-- Enhanced mid-deliberation analysis
		print("\n=== ENHANCED MID-DELIBERATION ANALYSIS ===")
		local stats = JurySpawner.getJuryStats()
		local socialStatus = SocialDynamics.getStatus()
		
		print(`Cognitive State:`)
		print(`  Average Coherence: {math.floor(stats.avgCoherence * 100)}%`)
		print(`  Average Guilt Belief: {math.floor(stats.avgGuilt * 100)}%`)
		
		print(`Social Dynamics:`)
		print(`  Active Conversations: {socialStatus.activeConversations}`)
		print(`  Dominant Speaker: {socialStatus.dominantSpeaker or "None"}`)
		print(`  Last Speaker: {socialStatus.lastSpeaker or "None"}`)
		print(`  Conversation Lines: {socialStatus.conversationLines}`)

		-- Analyze personality impact on social dynamics
		print(`\nPersonality-Social Dynamics Analysis:`)
		for personalityType, count in pairs(stats.personalityDistribution) do
			local exampleJuror = JurySpawner.getJurorByPersonality(personalityType)
			if exampleJuror then
				local traits = exampleJuror.PersonalityTraits
				local dominancePotential = (traits.Decisive * 0.4) + (traits.Analytical * 0.2) + ((1 - traits.Cautious) * 0.2)
				print(`  ${personalityType} (${count}): Dominance potential = ${math.floor(dominancePotential * 100)}%`)
			end
		end

		task.wait(3)

		-- Begin enhanced deliberation
		print("\n=== ENHANCED DELIBERATION WITH SOCIAL DYNAMICS ===")
		print("Features active:")
		print("• Dynamic speaker selection based on social dominance")
		print("• Conversation group formation and rotation")
		print("• Visual conversation networks with beams")
		print("• Deference mechanics for dominant speakers")
		print("• Interruption attempts and social challenges")
		print("• Real-time social influence propagation")
		
		Deliberation.begin()
	end)
end)

-- Enhanced monitoring system that tracks both cognitive and social states
task.spawn(function()
	task.wait(15) -- Start after initial setup

	local monitoringActive = true
	local lastReportTime = tick()

	while monitoringActive do
		task.wait(20) -- Report every 20 seconds

		if not Deliberation.Active then
			monitoringActive = false
			break
		end

		local currentTime = tick()
		if currentTime - lastReportTime >= 20 then
			print("\n--- ENHANCED COGNITIVE & SOCIAL MONITORING ---")

			-- Cognitive state analysis
			local totalCoherence = 0
			local totalGuilt = 0
			local highMeaningEvents = 0
			local jurorCount = 0

			-- Social state analysis
			local socialStatus = SocialDynamics.getStatus()
			local interactionMatrix = {} -- Track who's talking to whom

			for id, data in pairs(JurySpawner.Registry) do
				local juror = data.juror
				local state = juror:getCognitiveState()

				totalCoherence += state.coherence
				totalGuilt += state.overallGuilt
				jurorCount += 1

				-- Track high-meaning cognitive events
				if state.recentMeaning > 0.6 then
					highMeaningEvents += 1
					print(`[Cognitive Insight] ${id}: High meaning event (${math.floor(state.recentMeaning * 100)}%)`)
				end

				-- Track extreme cognitive states
				if state.coherence < 0.3 then
					print(`[Cognitive Confusion] ${id}: Low coherence (${math.floor(state.coherence * 100)}%)`)
					-- Show visual confusion
					JurorVisuals.showCoherenceCracks(data.model, state.coherence)
				elseif state.coherence > 0.8 and (state.overallGuilt < 0.2 or state.overallGuilt > 0.8) then
					print(`[Cognitive Certainty] ${id}: High coherence + strong belief (${math.floor(state.coherence * 100)}% coherence, ${math.floor(state.overallGuilt * 100)}% guilt)`)
				end

				-- Analyze social dominance potential
				local traits = juror.PersonalityTraits
				local dominanceScore = (traits.Decisive * 0.4) + (traits.Analytical * 0.2) + 
				                      ((1 - traits.Cautious) * 0.2) + (state.coherence * 0.2)
				
				if dominanceScore > 0.7 and id ~= socialStatus.dominantSpeaker then
					print(`[Social Potential] ${id}: High dominance potential (${math.floor(dominanceScore * 100)}%)`)
				end
			end

			-- Aggregate reporting
			if jurorCount > 0 then
				local avgCoherence = totalCoherence / jurorCount
				local avgGuilt = totalGuilt / jurorCount

				print(`\nCognitive Summary:`)
				print(`  Average Coherence: ${math.floor(avgCoherence * 100)}%`)
				print(`  Average Guilt Belief: ${math.floor(avgGuilt * 100)}%`)
				print(`  High Meaning Events: ${highMeaningEvents}`)

				print(`\nSocial Summary:`)
				print(`  Active Conversations: ${socialStatus.activeConversations}`)
				print(`  Current Dominant Speaker: ${socialStatus.dominantSpeaker or "None"}`)
				print(`  Visual Conversation Lines: ${socialStatus.conversationLines}`)
				
				-- Calculate jury polarization
				local consensus = 1 - math.abs(0.5 - avgGuilt) * 2
				print(`  Consensus Level: ${math.floor(consensus * 100)}%`)
				
				if socialStatus.dominantSpeaker then
					local dominantData = JurySpawner.Registry[socialStatus.dominantSpeaker]
					if dominantData then
						print(`  Dominant Speaker Type: ${dominantData.personality.name}`)
					end
				end
			end

			lastReportTime = currentTime
		end
	end

	-- Final comprehensive analysis
	task.wait(2)
	print("\n=== FINAL COMPREHENSIVE ANALYSIS ===")

	local finalStats = JurySpawner.getJuryStats()
	local finalSocialStatus = SocialDynamics.getStatus()
	
	print(`\nFinal Cognitive State:`)
	print(`  Average Coherence: ${math.floor(finalStats.avgCoherence * 100)}%`)
	print(`  Average Guilt Belief: ${math.floor(finalStats.avgGuilt * 100)}%`)

	print(`\nSocial Dynamics Impact:`)
	print(`  Total Conversation Groups Formed: ${finalSocialStatus.activeConversations}`)
	print(`  Final Dominant Speaker: ${finalSocialStatus.dominantSpeaker or "None"}`)
	
	print(`\nPersonality-Social Analysis:`)
	for personalityType, count in pairs(finalStats.personalityDistribution) do
		local juror = JurySpawner.getJurorByPersonality(personalityType)
		if juror then
			local guilt = juror:calculateOverallGuilt()
			local traits = juror.PersonalityTraits
			local socialInfluence = (traits.Decisive + traits.Analytical + (1 - traits.Cautious)) / 3
			print(`  ${personalityType} (${count}): ${math.floor(guilt * 100)}% guilt, ${math.floor(socialInfluence * 100)}% social influence`)
		end
	end
	
	-- Clear all social effects
	SocialDynamics.clearConversationLines()
	SocialDynamics.clearDominance(JurySpawner.Registry)
	
	print("\n=== SOCIAL DYNAMICS SIMULATION COMPLETE ===")
end)