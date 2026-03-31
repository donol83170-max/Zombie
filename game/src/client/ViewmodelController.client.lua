-- ViewmodelController.client.lua
-- Animation procédurale du ViewModel (bras + arme FPS)
-- Gère : bobbing marche/sprint, sway caméra, tilt latéral
-- Récupère le ViewModel et le recoil depuis InputController via _G

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ════════════════════════════════════════════════════════════════
-- CONFIGURATION — ajuste ces valeurs pour le feel voulu
-- ════════════════════════════════════════════════════════════════
local Config = {

    -- Position de base des bras devant la caméra (X=droite, Y=bas, Z=avant)
    BASE_OFFSET = CFrame.new(0, -1.8, 0.4),

    -- ── Bobbing Marche ──────────────────────────────────────────
    WALK_FREQ_X  = 4.0,    -- fréquence oscillation latérale (Hz)
    WALK_FREQ_Y  = 8.0,    -- fréquence verticale (2× = 2 pas par cycle)
    WALK_AMPL_X  = 0.055,  -- amplitude latérale (studs)
    WALK_AMPL_Y  = 0.035,  -- amplitude verticale

    -- ── Bobbing Sprint ──────────────────────────────────────────
    SPRINT_FREQ_X  = 5.5,
    SPRINT_FREQ_Y  = 11.0,
    SPRINT_AMPL_X  = 0.11,
    SPRINT_AMPL_Y  = 0.075,

    -- ── Sway (balancement souris) ────────────────────────────────
    SWAY_AMPL    = 0.0018,  -- sensibilité au delta souris
    SWAY_SMOOTH  = 7.0,     -- vitesse de retour (lerp factor)

    -- ── Tilt (inclinaison latérale en mouvement) ─────────────────
    TILT_AMPL    = 0.055,   -- radians max d'inclinaison
    TILT_SMOOTH  = 9.0,

    -- ── Seuils de vitesse ────────────────────────────────────────
    SPEED_THRESHOLD  = 1.0,
    SPRINT_THRESHOLD = 20.0,
}

-- ════════════════════════════════════════════════════════════════
-- STATE INTERNE
-- ════════════════════════════════════════════════════════════════
local bobTimer   = 0
local swayOffset = CFrame.identity
local tiltOffset = CFrame.identity

-- ════════════════════════════════════════════════════════════════
-- UTILITAIRES
-- ════════════════════════════════════════════════════════════════

-- Vitesse horizontale du HumanoidRootPart (ignore Y)
local function getHorizontalSpeed(character)
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0 end
    local v = hrp.AssemblyLinearVelocity
    return math.sqrt(v.X * v.X + v.Z * v.Z)
end

-- Lerp CFrame clampé
local function lerpCF(a, b, alpha)
    return a:Lerp(b, math.clamp(alpha, 0, 1))
end

-- ════════════════════════════════════════════════════════════════
-- BOUCLE PRINCIPALE — RenderStepped (priorité haute pour le visuel)
-- ════════════════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function(dt)

    -- ── 0. Récupérer le ViewModel depuis InputController ─────────
    -- InputController expose _G.InputController = { getViewModel, getRecoil }
    local IC = _G.InputController
    if not IC then return end

    local viewmodel = IC.getViewModel()
    if not viewmodel or not viewmodel.Parent then return end

    -- ── 1. Données de mouvement ──────────────────────────────────
    local character  = player.Character
    local speed      = getHorizontalSpeed(character)
    local isSprinting = speed > Config.SPRINT_THRESHOLD
    local isMoving    = speed > Config.SPEED_THRESHOLD

    -- Facteur 0→1 selon la vitesse (fondu progressif du bob)
    local speedFactor = math.clamp(
        (speed - Config.SPEED_THRESHOLD) / math.max(Config.SPRINT_THRESHOLD - Config.SPEED_THRESHOLD, 1),
        0, 1
    )

    -- ── 2. BOBBING ───────────────────────────────────────────────
    local freqX, freqY, amplX, amplY

    if isSprinting then
        freqX, freqY = Config.SPRINT_FREQ_X, Config.SPRINT_FREQ_Y
        amplX, amplY = Config.SPRINT_AMPL_X, Config.SPRINT_AMPL_Y
    else
        freqX, freqY = Config.WALK_FREQ_X,   Config.WALK_FREQ_Y
        amplX, amplY = Config.WALK_AMPL_X,   Config.WALK_AMPL_Y
    end

    if isMoving then
        -- Avance le timer selon la vitesse pour un bob proportionnel
        bobTimer = bobTimer + dt * (speed / 16)
    else
        -- Retour fluide vers zéro quand le joueur s'arrête
        bobTimer = bobTimer * (1 - math.min(dt * 8, 1))
    end

    local bobX = math.sin(bobTimer * freqX) * amplX * speedFactor
    -- math.abs donne un rebond "deux fois par cycle" (simulation pas)
    local bobY = math.abs(math.sin(bobTimer * freqY)) * amplY * speedFactor
    local bobOffset = CFrame.new(bobX, -bobY, 0)

    -- ── 3. SWAY (delta souris → déplacement des bras) ────────────
    local mouseDelta = UserInputService:GetMouseDelta()
    local targetSway = CFrame.new(
        -mouseDelta.X * Config.SWAY_AMPL,
         mouseDelta.Y * Config.SWAY_AMPL,
        0
    )
    swayOffset = lerpCF(swayOffset, targetSway, dt * Config.SWAY_SMOOTH)

    -- ── 4. TILT (inclinaison selon vitesse latérale locale) ──────
    local lateralVel = 0
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if hrp then
        -- Projette la vélocité dans l'espace caméra pour obtenir l'axe X local
        local localVel = camera.CFrame:VectorToObjectSpace(hrp.AssemblyLinearVelocity)
        lateralVel = localVel.X
    end
    local targetTilt = CFrame.Angles(0, 0, -lateralVel * Config.TILT_AMPL * 0.05)
    tiltOffset = lerpCF(tiltOffset, targetTilt, dt * Config.TILT_SMOOTH)

    -- ── 5. RECOIL (géré par InputController, récupéré via _G) ────
    local recoilOffset = IC.getRecoil()

    -- ── 6. COMPOSITION FINALE ────────────────────────────────────
    -- Ordre intentionnel : base → sway → tilt → bob → recoil
    -- Le recoil est au plus proche de la caméra pour rester dominant
    local finalCFrame = camera.CFrame
        * Config.BASE_OFFSET
        * swayOffset
        * tiltOffset
        * bobOffset
        * recoilOffset

    viewmodel:PivotTo(finalCFrame)

    -- Custom viewmodel : appliquer les transforms Motor6D pour les animations
    local isCustom = IC.isCustomVM and IC.isCustomVM() or false
    if isCustom then
        for _, motor in ipairs(viewmodel:GetDescendants()) do
            if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 then
                motor.Part1.CFrame = motor.Part0.CFrame * motor.C0 * motor.Transform * motor.C1:Inverse()
            end
        end
    end
end)

print("[ViewmodelController] Initialisé !")
