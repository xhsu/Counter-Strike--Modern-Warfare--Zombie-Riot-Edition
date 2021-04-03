/* AMXX Template by Devzone */

#include <amxmodx>
#include <orpheu>
#include <orpheu_stocks>

#define PLUGIN		"Fuck the mp_consistency"
#define VERSION		"1.0"
#define AUTHOR		"Luna the Reborn"

new OrpheuFunction:g_pfnForceUnmodified;

// LUNA: Copied from ReGameDLL-CS
// For integrity checking of content on clients
enum FORCE_TYPE
{
	force_exactfile,					// File on client must exactly match server's file
	force_model_samebounds,				// For model files only, the geometry must fit in the same bbox
	force_model_specifybounds,			// For model files only, the geometry must fit in the specified bbox
	force_model_spcfybnds_if_avail,		// For Steam model files only, the geometry must fit in the specified bbox (if the file is available)
};

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
}

public plugin_precache()	// You have to done it within CWorld::Precache() or it would be TOO LATE to do anything. g_engfuncs.pfnForceUnmodified was called in CWorld::Precache().
{
	g_pfnForceUnmodified = OrpheuGetEngineFunction("pfnForceUnmodified", "pfnForceUnmodified");

	OrpheuRegisterHook(g_pfnForceUnmodified, "pfnForceUnmodified");
}

public OrpheuHookReturn:pfnForceUnmodified(FORCE_TYPE:iType, Float:vecMins[3], Float:vecMaxs[3], const szFileName[])
{
	server_print("Block pfnForceUnmodified on file: %s", szFileName);
	return OrpheuSupercede;
}
