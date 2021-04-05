/*

Created Date: Apr 02 2021

Modern Warfare Dev Team
 - Luna the Reborn

*/

#define DMG_EXPLOSION		   (1<<24)

#define FFADE_IN		0x0000		// Just here so we don't pass 0 into the function
#define FFADE_OUT		0x0001		// Fade out (not in)
#define FFADE_MODULATE	0x0002		// Modulate (don't blend)
#define FFADE_STAYOUT	0x0004		// ignores the duration, stays faded out until new ScreenFade message received

stock g_CvarFriendlyFire = 0;
stock gmsgShake = 0;
stock gmsgFade = 0;
stock g_istr_spark_shower = 0;

stock const g_szBreakModels[][] = { "models/gibs_wallbrown.mdl", "models/gibs_woodplank.mdl", "models/gibs_brickred.mdl" };
stock g_iBreakModels[sizeof g_szBreakModels];

enum _:lawsspr_e
{
	lawspr_smoke = 0,
	lawspr_smoke2,
	lawspr_smokespr,
	lawspr_smokespr2,
	lawspr_rocketexp,
	lawspr_rocketexp2,
	lawspr_smoketrail,
	lawspr_fire,
	lawspr_fire2,
	lawspr_fire3
};
stock g_iLawsSprIndex[lawsspr_e];
stock g_sModelIndexFireball2 = 0;
stock g_sModelIndexFireball3 = 0;
stock g_iScorchTextureIndex[2] = {0, 0};

stock LibExplosion_Init()
{
	if (!g_CvarFriendlyFire)
		g_CvarFriendlyFire = get_cvar_pointer("mp_friendlyfire");
	
	if (!gmsgShake)
		gmsgShake = get_user_msgid("ScreenShake");
	
	if (!gmsgFade)
		gmsgFade = get_user_msgid("ScreenFade");
}

stock LibExplosion_Precache()
{
	g_iLawsSprIndex[lawspr_smokespr] = precache_model("sprites/exsmoke.spr");
	g_iLawsSprIndex[lawspr_smokespr2] = precache_model("sprites/rockeexfire.spr");
	g_iLawsSprIndex[lawspr_rocketexp] = precache_model("sprites/rockeexplode.spr");
	g_iLawsSprIndex[lawspr_rocketexp2] = precache_model("sprites/zerogxplode-big1.spr");
	g_iLawsSprIndex[lawspr_smoketrail] = precache_model("sprites/tdm_smoke.spr");
	g_iLawsSprIndex[lawspr_fire] = precache_model("sprites/rockefire.spr");
	g_iLawsSprIndex[lawspr_fire2] = precache_model("sprites/hotglow.spr");
	g_iLawsSprIndex[lawspr_fire3] = precache_model("sprites/flame.spr");
	g_iLawsSprIndex[lawspr_smoke] = precache_model("sprites/gas_smoke1.spr");
	g_iLawsSprIndex[lawspr_smoke2] = precache_model("sprites/wall_puff1.spr");

	for (new i = 0; i < sizeof g_szBreakModels; i ++)
		g_iBreakModels[i] = precache_model(g_szBreakModels[i]);
	
	g_iScorchTextureIndex[0] = engfunc(EngFunc_DecalIndex, "{scorch1");
	g_iScorchTextureIndex[1] = engfunc(EngFunc_DecalIndex, "{scorch2");

	g_sModelIndexFireball2  = precache_model("sprites/eexplo.spr");
	g_sModelIndexFireball3  = precache_model("sprites/fexplo.spr");

	g_istr_spark_shower = engfunc(EngFunc_AllocString, "spark_shower");
}

