-- ServerScriptService/InitializeJury (server script)

local JurySpawner = require(game.ServerStorage.JurySpawner)
local Deliberation = require(game.ServerScriptService.Deliberation)
local CaseFile = require(game.ServerStorage.CaseFile)

print("=== INITIALIZING ADVANCED JURY SIMULATION ===")
print("Demonstrating Hum and Jolt Cognitive Theory")
print("By Xander - Belief Graph Dynamics in Legal Reasoning\n")

-- Spawn diverse jury with cognitive personalities
JurySpawner.spawnJury()

-- Wait for jury to be seated
task.wait(3)

print("\n=== CASE OVERVIEW ===")
print(`Defendant: {CaseFile.SuspectName}`)
print(`Charges: {table.concat(CaseFile.Charges, ", ")}`)
print(CaseFile.getSummary())

-- Structured evidence presentation demonstrating cognitive dynamics
task.spawn(function()
	task.wait(2)

	print("\n=== EVIDENCE PRESENTATION PHASE ===")

	-- Phase 1: Opening Evidence (Set the scene)
	print("\n--- Opening: Setting the Scene ---")
	CaseFile.revealCategory("Opening")
	task.wait(3)

	-- Let jurors process initial evidence
	print("Giving jury time to process opening evidence...")
	task.wait(5)

	-- Phase 2: Prosecution Case
	print("\n--- Prosecution: Building the Case ---") 
	CaseFile.revealCategory("Prosecution")
	task.wait(3)

	print("Prosecution evidence presented. Monitoring cognitive responses...")
	task.wait(4)

	-- Phase 3: Defense Response  
	print("\n--- Defense: Creating Reasonable Doubt ---")
	CaseFile.revealCategory("Defense")
	task.wait(3)

	print("Defense evidence presented. Observing belief network changes...")
	task.wait(4)

	-- Phase 4: Technical Evidence (High complexity)
	print("\n--- Technical: Complex Forensic Evidence ---")
	CaseFile.revealCategory("Technical")
	task.wait(3)

	print("Technical evidence may increase processing load and affect coherence...")
	task.wait(3)

	-- Print mid-point jury analysis
	print("\n=== MID-DELIBERATION ANALYSIS ===")
	local stats = JurySpawner.getJuryStats()
	print(`Average Coherence: {math.floor(stats.avgCoherence * 100)}%`)
	print(`Average Guilt Belief: {math.floor(stats.avgGuilt * 100)}%`)

	local evidenceStats = CaseFile.getEvidenceStats()
	print(`Evidence Prosecution Bias: {math.floor(evidenceStats.prosecutionBias * 100)}%`)
	print(`Evidence Complexity: {math.floor(evidenceStats.avgComplexity * 100)}%`)

	task.wait(2)

	-- Begin formal deliberation
	print("\n=== FORMAL DELIBERATION BEGINS ===")
	print("Jurors will now discuss evidence using cognitive belief networks")
	print("Watch for:")
	print("- High meaning moments (aha! insights)")
	print("- Coherence changes (confusion vs clarity)")
	print("- Personality-driven responses")
	print("- Belief network propagation effects")

	Deliberation.begin()
end)

-- Monitoring task to track cognitive dynamics
task.spawn(function()
	task.wait(10) -- Start monitoring after initial setup

	local monitoringActive = true
	local lastReportTime = tick()

	while monitoringActive do
		task.wait(15) -- Report every 15 seconds

		if not Deliberation.Active then
			monitoringActive = false
			break
		end

		local currentTime = tick()
		if currentTime - lastReportTime >= 15 then
			print("\n--- COGNITIVE MONITORING REPORT ---")

			local totalCoherence = 0
			local totalGuilt = 0
			local highMeaningEvents = 0
			local jurorCount = 0

			for id, data in pairs(JurySpawner.Registry) do
				local juror = data.juror
				local state = juror:getCognitiveState()

				totalCoherence += state.coherence
				totalGuilt += state.overallGuilt
				jurorCount += 1

				-- Check for recent high-meaning events
				if state.recentMeaning > 0.6 then
					highMeaningEvents += 1
					print(`[Insight] {id} ({data.personality and data.personality.name or "Unknown"}): High meaning event detected`)
				end

				-- Report extreme states
				if state.coherence < 0.3 then
					print(`[Confusion] {id}: Low coherence ({math.floor(state.coherence * 100)}%)`)
				elseif state.coherence > 0.8 then
					print(`[Clarity] {id}: High coherence ({math.floor(state.coherence * 100)}%)`)
				end
			end

			if jurorCount > 0 then
				local avgCoherence = totalCoherence / jurorCount
				local avgGuilt = totalGuilt / jurorCount

				print(`Average Coherence: {math.floor(avgCoherence * 100)}%`)
				print(`Average Guilt: {math.floor(avgGuilt * 100)}%`)
				print(`High Meaning Events: {highMeaningEvents}`)

				-- Calculate consensus
				local consensus = 1 - math.abs(0.5 - avgGuilt) * 2
				print(`Consensus Level: {math.floor(consensus * 100)}%`)
			end

			lastReportTime = currentTime
		end
	end

	-- Final analysis when deliberation ends
	task.wait(2)
	print("\n=== FINAL COGNITIVE ANALYSIS ===")

	local finalStats = JurySpawner.getJuryStats()
	print(`Final Average Coherence: {math.floor(finalStats.avgCoherence * 100)}%`)
	print(`Final Average Guilt: {math.floor(finalStats.avgGuilt * 100)}%`)

	print("\nPersonality Impact Analysis:")
	for personalityType, _count in pairs(finalStats.personalityDistribution) do
		local juror = JurySpawner.getJurorByPersonality(personalityType)
		if juror then
			local guilt = juror:calculateOverallGuilt()
			print(`{personalityType}: {math.floor(guilt * 100)}% guilt belief`)
		end
	end
end)