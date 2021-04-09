/*

Created Date: Apr 03 2021

Modern Warfare Dev Team
 - Luna the Reborn

*/

#define ROCKET_GROUPINFO	(1<<10)

stock OrpheuFunction:g_pfn_ApplyMultiDamage;
stock _s_lp_tr = 0;

stock LibProjectile_Init()
{
	g_pfn_ApplyMultiDamage = OrpheuGetFunction("ApplyMultiDamage");
	_s_lp_tr = create_tr2();
}

stock LibProjectile_CreateProjectile(iOwner, const Float:vecOrigin[3], const Float:vecVelocity[3], const szModel[], const szClassName[])
{
	static str_info_target;
	if (!str_info_target)
		str_info_target = engfunc(EngFunc_AllocString, "info_target");

	new iEntity = engfunc(EngFunc_CreateNamedEntity, str_info_target);

	if (pev_valid(iEntity) != 2)
		return -1;

	set_pev(iEntity, pev_classname, szClassName);
	set_pev(iEntity, pev_owner, iOwner);
	set_pev(iEntity, pev_solid, SOLID_BBOX);
	set_pev(iEntity, pev_movetype, MOVETYPE_FLY);
	set_pev(iEntity, pev_gravity, 1.0);

	static Float:vecAngles[3];
	vector_to_angle(vecVelocity, vecAngles);
	set_pev(iEntity, pev_angles, vecAngles);

	static Float:vecVAngle[3];
	xs_vec_set(vecVAngle, -vecAngles[0], vecAngles[1], vecAngles[2]);
	set_pev(iEntity, pev_v_angle, vecVAngle);

	engfunc(EngFunc_SetSize, iEntity, Float:{-2.0, -2.0, -2.0}, Float:{2.0, 2.0, 2.0});
	engfunc(EngFunc_SetModel, iEntity, szModel);
	engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);

	set_pev(iEntity, pev_velocity, vecVelocity);
	set_pev(iEntity, pev_groupinfo, ROCKET_GROUPINFO);

	return iEntity;
}

stock Float:_s_vecVelocity[3], Float:_s_vecAngles[3], Float:_s_vecVAngle[3], Float:_s_vecOrigin[3];

stock LibProjectile_StandardThink(iEntity)
{
	pev(iEntity, pev_origin, _s_vecOrigin);
	pev(iEntity, pev_velocity, _s_vecVelocity);
	vector_to_angle(_s_vecVelocity, _s_vecAngles);
	set_pev(iEntity, pev_angles, _s_vecAngles);

	xs_vec_set(_s_vecVAngle, -_s_vecAngles[0], _s_vecAngles[1], _s_vecAngles[2]);
	set_pev(iEntity, pev_v_angle, _s_vecVAngle);
}

stock LibProjectile_RndFlyingDir(iEntity, Float:flOffsetInDegree, Float:flSpeed)
{
	pev(iEntity, pev_origin, _s_vecOrigin);
	pev(iEntity, pev_v_angle, _s_vecVAngle);

	_s_vecVAngle[0] += random_float(-flOffsetInDegree, flOffsetInDegree);
	_s_vecVAngle[1] += random_float(-flOffsetInDegree, flOffsetInDegree);
	_s_vecVAngle[2] += random_float(-flOffsetInDegree, flOffsetInDegree);
	set_pev(iEntity, pev_v_angle, _s_vecVAngle);

	angle_vector(_s_vecVAngle, ANGLEVECTOR_FORWARD, _s_vecVelocity);
	xs_vec_mul_scalar(_s_vecVelocity, flSpeed, _s_vecVelocity);
	set_pev(iEntity, pev_velocity, _s_vecVelocity);

	xs_vec_set(_s_vecAngles, -_s_vecVAngle[0], _s_vecVAngle[1], _s_vecVAngle[2]);
	set_pev(iEntity, pev_angles, _s_vecAngles);
}

stock LibProjectile_AddContrail(iEntity, iContrailModelIndex, Float:flSpeed)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(iEntity);
	write_short(iContrailModelIndex);
	write_byte(floatround(flSpeed / 100.0));	// life
	write_byte(3);	// width
	write_byte(255);
	write_byte(255);
	write_byte(255);
	write_byte(255);
	message_end();
}

stock LibProjectile_AddFlare(iEntity)
{
	set_pev(iEntity, pev_effects, pev(iEntity, pev_effects) | EF_LIGHT | EF_BRIGHTLIGHT);
}