stock LibExplosion_ResetResources()
{
	g_iLawsSprIndex[lawspr_smokespr] = engfunc(EngFunc_ModelIndex, "sprites/exsmoke.spr");
	g_iLawsSprIndex[lawspr_smokespr2] = engfunc(EngFunc_ModelIndex, "sprites/rockeexfire.spr");
	g_iLawsSprIndex[lawspr_rocketexp] = engfunc(EngFunc_ModelIndex, "sprites/rockeexplode.spr");
	g_iLawsSprIndex[lawspr_rocketexp2] = engfunc(EngFunc_ModelIndex, "sprites/zerogxplode-big1.spr");
	g_iLawsSprIndex[lawspr_smoketrail] = engfunc(EngFunc_ModelIndex, "sprites/tdm_smoke.spr");
	g_iLawsSprIndex[lawspr_fire] = engfunc(EngFunc_ModelIndex, "sprites/rockefire.spr");
	g_iLawsSprIndex[lawspr_fire2] = engfunc(EngFunc_ModelIndex, "sprites/hotglow.spr");
	g_iLawsSprIndex[lawspr_fire3] = engfunc(EngFunc_ModelIndex, "sprites/flame.spr");
	g_iLawsSprIndex[lawspr_smoke] = engfunc(EngFunc_ModelIndex, "sprites/gas_smoke1.spr");
	g_iLawsSprIndex[lawspr_smoke2] = engfunc(EngFunc_ModelIndex, "sprites/wall_puff1.spr");

	for (new i = 0; i < sizeof g_szBreakModels; i ++)
		g_iBreakModels[i] = engfunc(EngFunc_ModelIndex, g_szBreakModels[i]);
	
	g_sModelIndexFireball2  = engfunc(EngFunc_ModelIndex, "sprites/eexplo.spr");
	g_sModelIndexFireball3  = engfunc(EngFunc_ModelIndex, "sprites/fexplo.spr");
}

stock LibExplosion_SetExploSprite(indexRaising = -1, indexOnGround = -1)
{
	if (indexRaising > 0)
		g_iLawsSprIndex[lawspr_rocketexp] = indexRaising;

	if (indexOnGround > 0)
		g_iLawsSprIndex[lawspr_rocketexp2] = indexOnGround;
}

stock LibExplosion_RadiusDamage(iAttacker, iInflictor, const Float:vecOrigin[3], Float:flRadius, Float:flDamage)
{
	new iVictim = -1, Float:flTakeDamage, Float:vecOrigin2[3], Float:flDistance, Float:flAdjustedDamage;
	new bool:bInWater = !!(engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_WATER);
	
	while ((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, flRadius)) > 0)
	{
		pev(iVictim, pev_takedamage, flTakeDamage);
		if (flTakeDamage == DAMAGE_NO)
			continue;

		// blast's don't tavel into or out of water
		if (bInWater && pev(iVictim, pev_waterlevel) == 0)
			continue;

		if (!bInWater && pev(iVictim, pev_waterlevel) == 3)
			continue;

		if (is_user_alive(iVictim) && !get_pcvar_num(g_CvarFriendlyFire) && fm_is_user_same_team(iAttacker, iVictim))
			continue;

		if (pev(iVictim, pev_solid) == SOLID_BSP)
		{
			//ExecuteHamB(Ham_Center, iVictim, vecOrigin2);	// LUNA: Causes CTD for unknown reason.

			new Float:vecAbsMin[3], Float:vecAbsMax[3];
			pev(iVictim, pev_absmax, vecAbsMax);
			pev(iVictim, pev_absmin, vecAbsMin);
			xs_vec_add(vecAbsMax, vecAbsMin, vecOrigin2);
			xs_vec_mul_scalar(vecOrigin2, 0.5, vecOrigin2);	// Use this instead of pev->origin. For SOLID_BSP's sake.
		}
		else
			pev(iVictim, pev_origin, vecOrigin2);

		flDistance = get_distance_f(vecOrigin, vecOrigin2);
		flAdjustedDamage = (flRadius - flDistance) * (flRadius - flDistance) * 1.25 / (flRadius * flRadius) * (GetAmountOfPlayerVisible(vecOrigin, iVictim) * flDamage) * 1.5;

		if (flAdjustedDamage <= 1.0)	// Avoid infamous "lay but not dead" bug.
			continue;
		
		ExecuteHamB(Ham_TakeDamage, iVictim, iInflictor, iAttacker, flAdjustedDamage, DMG_EXPLOSION);
	}
}

