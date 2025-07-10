-- Belief Graph implementing spectral analysis from Hum & Jolt Theory

local BeliefGraph = {}
BeliefGraph.__index = BeliefGraph

-- Centrality metrics for meaning calculation (μ(D))
local CentralityMetrics = {
	degree = function(graph, nodeId)
		local degree = 0
		for _, connection in pairs(graph.connections) do
			if connection.from == nodeId or connection.to == nodeId then
				degree += math.abs(connection.weight)
			end
		end
		return degree
	end,

	betweenness = function(graph, nodeId)
		-- Simplified betweenness centrality
		local betweenness = 0
		local nodes = graph.nodes

		for i = 1, #nodes do
			for j = i + 1, #nodes do
				if nodes[i] ~= nodeId and nodes[j] ~= nodeId then
					local pathThroughNode = graph:shortestPath(nodes[i], nodeId) + graph:shortestPath(nodeId, nodes[j])
					local directPath = graph:shortestPath(nodes[i], nodes[j])

					if pathThroughNode < directPath * 1.1 then -- Within 10% tolerance
						betweenness += 1
					end
				end
			end
		end
		return betweenness
	end,

	pagerank = function(graph, nodeId)
		-- Simplified PageRank approximation
		local damping = 0.85
		local ranks = {}

		-- Initialize
		for _, node in pairs(graph.nodes) do
			ranks[node] = 1.0 / #graph.nodes
		end

		-- Iterate (simplified to 10 iterations)
		for _ = 1, 10 do
			local newRanks = {}
			for _, node in pairs(graph.nodes) do
				newRanks[node] = (1 - damping) / #graph.nodes

				-- Add contributions from incoming links
				for _, connection in pairs(graph.connections) do
					if connection.to == node then
						local outDegree = graph:getOutDegree(connection.from)
						if outDegree > 0 then
							newRanks[node] += damping * ranks[connection.from] / outDegree
						end
					end
				end
			end
			ranks = newRanks
		end

		return ranks[nodeId] or 0
	end,
}

function BeliefGraph.new(nodes, connections)
	local self = setmetatable({}, BeliefGraph)

	self.nodes = nodes or {}
	self.connections = connections or {}
	self.probabilities = {}

	-- Initialize probabilities
	for _, node in ipairs(self.nodes) do
		self.probabilities[node] = math.random(20, 80) / 100
	end

	-- Precompute centrality metrics for efficiency
	self.centralities = {}
	self:computeCentralities()

	return self
end

function BeliefGraph:computeCentralities()
	self.centralities = {}

	for _, node in ipairs(self.nodes) do
		self.centralities[node] = {}

		for metricName, metricFunc in pairs(CentralityMetrics) do
			self.centralities[node][metricName] = metricFunc(self, node)
		end
	end
end

function BeliefGraph:getOutDegree(nodeId)
	local degree = 0
	for _, connection in pairs(self.connections) do
		if connection.from == nodeId then
			degree += 1
		end
	end
	return degree
end

function BeliefGraph:shortestPath(from, to)
	-- Simplified shortest path (could implement Dijkstra for accuracy)
	if from == to then
		return 0
	end

	-- Direct connection check
	for _, connection in pairs(self.connections) do
		if connection.from == from and connection.to == to then
			return 1.0 / math.abs(connection.weight) -- Inverse weight as distance
		end
	end

	return 10 -- Large value for no direct path (could implement proper shortest path)
end

-- Calculate raw meaning μ(D) using weighted centrality changes
function BeliefGraph:calculateRawMeaning(priorGraph, weights)
	local totalMeaning = 0
	weights = weights or { degree = 0.3, betweenness = 0.4, pagerank = 0.3 }

	for _, node in ipairs(self.nodes) do
		local currentH = 0
		local priorH = 0

		-- Calculate weighted centrality scores H_i
		for metricName, weight in pairs(weights) do
			if self.centralities[node] and self.centralities[node][metricName] then
				currentH += weight * self.centralities[node][metricName]
			end

			if priorGraph.centralities[node] and priorGraph.centralities[node][metricName] then
				priorH += weight * priorGraph.centralities[node][metricName]
			end
		end

		-- Normalize to [0,1] range (simplified)
		currentH = math.clamp(currentH, 0, 1)
		priorH = math.clamp(priorH, 0, 1)

		totalMeaning += math.abs(currentH - priorH)
	end

	return totalMeaning
