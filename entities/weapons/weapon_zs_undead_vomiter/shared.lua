-- � Limetric Studios ( www.limetricstudios.com ) -- All rights reserved.
-- See LICENSE.txt for license information

--BIG WORK IN PROGRESS

AddCSLuaFile()

SWEP.Base = "weapon_zs_undead_base"

SWEP.PrintName = "Vomit Zombie"
if CLIENT then
	SWEP.ViewModelFOV = 52
	SWEP.ViewModelFlip = false
end

SWEP.ViewModel = Model("models/weapons/v_pza.mdl")
SWEP.WorldModel = Model("models/weapons/w_knife_t.mdl")

SWEP.Primary.Delay = 0.8
SWEP.Primary.Reach = 65
SWEP.Primary.Duration = 2
SWEP.Primary.Damage = 55

SWEP.Secondary.Duration = 4
SWEP.Secondary.Delay = 0.5
SWEP.Secondary.Damage = math.random(30,40)

SWEP.SwapAnims = false

function SWEP:Initialize()
	self.BaseClass.Initialize(self)

	if CLIENT then
		self.BreathSound = CreateSound(self.Weapon,Sound("npc/zombie_poison/pz_breathe_loop1.wav"));
		if self.BreathSound then
			self.BreathSound:Play()
		end
	end
end

function SWEP:StartPrimaryAttack()			
	
end

function SWEP:PostPerformPrimaryAttack(hit)
	if CLIENT then
		return
	end

	if hit then
		self.Owner:EmitSound(Sound("npc/zombiegreen/hit_punch_0".. math.random(1, 8) ..".wav"))
	else
		self.Owner:EmitSound(Sound("npc/zombiegreen/claw_miss_"..math.random(1, 2)..".wav"))
	end
end

function SWEP:StartSecondaryAttack()
	local pl = self.Owner
	
	if pl:GetAngles().pitch > 55 or pl:GetAngles().pitch < -55 then
		pl:EmitSound(Sound("npc/zombie_poison/pz_idle"..math.random(2,4)..".wav"))
		return
	end
	
	self.Owner:SetAnimation( PLAYER_ATTACK1 )
			
	if SERVER then
		pl:EmitSound(Sound("npc/zombie_poison/pz_throw".. math.random(2,3) ..".wav"))
	end
end


function SWEP:PerformSecondaryAttack()
	local pl = self.Owner

	-- GAMEMODE:SetPlayerSpeed ( pl, ZombieClasses[ pl:GetZombieClass() ].Speed ) 
	if pl:GetAngles().pitch > 55 or pl:GetAngles().pitch < -55 then 
		if SERVER then
			pl:EmitSound(Sound("npc/zombie_poison/pz_idle".. math.random(2,4) ..".wav"))
		end

		return 
	end
		
	--Swap Anims
	if self.SwapAnims then
		self:SendWeaponAnim(ACT_VM_HITCENTER)
	else
		self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
	end
	self.SwapAnims = not self.SwapAnims
		
	if CLIENT then
		return
	end

	local shootpos = pl:GetShootPos()
	local startpos = pl:GetPos()
	startpos.z = shootpos.z
	local aimvec = pl:GetAimVector()
	aimvec.z = math.max(aimvec.z, -0.7)
	
	for i=1, 8 do
		local ent = ents.Create("projectile_poisonpuke")
		if ent:IsValid() then
			local heading = (aimvec + VectorRand() * 0.2):GetNormal()
			ent:SetPos(startpos + heading * 8)
			ent:SetOwner(pl)
			ent:Spawn()
			ent.TeamID = pl:Team()
			local phys = ent:GetPhysicsObject()
			if phys:IsValid() then
				phys:SetVelocityInstantaneous(heading * math.Rand(300, 550))
			end
			ent:SetPhysicsAttacker(pl)
		end
	end

	pl:EmitSound(Sound("physics/body/body_medium_break"..math.random(2,4)..".wav"), 80, math.random(70, 80))

	pl:TakeDamage(self.Secondary.Damage, pl, self.Weapon)
end

function SWEP:Move(mv)
	if self:IsInPrimaryAttack() then
		mv:SetMaxSpeed(self.Owner:GetMaxSpeed()*0.8)
		return true
	elseif self:IsInSecondaryAttack() then
		mv:SetMaxSpeed(0)
		return true
	end
end

function SWEP:OnRemove()
	self.BaseClass.OnRemove(self)

	if CLIENT and self.BreathSound then
		self.BreathSound:Stop()
	end

	return true
end

function SWEP:Precache()
	util.PrecacheSound("npc/zombie_poison/pz_throw2.wav")
	util.PrecacheSound("npc/zombie_poison/pz_throw3.wav")
	util.PrecacheSound("npc/zombie_poison/pz_warn1.wav")
	util.PrecacheSound("npc/zombie_poison/pz_warn2.wav")
	util.PrecacheSound("npc/zombie_poison/pz_idle2.wav")
	util.PrecacheSound("npc/zombie_poison/pz_idle3.wav")
	util.PrecacheSound("npc/zombie_poison/pz_idle4.wav")
	util.PrecacheSound("npc/zombie/claw_strike1.wav")
	util.PrecacheSound("npc/zombie/claw_strike2.wav")
	util.PrecacheSound("npc/zombie/claw_strike3.wav")
	util.PrecacheSound("npc/zombie/claw_miss1.wav")
	util.PrecacheSound("npc/zombie/claw_miss2.wav")
	util.PrecacheSound("npc/headcrab_poison/ph_jump1.wav")
	util.PrecacheSound("npc/headcrab_poison/ph_jump2.wav")
	util.PrecacheSound("npc/headcrab_poison/ph_jump3.wav")
	util.PrecacheSound("npc/zombie_poison/pz_breathe_loop1.wav")
	
	-- Quick way to precache all sounds
	for _, snd in pairs(ZombieClasses[3].PainSounds) do
		util.PrecacheSound(snd)
	end
	
	for _, snd in pairs(ZombieClasses[3].IdleSounds) do
		util.PrecacheSound(snd)
	end
	
	for _, snd in pairs(ZombieClasses[3].DeathSounds) do
		util.PrecacheSound(snd)
	end
end