stock LibExplosion_PlayerFX(iAttacker, const Float:vecOrigin[3], Float:flRadius, Float:flShakeDur, Float:flShakeFreq, Float:flShakeAmp, Float:flFadeDur, Float:flFadeHold, Float:flPunchMax, Float:flKnockForce)
{
	new iVictim = -1, Float:vecOrigin2[3], Float:flDistance, Float:vecPunchAngle[3], Float:vecVelocity[3], Float:flSpeed, Float:flTakeDamage, Float:flFraction;
	while ((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, flRadius)) > 0)
	{
		if (iVictim < 1 || iVictim > global_get(glb_maxClients) || !is_user_alive(iVictim))
			continue;

		pev(iVictim, pev_takedamage, flTakeDamage);
		if (flTakeDamage == DAMAGE_NO)
			continue;

		if (!get_pcvar_num(g_CvarFriendlyFire) && fm_is_user_same_team(iAttacker, iVictim))
			continue;
		
		flDistance = get_distance_f(vecOrigin, vecOrigin2);
		flFraction = (flRadius - flDistance) / flRadius;
		pev(iVictim, pev_origin, vecOrigin2);

		UTIL_ScreenShake(iVictim, flShakeDur * flFraction, flShakeFreq * flFraction, flShakeAmp * flFraction);
		UTIL_ScreenFade(iVictim, flFadeDur, flFadeHold, FFADE_IN, 255, 255, 255, 255);

		vecPunchAngle[0] = random_float(-flPunchMax, flPunchMax);
		vecPunchAngle[1] = random_float(-flPunchMax, flPunchMax);
		vecPunchAngle[2] = random_float(-flPunchMax, flPunchMax);
		xs_vec_mul_scalar(vecPunchAngle, flFraction, vecPunchAngle);
		set_pev(iVictim, pev_punchangle, vecPunchAngle);
		
		xs_vec_sub(vecOrigin2, vecOrigin, vecVelocity);				// 创造一个向量, 方向指向受害者的点。(计算时需要将受害者的坐标减去爆炸中心)
		xs_vec_normalize(vecVelocity, vecVelocity);					// 修正此向量为单位向量
		flSpeed = floatpower(flKnockForce, flFraction);				// 以指数衰减定义冲击波
		xs_vec_mul_scalar(vecVelocity, flSpeed, vecVelocity);		// 向量数乘, 将速率转为速度
		vecVelocity[2] += flKnockForce * random_float(0.35, 0.45);	// 强化竖直方向上的速度
		set_pev(iVictim, pev_velocity, vecVelocity);				// 给受害者设置计算完毕的速度(即击退)
	}
}

stock LibExplosion_SetGlobalTrace(const Float:vecEndPos[3], const Float:vecPlaneNormal[3])
{
	set_tr2(0, TR_vecEndPos, vecEndPos);
	set_tr2(0, TR_vecPlaneNormal, vecPlaneNormal);
}

