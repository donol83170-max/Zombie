-- SCRIPT V2 : Placer le flash au BOUT DU CANON
-- Colle ce script dans la barre de commande de Studio et appuie sur Entrée

local weaponFolder = game.ReplicatedStorage:FindFirstChild("Weapons")
local pistol = weaponFolder and weaponFolder:FindFirstChild("Pistol")
if not pistol then warn("Pistol introuvable !") return end

-- Trouver la pièce principale du pistolet (Handle)
local handle = pistol:FindFirstChild("Handle") or pistol.PrimaryPart or pistol:FindFirstChildOfClass("BasePart")
if not handle then warn("Handle introuvable !") return end

-- Supprimer l'ancien attachement s'il existe
for _, child in ipairs(handle:GetChildren()) do
	if child:IsA("Attachment") then
		-- Déplacer les emitters hors de l'attachment d'abord
		for _, eff in ipairs(child:GetChildren()) do
			eff.Parent = handle
		end
		child:Destroy()
	end
end

-- Créer un nouvel attachement au bout du canon
-- Le pistolet est tourné de 180° en Y, donc le bout du canon est au -Z (avant du modèle d'origine)
local att = Instance.new("Attachment")
att.Name = "MuzzleFlash"
att.Position = Vector3.new(0, 0, -handle.Size.Z / 2) -- Bout du canon côté -Z
att.Parent = handle

-- Mettre TOUS les emitters dans cet attachement
local movedCount = 0
for _, child in ipairs(handle:GetChildren()) do
	if child:IsA("ParticleEmitter") or child:IsA("SpotLight") or child:IsA("PointLight") then
		child.Parent = att
		movedCount += 1
	end
end

print("✅ Flash repositionné au bout du canon ! " .. movedCount .. " effets déplacés.")
print("💡 Si le flash est du mauvais côté, remplace '-handle.Size.Z / 2' par '+handle.Size.Z / 2' dans le script.")
