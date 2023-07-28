local mvec3_lerp = mvector3.lerp
local mvec3_sub = mvector3.subtract
local mvec3_norm = mvector3.normalize

function enemy_throws_grenade(thrower_unit,throw_from,direction)
    local enemy_throwable = "poison_gas_grenade"  -- poison_gas_grenade molotov wpn_gre_electric(crash)
	if math.random() >=0.7 then enemy_throwable = "molotov" end --70% gas
	local throw_dir = Vector3()

	if not thrower_unit:brain()._logic_data.attention_obj then return end--anti crash code
	local player_pos = thrower_unit:brain()._logic_data.attention_obj.m_pos

	if player_pos.z > throw_from.z then --throw_from is enemy head pos,and playerpos is feet pos.If player feet pos higher then enemy's head pos,let the enemy aim a bit higher.
		if enemy_throwable == "molotov" then
			local temp1 = (player_pos.z-throw_from.z)/4.66--dont ask me how i get those magic number,by funny testing.
			mvector3.set_z(player_pos,player_pos.z+temp)
		elseif enemy_throwable == "poison_gas_grenade" then
			local temp2 = (player_pos.z-throw_from.z)/3.6
			mvector3.set_z(player_pos,player_pos.z+temp)
		end
	elseif math.random() > 0.5 then --randomly throw a bit further then we need.Ideally should fall behind the player.
		mvector3.set_z(player_pos,player_pos.z+math.random()*50+10)
	if	
	end
	--//**\\--
	mvec3_lerp(throw_dir, throw_from, player_pos, 0.3)
	mvec3_sub(throw_dir, throw_from)
	local throw_dis = thrower_unit:brain()._logic_data.attention_obj.verified_dis
	local dis_lerp = math.clamp((throw_dis - 1000) / 1000, 0, 1)
	local compensation = math.lerp(0, 300, dis_lerp)
	mvector3.set_z(throw_dir, throw_dir.z + compensation)
	mvec3_norm(throw_dir)
	--those are vanilla logic,but its good enough.

    ProjectileBase.throw_projectile_npc(enemy_throwable, throw_from, throw_dir, thrower_unit)
end

local mvec_to = Vector3()
local mvec_spread = Vector3()

function NPCRaycastWeaponBase:_fire_raycast(user_unit, from_pos, direction, dmg_mul, shoot_player, spread_mul, autohit_mul, suppr_mul, target_unit)
	local result = {}
	local hit_unit = nil
	local miss, extra_spread = self:_check_smoke_shot(user_unit, target_unit)

	if miss then
		result.guaranteed_miss = miss

		mvector3.spread(direction, math.rand(unpack(extra_spread)))
	end

	mvector3.set(mvec_to, direction)
	mvector3.multiply(mvec_to, 20000)
	mvector3.add(mvec_to, from_pos)

	local damage = self._damage * (dmg_mul or 1)
	local bullet_slotmask = self._bullet_slotmask
	local col_ray = World:raycast("ray", from_pos, mvec_to, "slot_mask", bullet_slotmask, "ignore_unit", self._setup.ignore_units)
	local player_hit, player_ray_data = nil

	if shoot_player and self._hit_player then
		player_hit, player_ray_data = self:damage_player(col_ray, from_pos, direction, result)

		if player_hit then
			self._unit:base():bullet_class():on_hit_player(col_ray or player_ray_data, self._unit, user_unit, damage)
            enemy_throws_grenade(user_unit,from_pos,mvec_to)
		end
	end

	local char_hit = nil

	if not player_hit and col_ray then
		char_hit = self._unit:base():bullet_class():on_collision(col_ray, self._unit, user_unit, damage)
	end

	if (not col_ray or col_ray.unit ~= target_unit) and target_unit and target_unit:character_damage() and target_unit:character_damage().build_suppression then
		target_unit:character_damage():build_suppression(tweak_data.weapon[self._name_id].suppression)
	end

	if not col_ray or col_ray.distance > 600 or result.guaranteed_miss then
		local num_rays = (tweak_data.weapon[self._name_id] or {}).rays or 1

		for i = 1, num_rays do
			mvector3.set(mvec_spread, direction)

			if i > 1 then
				mvector3.spread(mvec_spread, self:_get_spread(user_unit))
			end

			self:_spawn_trail_effect(mvec_spread, col_ray)
		end
	end

	result.hit_enemy = char_hit

	if self._alert_events then
		result.rays = {
			col_ray
		}
	end

	self:_cleanup_smoke_shot()

	return result
end
