-- SCRIPT DE SECOURS POUR LE FLASH (À copier dans la barre de commande de Roblox Studio)

local weaponFolder = game.ReplicatedStorage:FindFirstChild("Weapons")
if not weaponFolder then warn("Dossier Weapons introuvable !") return end

local pistol = weaponFolder:FindFirstChild("Pistol")
if not pistol then warn("Modèle Pistol introuvable dans ReplicatedStorage.Weapons !") return end

local handle = pistol:FindFirstChild("Handle") or pistol:FindFirstChildOfClass("MeshPart") or pistol:FindFirstChildOfClass("Part")
if not handle then warn("Handle introuvable dans le modèle Pistol !") return end

-- Trouver ou créer l'attachement
local att = handle:FindFirstChild("Attachment") or handle:FindFirstChild("Muzzle") or handle:FindFirstChild("Flash")
if not att then
	att = Instance.new("Attachment")
	att.Name = "Attachment"
	att.Parent = handle
	print("Attachment créé !")
end

-- Centrer l'attachement au bout du canon (approximation sur l'axe Z)
att.Position = Vector3.new(0, 0.2, -handle.Size.Z/2 - 0.2)

-- S'assurer que les particules sont dedans
for _, child in ipairs(pistol:GetDescendants()) do
	if child:IsA("ParticleEmitter") or child:IsA("Light") then
		child.Parent = att
	end
end

print("✅ FLASH RÉPARÉ ! L'attachement est maintenant pile au bout du canon.")
