local normalfov_convar = CreateClientConVar("fovtweaks_normalfov", "90", true, false, "")
local damageenabled_convar = CreateClientConVar("fovtweaks_damagefov_enable", "1", true, false, "")
local sprintenabled_convar = CreateClientConVar("fovtweaks_sprintfov_enable", "1", true, false, "")
local sprintfov_convar = CreateClientConVar("fovtweaks_sprintfov", "105", true, false, "")
local minimpactfov = 60
local impactduration = 0.05
local fovreturnspeed = 3

local currentfov = normalfov_convar:GetFloat()
local lasthealth = 0
local impacttime = 0

hook.Add("CalcView", "fovtweaks_combinedfov", function(ply, pos, angles, fov)
    if not IsValid(ply) then return end

    local health = ply:Health()
    local maxhealth = ply:GetMaxHealth()
    local normalfov = normalfov_convar:GetFloat()
    local sprintfov = sprintfov_convar:GetFloat()
    local targetfov = normalfov

    function FovTweaks_ResetFOV()
        currentfov = normalfov_convar:GetFloat()
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
            local impactfov = normalfov - (normalfov - minimpactfov) * damagefrac
            currentfov = impactfov
            impacttime = CurTime() + impactduration
        end
        lasthealth = health

        if CurTime() < impacttime then
            targetfov = currentfov
        end
    end

    -- Smoothly interpolate FOV based on velocity
    if sprintenabled_convar:GetBool() and CurTime() > impacttime then
        local vel = ply:GetVelocity():Length2D()
        local minVel, maxVel = 0, 400 -- You can tweak maxVel for when FOV is fully sprint
        local frac = math.Clamp((vel - minVel) / (maxVel - minVel), 0, 1)
        targetfov = Lerp(frac, normalfov, sprintfov)
    end

    currentfov = Lerp(FrameTime() * fovreturnspeed, currentfov, targetfov)
    return {
        origin = pos,
        angles = angles,
        fov = currentfov
    }
end)