stock LibExplosion_FullVFX(tr = 0)	// Use global TR.
{
	new Float:vecOrigin[3];
	get_tr2(tr, TR_vecEndPos, vecOrigin);

	new Float:vecDir[3];
	get_tr2(tr, TR_vecPlaneNormal, vecDir);

	new Float:vecVFXOrigin[3];
	xs_vec_mul_scalar(vecDir, 200.0, vecVFXOrigin);
	xs_vec_add(vecOrigin, vecVFXOrigin, vecVFXOrigin);

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecVFXOrigin, 0);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, vecVFXOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecVFXOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecVFXOrigin[2]);
	write_short(g_iLawsSprIndex[lawspr_rocketexp]);
	write_byte(20);
	write_byte(100);
	message_end();
	
	xs_vec_mul_scalar(vecDir, 70.0, vecVFXOrigin);
	xs_vec_add(vecOrigin, vecVFXOrigin, vecVFXOrigin);

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecVFXOrigin, 0);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, vecVFXOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecVFXOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecVFXOrigin[2]);
	write_short(g_iLawsSprIndex[lawspr_rocketexp2]);
	write_byte(30);
	write_byte(255);
	message_end();
	
	engfunc(EngFunc_MessageBegin, MSG_ALL, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_WORLDDECAL);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_byte(g_iScorchTextureIndex[random_num(0, sizeof g_iScorchTextureIndex - 1)]);
	message_end();
	
	xs_vec_mul_scalar(vecDir, 24.0, vecVFXOrigin);
	xs_vec_add(vecOrigin, vecVFXOrigin, vecVFXOrigin);

	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, vecVFXOrigin, 0);
	write_byte(TE_DLIGHT);
	engfunc(EngFunc_WriteCoord, vecVFXOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecVFXOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecVFXOrigin[2]);
	write_byte(50);
	write_byte(255);
	write_byte(0);
	write_byte(0);
	write_byte(2);
	write_byte(0);
	message_end();

	new iEntity, Float:vecAngles[3];
	vector_to_angle(vecDir, vecAngles);
	for (new i = 0; i < 3; i ++)
	{
		iEntity = engfunc(EngFunc_CreateNamedEntity, g_istr_spark_shower);
		engfunc(EngFunc_SetSize, iEntity, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0});
		engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);
		set_pev(iEntity, pev_angles, vecAngles);
		dllfunc(DLLFunc_Spawn, iEntity);
	}
	
	if (engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_WATER)
		return;
	
	xs_vec_mul_scalar(vecDir, 40.0, vecVFXOrigin);
	xs_vec_add(vecOrigin, vecVFXOrigin, vecOrigin);	// Overwrite the original vecOrigin.
	
	new Float:vecOrigin2[8][3], Float:vecOrigin3[21][3], Float:vecPosition[3];
	xs_vec_copy(vecOrigin, vecPosition);
	get_spherical_coord(vecPosition, 100.0, 20.0, 0.0, vecOrigin3[0]);
	get_spherical_coord(vecPosition, 0.0, 100.0, 0.0, vecOrigin3[1]);
	get_spherical_coord(vecPosition, 100.0, 100.0, 0.0, vecOrigin3[2]);
	get_spherical_coord(vecPosition, 70.0, 120.0, 0.0, vecOrigin3[3]);
	get_spherical_coord(vecPosition, 120.0, 20.0, 0.0, vecOrigin3[4]);
	get_spherical_coord(vecPosition, 120.0, 65.0, 0.0, vecOrigin3[5]);
	get_spherical_coord(vecPosition, 120.0, 110.0, 0.0, vecOrigin3[6]);
	get_spherical_coord(vecPosition, 120.0, 155.0, 0.0, vecOrigin3[7]);
	get_spherical_coord(vecPosition, 120.0, 200.0, 0.0, vecOrigin3[8]);
	get_spherical_coord(vecPosition, 120.0, 245.0, 0.0, vecOrigin3[9]);
	get_spherical_coord(vecPosition, 120.0, 290.0, 20.0, vecOrigin3[10]);
	get_spherical_coord(vecPosition, 120.0, 335.0, 20.0, vecOrigin3[11]);
	get_spherical_coord(vecPosition, 120.0, 40.0, 20.0, vecOrigin3[12]);
	get_spherical_coord(vecPosition, 40.0, 120.0, 20.0, vecOrigin3[13]);
	get_spherical_coord(vecPosition, 40.0, 110.0, 20.0, vecOrigin3[14]);
	get_spherical_coord(vecPosition, 60.0, 110.0, 20.0, vecOrigin3[15]);
	get_spherical_coord(vecPosition, 110.0, 40.0, 20.0, vecOrigin3[16]);
	get_spherical_coord(vecPosition, 120.0, 30.0, 20.0, vecOrigin3[17]);
	get_spherical_coord(vecPosition, 30.0, 130.0, 20.0, vecOrigin3[18]);
	get_spherical_coord(vecPosition, 30.0, 125.0, 20.0, vecOrigin3[19]);
	get_spherical_coord(vecPosition, 30.0, 120.0, 20.0, vecOrigin3[20]);
	
	for (new i = 0; i < 21; i++)
	{
		if (i < 8)
		{
			engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
			write_byte(TE_BREAKMODEL);
			engfunc(EngFunc_WriteCoord, vecOrigin[0]);
			engfunc(EngFunc_WriteCoord, vecOrigin[1]);
			engfunc(EngFunc_WriteCoord, vecOrigin[2]);
			engfunc(EngFunc_WriteCoord, 1.0);
			engfunc(EngFunc_WriteCoord, 1.0);
			engfunc(EngFunc_WriteCoord, 1.0);
			engfunc(EngFunc_WriteCoord, random_float(-500.0, 500.0));
			engfunc(EngFunc_WriteCoord, random_float(-500.0, 500.0));
			engfunc(EngFunc_WriteCoord, random_float(-300.0, 300.0));
			write_byte(10);
			write_short(g_iBreakModels[random_num(0, sizeof g_szBreakModels - 1)]);
			write_byte(random_num(1, 4));
			write_byte(random_num(4, 8) * 10);
			write_byte(0x40);
			message_end();
		}
		
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin3[i], 0);
		write_byte(TE_SPRITE);
		engfunc(EngFunc_WriteCoord, vecOrigin3[i][0]);
		engfunc(EngFunc_WriteCoord, vecOrigin3[i][1]);
		engfunc(EngFunc_WriteCoord, vecOrigin3[i][2]);
		write_short(g_iLawsSprIndex[lawspr_smokespr2]);
		write_byte(10);
		write_byte(255);
		message_end();
	}
	
	xs_vec_mul_scalar(vecDir, 120.0, vecVFXOrigin);
	xs_vec_add(vecOrigin, vecVFXOrigin, vecOrigin);	// Overwrite the original vecOrigin.

	get_spherical_coord(vecOrigin, 0.0, 0.0, 185.0, vecOrigin2[0]);
	get_spherical_coord(vecOrigin, 0.0, 80.0, 130.0, vecOrigin2[1]);
	get_spherical_coord(vecOrigin, 41.0, 43.0, 110.0, vecOrigin2[2]);
	get_spherical_coord(vecOrigin, 90.0, 90.0, 90.0, vecOrigin2[3]);
	get_spherical_coord(vecOrigin, 80.0, 25.0, 185.0, vecOrigin2[4]);
	get_spherical_coord(vecOrigin, 101.0, 100.0, 162.0, vecOrigin2[5]);
	get_spherical_coord(vecOrigin, 68.0, 35.0, 189.0, vecOrigin2[6]);
	get_spherical_coord(vecOrigin, 0.0, 95.0, 155.0, vecOrigin2[7]);
	
	for (new i = 0; i < 8; i++)
	{
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin2[i], 0);
		write_byte(TE_SPRITE);
		engfunc(EngFunc_WriteCoord, vecOrigin2[i][0]);
		engfunc(EngFunc_WriteCoord, vecOrigin2[i][1]);
		engfunc(EngFunc_WriteCoord, vecOrigin2[i][2]);
		write_short(g_iLawsSprIndex[lawspr_smoke]);
		write_byte(50);
		write_byte(50);
		message_end();
	}
}

