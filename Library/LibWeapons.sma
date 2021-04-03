/*

Created Date: Apr 02 2021

Modern Warfare Dev Team
 - Luna the Reborn

*/

stock OrpheuFunction:g_pfn_CBP_DropShield;
stock OrpheuFunction:g_pfn_CBP_SelectItem;
stock OrpheuFunction:g_pfn_CBP_SetAnimation;
stock OrpheuFunction:g_pfn_CBPW_ReloadSound;
stock OrpheuFunction:g_pfn_CBPW_KickBack;

enum PLAYER_ANIM
{
	PLAYER_IDLE,
	PLAYER_WALK,
	PLAYER_JUMP,
	PLAYER_SUPERJUMP,
	PLAYER_DIE,
	PLAYER_ATTACK1,
	PLAYER_ATTACK2,
	PLAYER_FLINCH,
	PLAYER_LARGE_FLINCH,
	PLAYER_RELOAD,
	PLAYER_HOLDBOMB
};

stock LibWeapons_Init()
{
	g_pfn_CBP_DropShield = OrpheuGetFunction("DropShield", "CBasePlayer");
	g_pfn_CBP_SelectItem = OrpheuGetFunction("SelectItem", "CBasePlayer");
	g_pfn_CBP_SetAnimation = OrpheuGetFunction("SetAnimation", "CBasePlayer");	// Unsupported by zombieriot_amxx.dll
	g_pfn_CBPW_ReloadSound = OrpheuGetFunction("ReloadSound", "CBasePlayerWeapon");
	g_pfn_CBPW_KickBack = OrpheuGetFunction("KickBack", "CBasePlayerWeapon");
}

stock DropShield(iPlayer)
{
	OrpheuCallSuper(g_pfn_CBP_DropShield, iPlayer, true);
}

stock SelectItem(iPlayer, const szItem[])
{
	OrpheuCallSuper(g_pfn_CBP_SelectItem, iPlayer, szItem);
}

stock SetAnimation(iPlayer, PLAYER_ANIM:iAnim)
{
	OrpheuCallSuper(g_pfn_CBP_SelectItem, iPlayer, iAnim);
}

stock MakeReloadSound(iWeapon)
{
	OrpheuCallSuper(g_pfn_CBPW_ReloadSound, iWeapon);
}

stock KickBack(iWeapon, Float:up_base, Float:lateral_base, Float:up_modifier, Float:lateral_modifier, Float:up_max, Float:lateral_max, direction_change)
{
	OrpheuCallSuper(g_pfn_CBPW_KickBack, iWeapon, up_base, lateral_base, up_modifier, lateral_modifier, up_max, lateral_max, direction_change);
}

stock DropWeapons(iPlayer, iSlot)
{
	// Treat shield specially.
	if (iSlot == 1 && get_pdata_bool(iPlayer, m_bOwnsShield, XO_CBASEPLAYER))
	{
		DropShield(iPlayer);
		return;
	}

	new iWeapon = get_pdata_cbase(iPlayer, m_rgpPlayerItems[iSlot], XO_CBASEPLAYER);
	while (pev_valid(iWeapon) == 2)
	{
		static szClassname[32];
		pev(iWeapon, pev_classname, szClassname, charsmax(szClassname));
		
		engclient_cmd(iPlayer, "drop", szClassname);
		
		iWeapon = get_pdata_cbase(iWeapon, m_pNext, XO_CBASEPLAYERITEM);
	}
	
	set_pdata_cbase(iPlayer, m_rgpPlayerItems[0], -1, XO_CBASEPLAYER);
}

stock GiveItem(iPlayer, const szClassname[], iSpecialCode = 0)
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, szClassname));

	if (pev_valid(iEntity) != 2)
		return -1;
	
	// Do it right now. Before CBasePlayerWeapon::AddToPlayer() and CBasePlayerWeapon::Deploy().
	set_pev(iEntity, pev_weapons, iSpecialCode);

	new Float:vecOrigin[3];
	pev(iPlayer, pev_origin, vecOrigin);
	set_pev(iEntity, pev_origin, vecOrigin);
	set_pev(iEntity, pev_spawnflags, pev(iEntity, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, iEntity);
	
	new iTemp = pev(iEntity, pev_solid);
	dllfunc(DLLFunc_Touch, iEntity, iPlayer);
	
	if (pev(iEntity, pev_solid) != iTemp)
		return iEntity;
	
	engfunc(EngFunc_RemoveEntity, iEntity);
	return -1;
}

