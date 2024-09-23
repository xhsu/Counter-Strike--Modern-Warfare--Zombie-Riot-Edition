/* AMXX编写头版 by Devzone */

#include <amxmodx>
#include <hamsandwich>

#pragma semicolon 1

#define PLUGIN		"Drop Grenades!"
#define VERSION		"1.0"
#define AUTHOR		"xhsu"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	RegisterHam(Ham_CS_Item_CanDrop, "weapon_hegrenade", "HamF_CS_Item_CanDrop");
	RegisterHam(Ham_CS_Item_CanDrop, "weapon_smokegrenade", "HamF_CS_Item_CanDrop");
	RegisterHam(Ham_CS_Item_CanDrop, "weapon_flashbang", "HamF_CS_Item_CanDrop");
}

public HamF_CS_Item_CanDrop(iWeapon)
{
	SetHamReturnInteger(true);
	return HAM_SUPERCEDE;
}
