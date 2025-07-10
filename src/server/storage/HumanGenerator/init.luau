local InsertService = game:GetService("InsertService")

local MaleAssets = require(script.MaleAssetLibrary)
local FemaleAssets = require(script.FemaleAssetLibrary)
local MaleBase = 73485958460058 -- THESE MODELS ARE STANDARD, BLOCKY MALE/FEMALE VARIANT R15 ASSETS I UPLOADED
local FemaleBase = 87409383453644

local HumanGenerator = {}

type Gender = "Male" | "Female"

function getRandomFrom(list)
	return list[math.random(1, #list)]
end

local function applyAssetsToModel(model: Model, gender: Gender)
	local assetSet = (gender == "Male") and MaleAssets or FemaleAssets
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	
	if not humanoid then
		warn(`No humanoid found in model {model.Name}`)
		return
	end

	-- Remove any existing clothing/accessories
	for _, item in ipairs(model:GetChildren()) do
		if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("Accessory") then
			item:Destroy()
		end
	end

	-- Apply Shirt
	local shirtId = getRandomFrom(assetSet.Shirts)
	if shirtId then
		local shirt = Instance.new("Shirt")
		shirt.ShirtTemplate = `rbxassetid://{shirtId}`
		shirt.Parent = model
		print(`Applied shirt: {shirtId} to {model.Name}`)
	end

	-- Apply Pants
	local pantsId = getRandomFrom(assetSet.Pants)
	if pantsId then
		local pants = Instance.new("Pants")
		pants.PantsTemplate = `rbxassetid://{pantsId}`
		pants.Parent = model
		print(`Applied pants: {pantsId} to {model.Name}`)
	end

	-- Apply Hair Accessory (simplified - no caching to avoid conflicts)
	local hairId = getRandomFrom(assetSet.Hair)
	if hairId then
		local success, result = pcall(function()
			return InsertService:LoadAsset(hairId)
		end)
		
		if success and result then
			local accessory = result:FindFirstChildOfClass("Accessory")
			if accessory then
				-- IMPORTANT: Remove from container first, but don't parent to model
				accessory.Parent = nil
				
				-- Let AddAccessory handle the parenting
				local addSuccess, addErr = pcall(function()
					humanoid:AddAccessory(accessory)
				end)
				
				if addSuccess then
					print(`Applied hair accessory: {hairId} to {model.Name}`)
				else
					warn(`Failed to add accessory {hairId}: {addErr}`)
					accessory:Destroy()
				end
			else
				warn(`Asset {hairId} is not a valid accessory`)
			end
			-- Clean up the container
			result:Destroy()
		else
			warn(`Failed to load hair accessory: {hairId}`)
		end
	end
end

local function generateRandomName(gender: Gender): string
	local maleFirstNames = {
		"James", "Daniel", "Michael", "Ethan", "Liam", "Noah", "Henry", "Lucas"
	}
	local femaleFirstNames = {
		"Emily", "Sarah", "Jessica", "Sophia", "Emma", "Olivia", "Chloe", "Ava"
	}
	local lastNames = {
		"Johnson", "Smith", "Taylor", "Brown", "Anderson", "Miller", "Davis", "Wilson"
	}

	local first = (gender == "Male") and getRandomFrom(maleFirstNames) or getRandomFrom(femaleFirstNames)
	local last = getRandomFrom(lastNames)

	return first .. " " .. last
end

function HumanGenerator.Generate(gender: Gender?): Model
	local chosenGender = gender or (math.random() > 0.5 and "Male" or "Female")
	local assetId = (chosenGender == "Male") and MaleBase or FemaleBase

	local success, baseContainer = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)

	if not success or not baseContainer then
		error(`Failed to load base model for gender: {chosenGender}`)
	end

	local baseModel = baseContainer:FindFirstChildWhichIsA("Model")
	if not baseModel then
		error("Loaded asset does not contain a valid Model")
	end

	local modelClone = baseModel:Clone()
	modelClone.Name = chosenGender .. "Juror"

	-- TEMPORARILY parent it to something in the DataModel so ApplyDescription works
	modelClone.Parent = workspace -- or ServerStorage, ReplicatedStorage, whatever you want

	applyAssetsToModel(modelClone, chosenGender)
	modelClone.Name = generateRandomName(chosenGender)
	baseContainer:Destroy()

	return modelClone
end

return HumanGenerator
