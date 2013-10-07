-- � Limetric Studios ( www.limetricstudios.com ) -- All rights reserved.
-- See LICENSE.txt for license information

local math = math
local team = team
local util = util
local timer = timer

if SERVER then
	AddCSLuaFile("shared.lua")
	SWEP.Weight				= 5
	SWEP.AutoSwitchTo		= true
	SWEP.AutoSwitchFrom		= true
	SWEP.PrintName = "weapon"
end

if CLIENT then
	SWEP.PrintName = "Generic Undead"
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = false
	SWEP.ViewModelFOV = 70
	SWEP.ViewModelFlip = false
	SWEP.CSMuzzleFlashes = false
	SWEP.ShowViewModel = true
	SWEP.ShowWorldModel = false

	SWEP.ViewModelBoneMods = {
		["ValveBiped.Bip01_R_Forearm"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -18.619, -9.325) },
		["ValveBiped.Bip01_R_UpperArm"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(5.551, 6.58, -33.668) },
		["ValveBiped.Bip01_L_UpperArm"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-5.663, 4.375, 33.555) },
		["ValveBiped.Bip01_L_Forearm"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -16.632, 0) }
	}

	
end
SWEP.Base = "weapon_zs_base_undead_dummy"
-- Remade by Deluvas
SWEP.Author = "Deluvas"
SWEP.Contact = ""
SWEP.Purpose = ""
SWEP.Instructions = ""

SWEP.ViewModel = Model ( "models/Weapons/v_zombiearms.mdl" )
SWEP.WorldModel = Model ( "models/weapons/w_knife_t.mdl" )

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 1.2

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 5
SWEP.AutoSwitchTo = true
SWEP.AutoSwitchFrom = false

SWEP.DistanceCheck = 95 -- 88
SWEP.MeleeDelay = 0.6

SWEP.SwapAnims = false
SWEP.AttackAnimations = { "attackD", "attackE", "attackF" }

SWEP.Damage = 30

function SWEP:Reload()
	return false
end

function SWEP:OnDeploy()
	if SERVER then
		self.Owner.Moaning = false
	end
	self.Owner.IsMoaning = false 
	self.Owner.ZomAnim = math.random(1, 3)
end

function SWEP:CheckMeleeAttack()
	local swingend = self:GetSwingEndTime()
	if swingend == 0 or CurTime() < swingend then
		return
	end
	self:StopSwinging(0)

	self:Swung()
end

function SWEP:Think()	
	self:CheckMeleeAttack()
end


SWEP.NextSwing = 0
function SWEP:PrimaryAttack()
	if CurTime() < self.NextSwing then
		return
	end
	
	self.Weapon:SetNextPrimaryFire ( CurTime() + self.MeleeDelay ) 
	self.Weapon:SetNextSecondaryFire ( self:GetNextPrimaryFire() + 0.5 )
	self:StartSwinging()
	
	self.NextSwing = CurTime() + self.Primary.Delay
	self.NextHit = CurTime() + 0.6	
end

function SWEP:StartSwinging()
	self.PreHit = nil
	self.Trace = nil
	-- self.Owner.IsMoaning = false
	
	if SERVER then
		self:SetMoaning(false)
		if self.MoanSound then
			self.MoanSound:Stop()
			self.MoanSound = nil
		end
	end
			
	-- Hacky way for the animations
	if self.SwapAnims then
		self.Weapon:SendWeaponAnim(ACT_VM_HITCENTER)
	else
		self.Weapon:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
	end
	self.SwapAnims = not self.SwapAnims
	
	-- Set the thirdperson animation and emit zombie attack sound
	self.Owner:DoAnimationEvent(CUSTOM_PRIMARY)

	if SERVER then
		self.Owner:EmitSound("npc/zombiegreen/rage_at_victim"..math.random(20, 37)..".wav")
	end

	if self.MeleeDelay > 0 then
		self:SetSwingEndTime(CurTime() + self.MeleeDelay)
	else
		self:Swung()
	end
end

function SWEP:Swung()	
	if CLIENT then
		return
	end
	
	self.Owner:LagCompensation(true)

	-- Calculate damage done
	local Damage = self.Damage or 30

	--Do actual traces
	local traces = self.Owner:PenetratingMeleeTrace(self.MeleeReach, self.MeleeSize, nil)
		
	local hit = false
	for _, trace in ipairs(traces) do
		if not trace.Hit then
			continue
		end

		if trace.HitWorld then
			hit = true

			self:MeleeHitWorld(trace)
		else
			local ent = trace.Entity
			if not ent or not ent:IsValid() then
				continue
			end

			--Break glass
			if ent:GetClass() == "func_breakable_surf" then
				ent:Fire( "break", "", 0 )
				hit = true
			end
			
			local phys = ent:GetPhysicsObject()
			-- Case 2: It is a valid physics object
			if phys:IsValid() and not ent:IsNPC() and phys:IsMoveable() and not ent:IsPlayer() and not ent.Nails then
				local Velocity = self.Owner:EyeAngles():Forward() * math.Clamp(Damage * 2000, 25000, 37000)
				Velocity.z = math.min(Velocity.z,1600)
						
				--Apply force to prop and make the physics attacker myself
				
				phys:ApplyForceCenter(Velocity)
				ent:SetPhysicsAttacker(self.Owner)

				hit = true
			elseif not ent:IsWeapon() then
				--Take damage
				ent:TakeDamage(Damage, self.Owner, self)

				hit = true
			end
		end
	end

	if SERVER then
		if hit then
			self.Owner:EmitSound("npc/zombiegreen/hit_punch_0".. math.random(1, 8) ..".wav")
		else
			self.Owner:EmitSound("npc/zombiegreen/claw_miss_"..math.random(1, 2)..".wav")
		end
	end

	self.Owner:LagCompensation(false)