end

-- Calculate trimmed KL divergence D*_KL
function BeliefGraph:calculateTrimmedKL(priorGraph)
	local kl = 0
	local nodeCount = #self.nodes

	for _, node in ipairs(self.nodes) do
		local p_post = self.probabilities[node] or 0.5
		local p_prior = priorGraph.probabilities[node] or 0.5

		-- Avoid log(0) with small epsilon
		local epsilon = 1e-10
		p_post = math.max(p_post, epsilon)
		p_prior = math.max(p_prior, epsilon)

		kl += p_post * math.log(p_post / p_prior)
	end

	-- Apply trimming: min(KL, log|V|)
	local logV = math.log(nodeCount)
	return math.min(kl, logV)
end

-- Calculate cognitive coherence C(t) = Ψ(D;M) × D*_KL/Δt
function BeliefGraph:calculateCoherence(priorGraph, deltaT, salienceWeight)
	deltaT = deltaT or 1.0
	salienceWeight = salienceWeight or 1.0 -- Simplified Ψ

	local trimmedKL = self:calculateTrimmedKL(priorGraph)
	local coherence = salienceWeight * (trimmedKL / deltaT)

	return math.clamp(coherence, 0, 1)
end

-- Calculate effective meaning μ*(D) = μ(D) × σ(β × ΔC_norm)
function BeliefGraph:calculateEffectiveMeaning(priorGraph, beta, weights)
	beta = beta or 2.0

	local rawMeaning = self:calculateRawMeaning(priorGraph, weights)

	-- Calculate normalized coherence change
	local currentCoherence = self:calculateCoherence(priorGraph, 1.0, 1.0)
	local priorCoherence = priorGraph:calculateCoherence(priorGraph, 1.0, 1.0) -- Self-coherence as baseline

	local logV = math.log(#self.nodes)
	local deltaC_norm = (currentCoherence - priorCoherence) / logV

	-- Apply sigmoid weighting
	local sigmoidWeight = 1 / (1 + math.exp(-beta * deltaC_norm))

	return rawMeaning * sigmoidWeight
end

-- Apply evidence and update belief probabilities
function BeliefGraph:applyEvidence(evidence, affectedNodes, strength)
	-- Store prior state for comparison
	local priorGraph = self:clone()

	-- Update affected node probabilities
	for _, nodeId in ipairs(affectedNodes) do
		local currentProb = self.probabilities[nodeId] or 0.5

		local change = strength
		if evidence.Direction == "Against" then
			change = -change
		end

		self.probabilities[nodeId] = math.clamp(currentProb + change, 0, 1)
	end

	-- Recompute centralities after probability changes
	self:computeCentralities()

	-- Return analysis
	return {
		rawMeaning = self:calculateRawMeaning(priorGraph),
		effectiveMeaning = self:calculateEffectiveMeaning(priorGraph),
		coherenceChange = self:calculateCoherence(priorGraph, 1.0, 1.0)
			- priorGraph:calculateCoherence(priorGraph, 1.0, 1.0),
	}
end

function BeliefGraph:clone()
	local cloned = BeliefGraph.new(table.clone(self.nodes), table.clone(self.connections))
	cloned.probabilities = table.clone(self.probabilities)
	cloned.centralities = table.clone(self.centralities)
	return cloned
end

-- Spectral analysis for large graphs (simplified)
function BeliefGraph:getSpectralEmbedding(dimensions)
	dimensions = dimensions or math.min(5, #self.nodes)

	-- This would implement proper Laplacian eigendecomposition
	-- For now, return simplified embedding based on centralities
	local embedding = {}

	for _, node in ipairs(self.nodes) do
		embedding[node] = {}
		for i = 1, dimensions do
			-- Simplified: use scaled centrality metrics as "eigenvector" components
			local centrality = self.centralities[node]
			if centrality then
				local value = (centrality.degree or 0) * math.sin(i) + (centrality.pagerank or 0) * math.cos(i)
				embedding[node][i] = value
			else
				embedding[node][i] = 0
			end
		end
	end

	return embedding
end

return BeliefGraph