stock LibExplosion_SimplifiedVFX(tr = 0)
{
	new Float:vecOrigin[3];
	get_tr2(tr, TR_vecEndPos, vecOrigin);

	new Float:vecDir[3];
	get_tr2(tr, TR_vecPlaneNormal, vecDir);

	new Float:vecVFXOrigin[3];
	xs_vec_mul_scalar(vecDir, random_float(50.0, 55.0), vecVFXOrigin);
	xs_vec_add(vecOrigin, vecVFXOrigin, vecVFXOrigin);
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecVFXOrigin, 0);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, vecVFXOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecVFXOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecVFXOrigin[2]);
	write_short(g_sModelIndexFireball3);
	write_byte(25);
	write_byte(30);
	write_byte(TE_EXPLFLAG_NOSOUND);
	message_end();

	xs_vec_mul_scalar(vecDir, random_float(70.0, 95.0), vecVFXOrigin);
	xs_vec_add(vecOrigin, vecVFXOrigin, vecVFXOrigin);
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecVFXOrigin, 0);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, vecVFXOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecVFXOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecVFXOrigin[2]);
	write_short(g_sModelIndexFireball2);
	write_byte(30);
	write_byte(30);
	write_byte(TE_EXPLFLAG_NONE);
	message_end();
}

stock UTIL_ScreenShake(iPlayer, Float:flDuration, Float:flFrequence, Float:flAmplitude)
{
	message_begin(MSG_ONE_UNRELIABLE, gmsgShake, _, iPlayer);
	write_short(FixedUnsigned16(flAmplitude, 1<<12));	// amplitude
	write_short(FixedUnsigned16(flDuration, 1<<12));	// duration
	write_short(FixedUnsigned16(flFrequence, 1<<12));	// frequency
	message_end();
}

stock UTIL_ScreenFade(iPlayer, Float:flDuration, Float:flHoldTime, bitsFlags, r, g, b, a)
{
	message_begin(MSG_ONE_UNRELIABLE, gmsgFade, _, iPlayer);
	write_short(FixedUnsigned16(flDuration, 1<<12));	// duration
	write_short(FixedUnsigned16(flHoldTime, 1<<12));	// hold time
	write_short(bitsFlags);	// flags
	write_byte(r);	// r
	write_byte(g);	// g
	write_byte(b);	// b
	write_byte(a);	// a
	message_end();
}