end

function SWEP:MeleeHitWorld(trace)
end

function SWEP:SetMoaning(bl)
	self:SetDTBool(0,bl)
end

function SWEP:IsMoaning()
	return self:GetDTBool(0)
end

function SWEP:StopSwinging()
	self:SetSwingEndTime(0)
end

function SWEP:SetSwingEndTime(time)
	self:SetDTFloat(0, time)
end

function SWEP:GetSwingEndTime()
	return self:GetDTFloat(0)
end

function SWEP:IsSwinging()
	return self:GetSwingEndTime() > 0
end

-- Disables rage on player
function playerRevertRage( pl )
	if not IsValid( pl ) then 
		if CLIENT then
			pl = MySelf
		else
			return
		end
	end
	
	-- Predict duration
	local iDuration = math.Clamp( ( 1 - ( pl:Health() / pl:GetMaximumHealth() ) ) * 4, 1.8, 3.5 )

	-- Run timer
	timer.Simple( iDuration, function()
		if IsValid( pl ) then
			if pl:IsZombie() and pl:IsCommonZombie() then
				if SERVER then
					GAMEMODE:SetPlayerSpeed( pl, ZombieClasses[1].Speed )
				end
			end
				
			-- Revert color
			if not pl:IsInvisible() then
				pl:SetColor( 255,255,255,255 )
			end
				
			-- Reset status
			pl.IsInRage = false
		end
	end)
end

-- Enrage player
function playerEnrage( pl )
	if not IsValid( pl ) then 
		if CLIENT then
			pl = MySelf
		else
			return
		end
	end
	
	-- Check if not healed or protected
	if pl:HasHowlerProtection() or pl:IsZombieInAura() or pl:IsZombieInRage() then
		return
	end
	
	-- Duration of rage
	local iDuration, iPitch = math.Clamp( ( 1 - ( pl:Health() / pl:GetMaximumHealth() ) ) * 4, 1.8, 3.5 )
	iPitch = ( ( ( iDuration - 1.8 ) / 1.7 ) * 55 ) * 1.03
	
	-- Status
	pl.IsInRage = true
	if CLIENT then RageScream( iDuration ) end
	
	-- Increase speed and set color
	pl:SetColor( 255,0,0,255 )
	if SERVER then GAMEMODE:SetPlayerSpeed( pl, pl:GetMaxSpeed() * 1.25 ) end
	
	-- Play activation sound
	if SERVER then pl:EmitSound( "npc/antlion/attack_double"..math.random( 1,3 )..".wav", 100, 100 - iPitch ) end

	-- Send PP to client
	if SERVER then 
		pl:SendLua("playerEnrage()") 
	end
	
	-- Show effect
	if SERVER then
		local Effect = EffectData()
			Effect:SetEntity( pl )
		util.Effect( "rage_cloud", Effect, true, true )
	end
	
	-- Revert shit
	playerRevertRage( pl )
end

SWEP.NextYell = 0
function SWEP:SecondaryAttack()
	if CurTime() < self.NextYell then return end
	
	return

	--Moaning was located here	
end

function SWEP:_OnRemove()
	if SERVER then
		if self.MoanSound then
			self.MoanSound:Stop()
		end
	end
	self.Owner.IsMoaning = false 
return true
end

function SWEP:Reload()
	return false
end

if SERVER then
	function SWEP:OnDrop()
		if self and self:IsValid() then
			self:Remove()
		end
	end
end

if CLIENT then
	function SWEP:DrawHUD()
		GAMEMODE:DrawZombieCrosshair ( self.Owner, self.DistanceCheck )
	end
end

function SWEP:Precache()
	for i = 20, 37 do
		util.PrecacheSound("npc/zombiegreen/rage_at_victim"..i..".wav")
	end

	for i = 1, 2 do
		util.PrecacheSound("npc/zombiegreen/claw_miss_"..i..".wav")
	end
	
	for i = 1, 2 do
		util.PrecacheSound("npc/zombiegreen/hit_punch_0"..i..".wav")
	end
	
	for i = 17,38 do
		util.PrecacheSound("npc/zombiegreen/death_"..i..".wav")
	end	
end