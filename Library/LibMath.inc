/*

Created Date: Apr 03 2021

Modern Warfare Dev Team
 - Luna the Reborn

*/

#if defined _csmwzr_lib_math
	#endinput
#endif
#define _csmwzr_lib_math

stock FixedUnsigned16(Float:value, scale = (1<<12))
{
	new Float:output = value * float(scale);
	if (output < 0.0)
		output = 0.0;

	if (output > float(0xFFFF))
		output = float(0xFFFF);

	return floatround(output);
}

stock get_spherical_coord(const Float:ent_origin[3], Float:redius, Float:level_angle, Float:vertical_angle, Float:origin[3])
{
	static Float:length;
	length = redius * floatcos(vertical_angle, degrees);
	
	origin[0] = ent_origin[0] + length * floatcos(level_angle, degrees);
	origin[1] = ent_origin[1] + length * floatsin(level_angle, degrees);
	origin[2] = ent_origin[2] + redius * floatsin(vertical_angle, degrees);
}

stock Float:_s_vOrigin[3], Float:_s_vAngle[3], Float:_s_vForward[3], Float:_s_vRight[3], Float:_s_vUp[3];

stock get_aim_origin_vector(iPlayer, Float:forw, Float:right, Float:up, Float:vStart[])
{
	pev(iPlayer, pev_origin, _s_vOrigin);
	pev(iPlayer, pev_view_ofs, _s_vUp);
	xs_vec_add(_s_vOrigin, _s_vUp, _s_vOrigin);
	pev(iPlayer, pev_v_angle, _s_vAngle);
	
	angle_vector(_s_vAngle, ANGLEVECTOR_FORWARD, _s_vForward);
	angle_vector(_s_vAngle, ANGLEVECTOR_RIGHT, _s_vRight);
	angle_vector(_s_vAngle, ANGLEVECTOR_UP, _s_vUp);
	
	vStart[0] = _s_vOrigin[0] + _s_vForward[0] * forw + _s_vRight[0] * right + _s_vUp[0] * up;
	vStart[1] = _s_vOrigin[1] + _s_vForward[1] * forw + _s_vRight[1] * right + _s_vUp[1] * up;
	vStart[2] = _s_vOrigin[2] + _s_vForward[2] * forw + _s_vRight[2] * right + _s_vUp[2] * up;
}

stock get_aim_origin_vector2(const Float:vOrigin[3], const Float:vAngle[3], Float:forw, Float:right, Float:up, Float:vReturn[])
{
	angle_vector(vAngle, ANGLEVECTOR_FORWARD, _s_vForward);
	angle_vector(vAngle, ANGLEVECTOR_RIGHT, _s_vRight);
	angle_vector(vAngle, ANGLEVECTOR_UP, _s_vUp);
	
	vReturn[0] = vOrigin[0] + _s_vForward[0] * forw + _s_vRight[0] * right + _s_vUp[0] * up;
	vReturn[1] = vOrigin[1] + _s_vForward[1] * forw + _s_vRight[1] * right + _s_vUp[1] * up;
	vReturn[2] = vOrigin[2] + _s_vForward[2] * forw + _s_vRight[2] * right + _s_vUp[2] * up;
}

stock UTIL_GetPlayerAimingTR(iPlayer, &tr = 0)
{
	pev(iPlayer, pev_origin, _s_vOrigin);
	pev(iPlayer, pev_view_ofs, _s_vUp);
	xs_vec_add(_s_vOrigin, _s_vUp, _s_vOrigin);

	pev(iPlayer, pev_v_angle, _s_vAngle);
	angle_vector(_s_vAngle, ANGLEVECTOR_FORWARD, _s_vForward);
	xs_vec_mul_scalar(_s_vForward, 9999.0, _s_vForward);
	xs_vec_add(_s_vOrigin, _s_vForward, _s_vForward);

	engfunc(EngFunc_TraceLine, _s_vOrigin, _s_vForward, DONT_IGNORE_MONSTERS, iPlayer, tr);
	return tr;
}
