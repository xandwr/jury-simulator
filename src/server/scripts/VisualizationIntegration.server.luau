-- ServerScriptService/VisualizationIntegration (server script)
-- Connects the cognitive visualization system to the jury simulation

local JurySpawner = require(game.ServerStorage.JurySpawner)
local Deliberation = require(game.ServerScriptService.Deliberation)
local CaseFile = require(game.ServerStorage.CaseFile)
local JurorVisuals = require(game.ServerStorage.JurorVisuals)
local TimelineDisplay = require(game.ServerStorage.TimelineDisplay)

print("\n=== INITIALIZING VISUALIZATION INTEGRATION ===")

-- Initialize the timeline display
TimelineDisplay.initialize()
TimelineDisplay.setPhase("Pre-Trial")

-- Enhanced CaseFile integration
local OriginalReveal = CaseFile.reveal
CaseFile.reveal = function(evidenceId)
	local evidence = OriginalReveal(evidenceId)
	if evidence then
		-- Calculate jury impact
		local juryReactions = {
			totalJurors = 0,
			highImpactJurors = 0,
			averageCoherence = 0,
			strongReactions = {}
		}
		
		local totalCoherence = 0
		
		for id, data in pairs(JurySpawner.Registry) do
			local juror = data.juror
			local model = data.model
			
			juryReactions.totalJurors += 1
			
			-- Get current state for baseline
			local priorCoherence = juror.CognitiveCoherence
			local priorGuilt = juror:calculateOverallGuilt()
			
			-- Present evidence to juror (this will trigger visual effects)
			local evaluation = juror:EvaluateEvidence(evidence)
			
			totalCoherence += juror.CognitiveCoherence
			
			-- Track high impact moments
			if evaluation.effectiveMeaning > 0.6 then
				juryReactions.highImpactJurors += 1
				table.insert(juryReactions.strongReactions, {
					jurorId = id,
					meaningLevel = evaluation.effectiveMeaning,
					beliefType = evaluation.newCoherence > priorCoherence and "clarity" or "confusion"
				})
				
				-- Trigger insight effect for high meaning
				JurorVisuals.triggerInsightEffect(
					model, 
					evaluation.newCoherence > priorCoherence and "clarity" or "confusion",
					evaluation.effectiveMeaning
				)
			end
			
			-- Show thought based on reaction
			local newGuilt = juror:calculateOverallGuilt()
			local guiltChange = newGuilt - priorGuilt
			
			if math.abs(guiltChange) > 0.2 then
				local thoughtType = newGuilt > 0.6 and "strongGuilt" or "strongDoubt"
				local phrases = {
					strongGuilt = {
						"The evidence is mounting...",
						"This seals it for me.",
						"Hard to deny guilt now."
					},
					strongDoubt = {
						"This creates serious doubt.",
						"I'm questioning everything now.",
						"The case is falling apart."
					}
				}
				
				local selectedPhrases = phrases[thoughtType]
				if selectedPhrases then
					local phrase = selectedPhrases[math.random(1, #selectedPhrases)]
					JurorVisuals.showThoughtBubble(model, phrase, thoughtType)
				end
			end
		end
		
		if juryReactions.totalJurors > 0 then
			juryReactions.averageCoherence = math.floor((totalCoherence / juryReactions.totalJurors) * 100)
		end
		
		-- Update timeline with evidence presentation
		TimelineDisplay.onEvidencePresented(evidence, juryReactions)
		
		print(`[Evidence Impact] {evidence.Id}: ${juryReactions.highImpactJurors}/${juryReactions.totalJurors} high-impact reactions`)
	end
	
	return evidence
end

-- Enhanced CaseFile category reveal
local OriginalRevealCategory = CaseFile.revealCategory
CaseFile.revealCategory = function(categoryName)
	print(`\n=== PRESENTING {categoryName:upper()} EVIDENCE ===`)
	TimelineDisplay.setPhase(categoryName)
	
	local evidence = OriginalRevealCategory(categoryName)
	
	-- Add category introduction to timeline
	local descriptions = {
		Opening = "Setting the scene with initial evidence",
		Prosecution = "Building the case for guilt",
		Defense = "Creating reasonable doubt",
		Technical = "Complex forensic analysis"
	}
	
	TimelineDisplay.addEvent(categoryName, `${categoryName} Evidence Phase`, descriptions[categoryName] or "")
	
	return evidence
end

-- Enhanced Deliberation integration
local OriginalDeliberationBegin = Deliberation.begin
Deliberation.begin = function()
	TimelineDisplay.setPhase("Deliberation")
	TimelineDisplay.addEvent("Deliberation", "Formal Deliberation Begins", "Jury begins private discussion")
	
	return OriginalDeliberationBegin()
end

-- Hook into the voting system
task.spawn(function()
	-- Wait for deliberation module to be ready
	task.wait(1)
	
	-- Find and enhance the conductVote function
	local DeliberationModule = require(game.ServerScriptService.Deliberation)
	
	-- Monitor voting by checking voting history
	local lastVoteCount = 0
	local monitoringActive = true
	
	task.spawn(function()
		while monitoringActive do
			task.wait(2)
			
			local status = DeliberationModule.getStatus()
			if status.votingHistory and #status.votingHistory > lastVoteCount then
				-- New vote detected
				local latestVote = status.votingHistory[#status.votingHistory]
				TimelineDisplay.onVote(latestVote)
				
				-- Show vote visualization effects
				for id, voterDetail in pairs(latestVote.details) do
					local data = JurySpawner.Registry[id]
					if data then
						local beliefType = "confusion"
						if voterDetail.vote == "guilty" then
							beliefType = "guilt"
						elseif voterDetail.vote == "notGuilty" then
							beliefType = "doubt"
						end
						
						JurorVisuals.createBeliefHalo(data.model, beliefType, voterDetail.coherence or 0.5)
					end
				end
				
				-- Check for unanimous verdict
				if latestVote.unanimous then
					TimelineDisplay.addEvent("Deliberation", "UNANIMOUS VERDICT REACHED!", 
						`Final decision: ${latestVote.votes.guilty > 0 and "GUILTY" or "NOT GUILTY"}`)
					monitoringActive = false
				end
				
				lastVoteCount = #status.votingHistory
			end
			
			if not DeliberationModule.Active then
				monitoringActive = false
			end
		end
	end)
end)

-- Monitor jury cognitive state changes
task.spawn(function()
	task.wait(5) -- Wait for jury to be fully initialized
	
	-- Connect visual effects to all jurors
	JurorVisuals.connectToAllJurors(JurySpawner.Registry)
	
	print("[VisualizationIntegration] All visual effects connected to jury")
	
	-- Periodic jury state monitoring
	local lastReportTime = tick()
	
	while true do
		task.wait(10)
		
		local currentTime = tick()
		if currentTime - lastReportTime >= 30 then -- Report every 30 seconds
			
			-- Gather jury state
			local totalCoherence = 0
			local totalGuilt = 0
			local extremeStates = {confused = {}, certain = {}}
			local jurorCount = 0
			
			for id, data in pairs(JurySpawner.Registry) do
				local juror = data.juror
				local model = data.model
				local state = juror:getCognitiveState()
				
				totalCoherence += state.coherence
				totalGuilt += state.overallGuilt
				jurorCount += 1
				
				-- Check for extreme cognitive states
				if state.coherence < 0.3 then
					table.insert(extremeStates.confused, {id = id, coherence = state.coherence})
					-- Show ongoing confusion effect
					JurorVisuals.showCoherenceCracks(model, state.coherence)
				elseif state.coherence > 0.8 and (state.overallGuilt < 0.2 or state.overallGuilt > 0.8) then
					table.insert(extremeStates.certain, {id = id, guilt = state.overallGuilt, coherence = state.coherence})
					-- Show certainty halo
					local beliefType = state.overallGuilt > 0.5 and "guilt" or "doubt"
					JurorVisuals.createBeliefHalo(model, beliefType, state.coherence)
				end
			end
			
			if jurorCount > 0 then
				local avgCoherence = totalCoherence / jurorCount
				local avgGuilt = totalGuilt / jurorCount
				
				-- Create jury state summary for timeline
				local stateDetails = `Avg Coherence: ${math.floor(avgCoherence * 100)}% | Avg Guilt Belief: ${math.floor(avgGuilt * 100)}%`
				if #extremeStates.confused > 0 then
					stateDetails = stateDetails .. ` | ${#extremeStates.confused} confused`
				end
				if #extremeStates.certain > 0 then
					stateDetails = stateDetails .. ` | ${#extremeStates.certain} certain`
				end
				
				TimelineDisplay.addEvent("Monitoring", "Jury State Update", stateDetails)
			end
			
			lastReportTime = currentTime
		end
	end
end)