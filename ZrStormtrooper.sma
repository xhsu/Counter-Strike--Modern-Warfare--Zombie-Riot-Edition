/* ammx编写头版 by Devzone*/

#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieriot>

#include <offset>
#include <cstrike_pdatas/pdatas_stocks>
#include "Library/LibWeapons.sma"

#define PLUGIN	"Zr Stormtrooper"
#define VERSION	"1.0.3 CSMW:ZR"
#define AUTHOR	"DSHGFHDS & Luna"

new const StormtrooperID = 1;			//突击卫士ID

stock const g_rgszPrimaryWeaponsPool[][] =
{
	"weapon_xm1014",
	"weapon_aug", 
	"weapon_ump45",
	"weapon_galil",
	"weapon_famas",
	"weapon_mp5navy",
	"weapon_m3",
	"weapon_m4a1",
	"weapon_sg552",
	"weapon_ak47",
	"weapon_p90"
};

stock const g_rgszSecondaryWeaponsPool[][] =
{
	"weapon_p228",
	"weapon_elite",
	"weapon_fiveseven",
	"weapon_usp",
	"weapon_glock18",
	"weapon_deagle"
};

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

	new iFirearmCount = 0, iSlotCounts[InventorySlotCounts];
	CountFirearms(iPlayer, iFirearmCount, iSlotCounts);

	if (iFirearmCount < get_pcvar_num(cvar_maxtotalwpns) && iSlotCounts[PRIMARY_WEAPON_SLOT] < 1)
		GiveItem(iPlayer, g_rgszPrimaryWeaponsPool[random_num(0, sizeof g_rgszPrimaryWeaponsPool - 1)]);

	if (iFirearmCount < get_pcvar_num(cvar_maxtotalwpns) && iSlotCounts[PISTOL_SLOT] < 1)
		GiveItem(iPlayer, g_rgszSecondaryWeaponsPool[random_num(0, sizeof g_rgszSecondaryWeaponsPool - 1)]);

	ReplenishAmmunition(iPlayer);
}
