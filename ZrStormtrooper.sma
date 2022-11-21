/* ammx编写头版 by Devzone*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieriot>

#include <offset>
#include <cstrike_pdatas/pdatas_stocks>
#include "Library/LibWeapons.sma"

#define PLUGIN	"Zr Stormtrooper"
#define VERSION	"1.0.2 CSMW:ZR"
#define AUTHOR	"DSHGFHDS & Luna"

new const StormtrooperID = 1;			//突击卫士ID

new cvar_maxtotalwpns = 0;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
}

public plugin_cfg()
{
	cvar_maxtotalwpns = get_cvar_pointer("uktpg_MaxiumTotalWeaponCounts");
}

public zr_being_human(iPlayer)
{
	if (zr_get_human_id(iPlayer) != StormtrooperID)
		return;
	
	set_pev(iPlayer, pev_armorvalue, zr_get_human_health(StormtrooperID));
	set_pdata_int(iPlayer, m_iKevlar, ARMOR_VESTHELM);
	set_pdata_bool(iPlayer, m_bHasNightVision, true);

	for (new i = 0; i < AMMO_MAX_CAPACITY[AMMO_HEGrenade]; i++)
		GiveGrenade(iPlayer, CSW_HEGRENADE);
	
	for (new i = 0; i < AMMO_MAX_CAPACITY[AMMO_Flashbang]; i++)
		GiveGrenade(iPlayer, CSW_FLASHBANG);
	
	for (new i = 0; i < AMMO_MAX_CAPACITY[AMMO_SmokeGrenade]; i++)
		GiveGrenade(iPlayer, CSW_SMOKEGRENADE);
	
	new rgIndices[sizeof WEAPON_CLASSNAME], iCount = 0;

	new iFirearmCount = 0, iSlotCounts[InventorySlotCounts];
	CountFirearms(iPlayer, iFirearmCount, iSlotCounts);

	if (iFirearmCount < get_pcvar_num(cvar_maxtotalwpns) && iSlotCounts[PRIMARY_WEAPON_SLOT] < 1)
	{
		BuildWeaponList(PRIMARY_WEAPON_SLOT, rgIndices, iCount);

		if (iCount)
			GiveItem(iPlayer, WEAPON_CLASSNAME[rgIndices[random_num(1, iCount)]]);
	}

	if (iFirearmCount < get_pcvar_num(cvar_maxtotalwpns) && iSlotCounts[PISTOL_SLOT] < 1)
	{
		BuildWeaponList(PISTOL_SLOT, rgIndices, iCount);

		if (iCount)
			GiveItem(iPlayer, WEAPON_CLASSNAME[rgIndices[random_num(1, iCount)]]);
	}

	ReplenishAmmunition(iPlayer);
}

BuildWeaponList(iSlot, rgIndices[], &iCount)
{
	iCount = 0;

	for (new i = 0; i < sizeof WEAPON_CLASSNAME; i++)
	{
		if (iSlot > 0 && WEAPON_SLOT[i] != iSlot)
			continue;
			
		iCount++;
		rgIndices[iCount] = i;
	}
}