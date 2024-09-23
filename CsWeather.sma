/* AMXX编写头版 by Devzone */

#include <amxmodx>

#pragma semicolon 1

#define PLUGIN		"Weather Controller"
#define VERSION		"1.0"
#define AUTHOR		"xhsu"

enum EWeather
{
	Sunny = 1,
	Drizzle = 2,
	ThunderStorm = 3,
	Tempest = 4,
	Snow = 5,
	Sleet = 6,
	BlackFog = 7,
};

enum EReceiveW
{
	Clear = 0,
	Rain,
	Snow,
};

native Weather_SetFog(r, g, b, Float:flDensity);
native Weather_SetReceiveW(EReceiveW:what);
native Weather_SetLightLevel(cLightLevel);
native Weather_SetWeather(EWeather:what, cLightLevel = 0);

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_concmd("set_fog", "Command_SetFog");
	register_concmd("set_weather", "Command_SetWeather");
	register_concmd("set_lightlevel", "Command_SetLightLevel");

	register_concmd("set_sunny", "Command_SetSunny");
	register_concmd("set_drizzle", "Command_SetDrizzle");
	register_concmd("set_thunder_storm", "Command_SetThunderStorm");
	register_concmd("set_tempest", "Command_SetTempest");
	register_concmd("set_snow", "Command_SetSnow");
	register_concmd("set_sleet", "Command_SetSleet");
	register_concmd("set_blackfog", "Command_SetBlackFog");
}

public Command_SetFog(iPlayer)
{
	if (read_argc() < 5)
		return PLUGIN_HANDLED;

	new szR[4], szG[4], szB[4], szDensity[16];
	read_argv(1, szR, charsmax(szR));
	read_argv(2, szG, charsmax(szG));
	read_argv(3, szB, charsmax(szB));
	read_argv(4, szDensity, charsmax(szDensity));

	Weather_SetFog(
		str_to_num(szR), str_to_num(szG), str_to_num(szB),
		str_to_float(szDensity)
	);

	client_print(iPlayer, print_console, "density: %f", str_to_float(szDensity));

	return PLUGIN_HANDLED;
}

public Command_SetWeather(iPlayer)
{
	if (read_argc() < 2)
		return PLUGIN_HANDLED;

	new szType[4];
	read_argv(1, szType, charsmax(szType));

	Weather_SetReceiveW(EReceiveW:str_to_num(szType));

	return PLUGIN_HANDLED;
}

public Command_SetLightLevel(iPlayer)
{
	if (read_argc() < 2)
		return PLUGIN_HANDLED;

	new szType[4];
	read_argv(1, szType, charsmax(szType));

	Weather_SetLightLevel(szType[0]);

	return PLUGIN_HANDLED;
}

public Command_SetSunny(iPlayer)
{
	new sz[4];
	if (read_argc() > 1)
		read_argv(1, sz, charsmax(sz));
	else
		sz[0] = 'f';

	Weather_SetWeather(Sunny, sz[0]);
}

public Command_SetDrizzle(iPlayer)
{
	new sz[4];
	if (read_argc() > 1)
		read_argv(1, sz, charsmax(sz));
	else
		sz[0] = 'e';

	Weather_SetWeather(Drizzle, sz[0]);
}

public Command_SetThunderStorm(iPlayer)
{
	new sz[4];
	if (read_argc() > 1)
		read_argv(1, sz, charsmax(sz));
	else
		sz[0] = 'c';

	Weather_SetWeather(ThunderStorm, sz[0]);
}

public Command_SetTempest(iPlayer)
{
	new sz[4];
	if (read_argc() > 1)
		read_argv(1, sz, charsmax(sz));
	else
		sz[0] = 'b';

	Weather_SetWeather(Tempest, sz[0]);
}

public Command_SetSnow(iPlayer)
{
	new sz[4];
	if (read_argc() > 1)
		read_argv(1, sz, charsmax(sz));

	Weather_SetWeather(EWeather:5, sz[0]);
}

public Command_SetSleet(iPlayer)
{
	new sz[4];
	if (read_argc() > 1)
		read_argv(1, sz, charsmax(sz));

	Weather_SetWeather(Sleet, sz[0]);
}

public Command_SetBlackFog(iPlayer)
{
	new sz[4];
	if (read_argc() > 1)
		read_argv(1, sz, charsmax(sz));

	Weather_SetWeather(BlackFog, sz[0]);
}
