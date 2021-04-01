#if !defined __keyvalues__
  #define __keyvalues__
#else
  #endinput
#endif

// Data type
enum
{
	DATATYPE_NONE = 0,
	DATATYPE_STRING,
	DATATYPE_INT,
	DATATYPE_FLOAT,
};

native kv_create(const name[] = "");
native kv_get_name(kv, output[], len);
native kv_set_name(kv, const name[]);
native kv_load_from_file(kv, const file[]);
native kv_save_to_file(kv, const file[]);
native kv_find_key(kv, const name[]);
native kv_add_sub_key(kv, sub_key);
native kv_remove_sub_key(kv, sub_key);
native kv_get_first_sub_key(kv);
native kv_get_next_key(kv);
native kv_get_first_value(kv);
native kv_get_next_value(kv);
native kv_get_int(kv, const name[] = "", defval = 0);
native Float:kv_get_float(kv, const name[] = "", Float:defval = 0.0);
native kv_get_string(kv, const name[] = "", output[], len, const defval[] = "");
native kv_is_empty(kv);
native kv_set_string(kv, const name[], const value[]);
native kv_set_int(kv, const name[], value);
native kv_set_float(kv, const name[], Float:value);
native kv_clear(kv);
native kv_get_data_type(kv, const name[] = "");
native kv_delete(kv);
