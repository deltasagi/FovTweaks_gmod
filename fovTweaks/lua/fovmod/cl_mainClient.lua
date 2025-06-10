local damageenabled_convar = CreateClientConVar("fovtweaks_damagefov_enable", "1", true, false, "")
local sprintenabled_convar = CreateClientConVar("fovtweaks_sprintfov_enable", "1", true, false, "")
local sprintfov_convar = CreateClientConVar("fovtweaks_sprintfov", "15", true, false, "") -- now an offset, not an absolute value
local minimpactfov_offset = -30 -- how much to reduce FOV on max damage
local impactduration = 0.05
local fovreturnspeed = 3

local currentfov_offset = 0
local lasthealth = 0
local impacttime = 0

hook.Add("CalcView", "fovtweaks_combinedfov", function(ply, pos, angles, fov)
    if not IsValid(ply) then return end

    local health = ply:Health()
    local maxhealth = ply:GetMaxHealth()
    local sprintfov_offset = sprintfov_convar:GetFloat()
    local targetfov_offset = 0

    local function FovTweaks_ResetFOV()
        currentfov_offset = 0
        lasthealth = 0
        impacttime = 0
    end

    if ply:IsPlayer() and ply:InVehicle() then FovTweaks_ResetFOV() return end
    if not ply:Alive() then FovTweaks_ResetFOV() return end
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and wep:GetClass() == "gmod_camera" then
        FovTweaks_ResetFOV()
        return
    end

    if damageenabled_convar:GetBool() then
        if health < lasthealth then
            local damage = lasthealth - health
            local damagefrac = math.Clamp(damage / maxhealth, 0, 1)
            local impactfov_offset = minimpactfov_offset * damagefrac
            currentfov_offset = impactfov_offset
            impacttime = CurTime() + impactduration
        end
        lasthealth = health

        if CurTime() < impacttime then
            targetfov_offset = currentfov_offset
        end
    end

    if sprintenabled_convar:GetBool() and CurTime() > impacttime then
        local vel = ply:GetVelocity():Length2D()
        local minVel, maxVel = 0, 400
        local frac = math.Clamp((vel - minVel) / (maxVel - minVel), 0, 1)
        targetfov_offset = Lerp(frac, 0, sprintfov_offset)
    end

    currentfov_offset = Lerp(FrameTime() * fovreturnspeed, currentfov_offset, targetfov_offset)
    return {
        origin = pos,
        angles = angles,
        fov = fov + currentfov_offset
    }
end)
--hopefully this adds more compatibility :)