stock Float:GetAmountOfPlayerVisible(const Float:vecSrc[3], iEntity)
{
	new Float:retval = 0.0;
	new tr = create_tr2();

	const Float:topOfHead = 25.0;
	const Float:standFeet = 34.0;
	const Float:crouchFeet = 14.0;
	const Float:edgeOffset = 13.0;

	const Float:damagePercentageChest = 0.40;
	const Float:damagePercentageHead = 0.20;
	const Float:damagePercentageFeet = 0.20;
	const Float:damagePercentageRightSide = 0.10;
	const Float:damagePercentageLeftSide = 0.10;

	if (!is_user_connected(iEntity))
	{
		new Float:vecOrigin[3];
		pev(iEntity, pev_origin, vecOrigin);

		// the entity is not a player, so the damage is all or nothing.
		engfunc(EngFunc_TraceLine, vecSrc, vecOrigin, IGNORE_MONSTERS, 0, tr);

		new Float:flFraction;
		get_tr2(tr, TR_flFraction, flFraction);

		if (flFraction == 1.0)
			retval = 1.0;

		free_tr2(tr);
		return retval;
	}

	// check chest
	new Float:vecChest[3];
	pev(iEntity, pev_origin, vecChest);
	engfunc(EngFunc_TraceLine, vecSrc, vecChest, IGNORE_MONSTERS, 0, tr);

	new Float:flFraction;
	get_tr2(tr, TR_flFraction, flFraction);
	if (flFraction == 1.0)
		retval += damagePercentageChest;

	// check top of head
	new Float:vecHead[3];
	xs_vec_set(vecHead, vecChest[0], vecChest[1], vecChest[2] + topOfHead);
	engfunc(EngFunc_TraceLine, vecSrc, vecHead, IGNORE_MONSTERS, 0, tr);

	get_tr2(tr, TR_flFraction, flFraction);
	if (flFraction == 1.0)
		retval += damagePercentageHead;

	// check feet
	new Float:vecFeet[3];
	xs_vec_set(vecFeet, vecChest[0], vecChest[1], vecChest[2] - (pev(iEntity, pev_flags) & FL_DUCKING ? crouchFeet : standFeet));

	engfunc(EngFunc_TraceLine, vecSrc, vecFeet, IGNORE_MONSTERS, 0, tr);

	get_tr2(tr, TR_flFraction, flFraction);
	if (flFraction == 1.0)
		retval += damagePercentageFeet;

	new Float:vecDir[3];
	xs_vec_sub(vecChest, vecSrc, vecDir);
	vecDir[2] = 0.0;
	xs_vec_normalize(vecDir, vecDir);

	new Float:prep[3];
	xs_vec_set(prep, -vecDir[1] * edgeOffset, vecDir[0] * edgeOffset, 0.0);

	new Float:vecRightSide[3];
	xs_vec_add(vecChest, prep, vecRightSide);
	new Float:vecLeftSide[3];
	xs_vec_sub(vecChest, prep, vecLeftSide);

	// check right "edge"
	engfunc(EngFunc_TraceLine, vecSrc, vecRightSide, IGNORE_MONSTERS, 0, tr);

	get_tr2(tr, TR_flFraction, flFraction);
	if (flFraction == 1.0)
		retval += damagePercentageRightSide;

	// check left "edge"
	engfunc(EngFunc_TraceLine, vecSrc, vecLeftSide, IGNORE_MONSTERS, 0, tr);

	get_tr2(tr, TR_flFraction, flFraction);
	if (flFraction == 1.0)
		retval += damagePercentageLeftSide;

	free_tr2(tr);
	return retval;
}

stock bool:fm_is_user_same_team(index1, index2)
{
	return !!(get_pdata_int(index1, m_iTeam) == get_pdata_int(index2, m_iTeam));
}

stock UTIL_RandomizeSmokeSprite()
{
	switch (random_num(0, 2))
	{
		case 0:
			return g_iLawsSprIndex[lawspr_smokespr];
		
		case 1:
			return g_iLawsSprIndex[lawspr_smoke];
		
		case 2:
			return g_iLawsSprIndex[lawspr_smoke2];
	}

	return 0;
}