stock LibProjectile_RocketLaunchVFX(const Float:vecRocketOrigin[3], const Float:vecLaunchCentre[3], const Float:vecLaunchVAngle[3], iFlameSprite, iSmokeSprite)
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecRocketOrigin, 0);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, vecRocketOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecRocketOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecRocketOrigin[2]);
	write_short(iFlameSprite);
	write_byte(5);
	write_byte(255);
	message_end();

	static Float:vecVFXOrigin[5][3], Float:vecVFXOrigin2[5][3];

	get_spherical_coord(vecLaunchCentre, 20.0, 30.0, 5.0, vecVFXOrigin[0]);
	get_spherical_coord(vecLaunchCentre, 20.0, -20.0, -5.0, vecVFXOrigin[1]);
	get_spherical_coord(vecLaunchCentre, -14.0, 30.0, 7.0, vecVFXOrigin[2]);
	get_spherical_coord(vecLaunchCentre, 25.0, 10.0, -8.0, vecVFXOrigin[3]);
	get_spherical_coord(vecLaunchCentre, -17.0, 17.0, 0.0, vecVFXOrigin[4]);

	get_aim_origin_vector2(vecLaunchCentre, vecLaunchVAngle, -80.0, 4.0, 1.0, _s_vecOrigin);

	get_spherical_coord(_s_vecOrigin, 30.0, 40.0, 2.0, vecVFXOrigin2[0])
	get_spherical_coord(_s_vecOrigin, 30.0, -30.0, -3.0, vecVFXOrigin2[1])
	get_spherical_coord(_s_vecOrigin, -24.0, 40.0, 4.0, vecVFXOrigin2[2])
	get_spherical_coord(_s_vecOrigin, 35.0, 20.0, -4.0, vecVFXOrigin2[3])
	get_spherical_coord(_s_vecOrigin, -27.0, 27.0, 0.0, vecVFXOrigin2[4])

	for(new i = 0; i < 5; i++)
	{
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecVFXOrigin[i], 0);
		write_byte(TE_SPRITE);
		engfunc(EngFunc_WriteCoord, vecVFXOrigin[i][0]);
		engfunc(EngFunc_WriteCoord, vecVFXOrigin[i][1]);
		engfunc(EngFunc_WriteCoord, vecVFXOrigin[i][2]);
		write_short(iSmokeSprite);
		write_byte(10);	// size
		write_byte(50);	// brightness
		message_end();

		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecVFXOrigin2[i], 0);
		write_byte(TE_SPRITE);
		engfunc(EngFunc_WriteCoord, vecVFXOrigin2[i][0]);
		engfunc(EngFunc_WriteCoord, vecVFXOrigin2[i][1]);
		engfunc(EngFunc_WriteCoord, vecVFXOrigin2[i][2]);
		write_short(iSmokeSprite);
		write_byte(random_num(10, 15));		// size
		write_byte(random_num(50, 100));	// brightness
		message_end();
	}
}

stock LibProjectile_RocketFlyingVFX(const Float:vecOrigin[3], iFlameSprite, iSmokeSprite)
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(iFlameSprite);
	write_byte(3);
	write_byte(255);
	message_end();

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(iSmokeSprite);
	write_byte(random_num(1, 10));
	write_byte(random_num(50, 255));
	message_end();
}

stock LibProjectile_DirectHit(iEntity, Float:flDamage, bitsDamageTypes = DMG_CLUB)
{
	pev(iEntity, pev_origin, _s_vecOrigin);
	get_aim_origin_vector(iEntity, 10.0, 0.0, 0.0, _s_vecVelocity);

	engfunc(EngFunc_TraceLine, _s_vecOrigin, _s_vecVelocity, DONT_IGNORE_MONSTERS, iEntity, _s_lp_tr);

	new iVictim = get_tr2(_s_lp_tr, TR_pHit);
	if (pev_valid(iVictim) != 2)
		return;

	new Float:flTakeDamage;
	pev(iVictim, pev_takedamage, flTakeDamage);
	if (flTakeDamage == DAMAGE_NO)
		return;

	new iAttacker = pev(iEntity, pev_owner);
	ExecuteHamB(Ham_TraceAttack, iVictim, iAttacker, flDamage, _s_vForward, _s_lp_tr, bitsDamageTypes);
	OrpheuCallSuper(g_pfn_ApplyMultiDamage, iEntity, iAttacker);
}

stock LibProjectile_GetTR()
{
	return _s_lp_tr;
}

stock UTIL_SoftRemoval(iEntity)
{
	set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME);
}