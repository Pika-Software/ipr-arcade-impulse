install( "packages/ipr-base", "https://github.com/Pika-Software/ipr-base" )

local util_TraceLine = util.TraceLine
local math_max = math.max
local IsValid = IsValid
local hook = hook

local ipr_velocity = CreateConVar( "ipr_velocity", "200", FCVAR_ARCHIVE, "Determines the maximum allowable player's body impact from damage.", 1, 100000 )
local packageName = gpm.Package:GetIdentifier()

hook.Add( "PlayerRagdollCreated", packageName, function( ply, ragdoll )
    if not ragdoll:IsRagdoll() then return end

    local data = ply[ packageName ]
    if not data then return end
    ply[ packageName ] = nil

    local physID = ragdoll:TranslateBoneToPhysBone( data.BoneID )
    if physID < 0 then return end

    local phys = ragdoll:GetPhysicsObjectNum( physID )
    if not IsValid( phys ) then return end

    local impulse = data.Impulse
    local frac = impulse:Length() / ipr_velocity:GetFloat()
    if frac > 1 then
        impulse = impulse / math_max( 1, frac - 1 )
    end

    phys:ApplyForceOffset( impulse, data.Origin )
end )

hook.Add( "DoPlayerDeath", packageName, function( ply, _, damageInfo )
    local start, endpos = damageInfo:GetDamagePosition(), ply:LocalToWorld( ply:OBBCenter() )
    endpos[3] = start[3]

    local tr = util_TraceLine( {
        ["start"] = start,
        ["endpos"] = endpos,
        ["filter"] = function( ent )
            return ent == ply
        end
    } )

    local boneID = ply:GetHitBoxBone( tr.HitBox, ply:GetHitboxSet() )
    if not boneID or boneID < 0 then boneID = ply:TranslatePhysBoneToBone( tr.PhysicsBone ) end
    if not boneID or boneID < 0 then return end

    ply[ packageName ] = {
        ["BoneID"] = boneID,
        ["Origin"] = tr.HitPos,
        ["Impulse"] = damageInfo:GetDamageForce()
    }
end )