stock GetItemIdByArmoury(iArmouryIndex)
{
	switch (iArmouryIndex)
	{
		case ARMOURY_MP5NAVY: return CSW_MP5NAVY;
		case ARMOURY_TMP: return CSW_TMP;
		case ARMOURY_P90: return CSW_P90;
		case ARMOURY_MAC10: return CSW_MAC10;
		case ARMOURY_AK47: return CSW_AK47;
		case ARMOURY_SG552: return CSW_SG552;
		case ARMOURY_M4A1: return CSW_M4A1;
		case ARMOURY_AUG: return CSW_AUG;
		case ARMOURY_SCOUT: return CSW_SCOUT;
		case ARMOURY_G3SG1: return CSW_G3SG1;
		case ARMOURY_AWP: return CSW_AWP;
		case ARMOURY_M3: return CSW_M3;
		case ARMOURY_XM1014: return CSW_XM1014;
		case ARMOURY_M249: return CSW_M249;
		case ARMOURY_FLASHBANG: return CSW_FLASHBANG;
		case ARMOURY_HEGRENADE: return CSW_HEGRENADE;
		case ARMOURY_KEVLAR: return CSW_VEST;	// You should treat specially on this one!!
		case ARMOURY_ASSAULT: return CSW_VESTHELM;	// You should treat specially on this one!!
		case ARMOURY_SMOKEGRENADE: return CSW_SMOKEGRENADE;
		case ARMOURY_SHIELD: return 99;	// You should treat specially on this one!!
		case ARMOURY_GLOCK18: return CSW_GLOCK18;
		case ARMOURY_USP: return CSW_USP;
		case ARMOURY_ELITE: return CSW_ELITE;
		case ARMOURY_FIVESEVEN: return CSW_FIVESEVEN;
		case ARMOURY_P228: return CSW_P228;
		case ARMOURY_DEAGLE: return CSW_DEAGLE;
		case ARMOURY_FAMAS: return CSW_FAMAS;
		case ARMOURY_SG550: return CSW_SG550;
		case ARMOURY_GALIL: return CSW_GALIL;
		case ARMOURY_UMP45: return CSW_UMP45;
		default: return 0;
	}

	return 0;
}

stock GiveUserShield(iPlayer)
{
	set_pdata_bool(iPlayer, m_bOwnsShield, true, XO_CBASEPLAYER);
	set_pdata_bool(iPlayer, m_bHasPrimary, true, XO_CBASEPLAYER);

	// NOTE: Moved above, because CC4::Deploy can reset hitbox of shield.
	set_pev(iPlayer, pev_gamestate, HITGROUP_SHIELD_ENABLED);

	new iActiveItem = get_pdata_cbase(iPlayer, m_pActiveItem, XO_CBASEPLAYER);
	if (iActiveItem > 0)
	{
		new ammoIndex = get_pdata_int(iActiveItem, m_iPrimaryAmmoType, XO_CBASEPLAYERWEAPON);
		if (ammoIndex > 0 && get_pdata_int(iPlayer, m_rgAmmo_CBasePlayer[ammoIndex], XO_CBASEPLAYER) > 0)
		{
			ExecuteHamB(Ham_Item_Holster, iActiveItem, 0);
		}

		if (!ExecuteHamB(Ham_Item_Deploy, iActiveItem))
		{
			ExecuteHamB(Ham_Weapon_RetireWeapon, iActiveItem);
		}
	}
}

stock RemoveUserShield(iPlayer)
{
	if (get_pdata_bool(iPlayer, m_bOwnsShield, XO_CBASEPLAYER))
	{
		set_pdata_bool(iPlayer, m_bOwnsShield, false, XO_CBASEPLAYER);
		set_pdata_bool(iPlayer, m_bHasPrimary, false, XO_CBASEPLAYER);
		set_pdata_bool(iPlayer, m_bShieldDrawn, false, XO_CBASEPLAYER);
		set_pev(iPlayer, pev_gamestate, HITGROUP_SHIELD_DISABLED);

		new iHideHUD = get_pdata_int(iPlayer, m_iHideHUD, XO_CBASEPLAYER);
		if (iHideHUD & HIDEHUD_CROSSHAIR)
		{
			set_pdata_int(iPlayer, m_iHideHUD, iHideHUD & ~HIDEHUD_CROSSHAIR, XO_CBASEPLAYER);
		}
	}
}

stock RevealWeaponFromWeaponBox(iEntity, &iSlot = 0)
{
	for (new i = 0; i < sizeof m_rgpPlayerItems2; i++)
	{
		new iWeapon = get_pdata_cbase(iEntity, m_rgpPlayerItems2[i], XO_CWEAPONBOX);

		if (pev_valid(iWeapon) == 2)
		{
			iSlot = i;
			return iWeapon;
		}
	}

	return 0;
}

stock RevealAmmoTypeFromWeaponBox(iEntity)
{
	for (new i = 0; i < sizeof m_rgpPlayerItems2; i++)
	{
		new iWeapon = get_pdata_cbase(iEntity, m_rgpPlayerItems2[i], XO_CWEAPONBOX);

		if (pev_valid(iWeapon) == 2)
		{
			return get_pdata_int(iWeapon, m_iPrimaryAmmoType, XO_CWEAPONBOX);
		}
	}

	return 0;
}

