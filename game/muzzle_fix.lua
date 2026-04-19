-- Sélectionne le Handle dans l'explorateur Studio, puis exécute ce script dans la Command Bar
local sel = game:GetService("Selection"):Get()[1]
if not sel or not sel:IsA("BasePart") then warn("Sélectionne le Handle d'abord !") return end

local handle = sel

-- Utilise l'Attachment Muzzle existant, ou GunMuzzlePoint1, sinon en crée un
local att = handle:FindFirstChild("Muzzle") or handle:FindFirstChild("GunMuzzlePoint1")
if not att then
	att = Instance.new("Attachment")
	att.Name = "Muzzle"
	att.Position = Vector3.new(0, 0, -handle.Size.Z / 2)
	att.Parent = handle
end

-- Déplace tous les effets visuels dans cet Attachment
local movedCount = 0
for _, child in ipairs(handle:GetChildren()) do
	if child:IsA("ParticleEmitter") or child:IsA("Smoke") or child:IsA("Fire")
	or child:IsA("SpotLight") or child:IsA("PointLight") then
		child.Parent = att
		movedCount += 1
	end
end

print("✅ " .. movedCount .. " effets déplacés dans '" .. att.Name .. "'")