stock SumAmmunitionOfWeaponBox(iEntity)
{
	new iSum = 0;

	for (new i = 0; i < sizeof m_rgAmmo2; i++)
	{
		iSum += get_pdata_int(iEntity, m_rgAmmo2[i], XO_CWEAPONBOX);
	}

	return iSum;
}

#define ITEM_FLAG_SELECTONEMPTY		1
#define ITEM_FLAG_NOAUTORELOAD		2
#define ITEM_FLAG_NOAUTOSWITCHEMPTY	4
#define ITEM_FLAG_LIMITINWORLD		8
#define ITEM_FLAG_EXHAUSTIBLE		16  // A player can totally exhaust their ammo supply and lose this weapon

stock const g_rgiGameWeaponAmmoId[] = { -1, 9, -1, 2, 12, 5, 14, 6, 4, 13, 10, 7, 6, 4, 4, 4, 6, 10, 1, 10, 3, 5, 4, 10, 2, 11, 8, 4, 2, -1, 7 };
stock const g_rgiGameWeaponPosInSlot[] = { -1, 3, -1, 9, 1, 12, 3, 13, 14, 3, 5, 6, 15, 16, 17, 18, 4, 2, 2, 7, 4, 5, 6, 11, 3, 2, 1, 10, 1, 1, 8 };
stock const g_rgiGameWeaponWhichSlot[] = { -1, 1, -1, 0, 3, 0, 4, 0, 0, 3, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 3, 1, 0, 0, 2, 0 };
stock const g_rgiGameWeaponAmmoMaxAmount[] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120, 30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 };

stock UTIL_WeaponList(iPlayer, iId, const szHudText[], iAmmo = -1, iSlot = -1)
{
	static gmsgWeaponList;
	if (!gmsgWeaponList)
		gmsgWeaponList = get_user_msgid("WeaponList");

	message_begin(MSG_ONE, gmsgWeaponList, _, iPlayer);
	write_string(szHudText);
	write_byte(g_rgiGameWeaponAmmoId[iId]);
	write_byte(iAmmo < 0 ? g_rgiGameWeaponAmmoMaxAmount[iId] : iAmmo);
	write_byte(-1);
	write_byte(-1);
	write_byte(iSlot < 0 ? g_rgiGameWeaponWhichSlot[iId] : iSlot - 1);
	write_byte(g_rgiGameWeaponPosInSlot[iId]);
	write_byte(iId);

	if (iId == CSW_C4 || iId == CSW_HEGRENADE || iId == CSW_FLASHBANG || iId == CSW_SMOKEGRENADE)
		write_byte(ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE);
	else
		write_byte(0);

	message_end();
}

stock UTIL_WeaponAnim(iPlayer, iAnim)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, _, iPlayer);
	write_byte(iAnim);
	write_byte(pev(iPlayer, pev_body));
	message_end();
}

stock UTIL_ForceWeaponAnim(iPlayer, iEntity, Float:flTime = 0.0)
{
	set_pdata_float(iPlayer, m_flNextAttack,			flTime);
	set_pdata_float(iEntity, m_flNextPrimaryAttack,		flTime, 4);
	set_pdata_float(iEntity, m_flNextSecondaryAttack,	flTime, 4);
	set_pdata_float(iEntity, m_flTimeWeaponIdle,		flTime, 4);
}

stock UTIL_RemovePlayerWeapon(iPlayer, iEntity)
{
	ExecuteHamB(Ham_Weapon_RetireWeapon, iEntity);
	ExecuteHamB(Ham_RemovePlayerItem, iPlayer, iEntity);
	ExecuteHamB(Ham_Item_Kill, iEntity);
	set_pev(iPlayer, pev_weapons, pev(iPlayer, pev_weapons) & ~(1<<get_pdata_int(iEntity, m_iId, XO_CBASEPLAYERITEM)));
}

stock UTIL_GetPlayerAimingTR(iPlayer, &tr = 0)
{
	static Float:vecSrc[3], Float:vecEnd[3];
	pev(iPlayer, pev_origin, vecSrc);
	pev(iPlayer, pev_view_ofs, vecEnd);
	xs_vec_add(vecSrc, vecEnd, vecSrc);

	pev(iPlayer, pev_v_angle, vecEnd);
	angle_vector(vecEnd, ANGLEVECTOR_FORWARD, vecEnd);
	xs_vec_mul_scalar(vecEnd, 9999.0, vecEnd);
	xs_vec_add(vecSrc, vecEnd, vecEnd);

	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, iPlayer, tr);
	return tr;
}
