//<3 i love sourcemod

//WHITEFIRE, THE NOOB SCRIPTER

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <glow>
#pragma newdecls required

int Random1[MAXPLAYERS+1], Random2[MAXPLAYERS+1];

char Weapons1[][] =
{
	"models/weapons/melee/w_fireaxe.mdl", "models/weapons/melee/w_katana.mdl", "models/weapons/melee/w_machete.mdl"
},
WeaponClasses[][] =
{
	"fireaxe", "katana", "machete"
},
Weapons2[][] =
{
	"models/weapons/melee/w_fireaxe.mdl", "models/weapons/melee/w_katana.mdl", "models/weapons/melee/w_machete.mdl"
},  
WeaponsWiew[][] =
{
	"models/weapons/melee/v_fireaxe.mdl", "models/weapons/melee/v_katana.mdl", "models/weapons/melee/v_machete.mdl"
}, 
MeleeScripts[][] =
{
	"scripts/melee/fireaxe.txt", "scripts/melee/katana.txt", "scripts/melee/machete.txt"
};

public Plugin myinfo =
{
    name = "[L4D2] Tank Melee with glow and drop",
    author = "King_OXO",
    version = "1.0"
}

public void OnPluginStart()
{
    HookEvent("player_spawn", Event_spawntank);
    HookEvent("player_death", Event_tankdeath);
    
    CreateTimer(0.1, CheckAxe, _, TIMER_REPEAT);
}

public void OnMapStart()
{
    for (int x = 0; x < (sizeof MeleeScripts); x++)
    {
        PrecacheGeneric(MeleeScripts[x], true);
    }
    
    for (int i = 0; i < (sizeof Weapons2); i++)
    {
        PrecacheModel(WeaponsWiew[i], true);
        PrecacheModel(Weapons1[i], true);
        PrecacheModel(Weapons2[i], true);
    }
}

public Action Event_spawntank( Event event, const char[] name, bool dontBroadcast )
{
    int tank = GetClientOfUserId(event.GetInt("userid"));
    if (IsTank(tank))
    {
        //SetEntityRenderColor(tank, GetRandomInt(0, 255),  GetRandomInt(0, 255),  GetRandomInt(0, 255), 255);
        
        MeleeTank(tank);
    }
}

public Action Event_tankdeath( Event event, const char[] name, bool dontBroadcast )
{
    int tank = GetClientOfUserId(event.GetInt("userid"));
    if (IsTank(tank))
    {
        RemoveEntities(tank);
    }
}

public Action CheckAxe(Handle timer)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsTank(i))
        {
            RemoveEntities(i);
        }
    }
}

stock void RemoveEntities(int client)
{
    int entity = -1;
    while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != INVALID_ENT_REFERENCE)
    {
        char model[128];
        GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
        
        if (StrEqual(model, Weapons1[Random1[client]]))
        {
            int owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
            if (owner == client)
            {
                float flPos[3], flAngles[3];
                GetClientEyePosition(client, flPos);
                GetClientAbsAngles(client, flAngles);
            
                DropWeapon(flPos, flAngles, Random1[client]);
			
                AcceptEntityInput(entity, "Kill");
            }
        }
        else if (StrEqual(model, Weapons2[Random2[client]]))
        {
            int owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
            if (owner == client)
            {
                float flPos[3], flAngles[3];
                GetClientEyePosition(client, flPos);
                GetClientAbsAngles(client, flAngles);
            
                DropWeapon( flPos, flAngles, Random2[client]);
                AcceptEntityInput(entity, "Kill");
            }
        }
        
    }
}

void DropWeapon(float Pos[3], float Ang[3], int ivalue)
{
    int iDrop = CreateEntityByName("weapon_melee");
    if (IsValidEntity(iDrop))
    {
        DispatchKeyValue(iDrop, "melee_script_name", WeaponClasses[ivalue]);
        TeleportEntity(iDrop, Pos, Ang, NULL_VECTOR);
        DispatchSpawn(iDrop);
	
    	SetEntPropFloat(iDrop, Prop_Send,"m_flModelScale", 2.5);
    }
	
	L4D2_SetEntGlow(iDrop, L4D2Glow_OnLookAt, 999999, 0, {255, 0, 0}, true);
}

void MeleeTank(int client)
{
    Random1[client] = GetRandomInt(0, 2);
    Random2[client] = GetRandomInt(0, 2);
    
    int weapon1 = CreateEntityByName("prop_dynamic_override");
    if(IsValidEntity(weapon1))
    {    
        SetEntityModel(weapon1, Weapons1[Random1[client]]);
        DispatchSpawn(weapon1); 
        SetEntPropFloat(weapon1 , Prop_Send,"m_flModelScale", 2.5);

        float pos[3];
        float ang[3];        
    
        SetVector(pos, -4.0, 0.0, 3.0);
        SetVector(ang, 0.0, -11.0, 100.0);
		
        SetEntityMoveType(weapon1, MOVETYPE_NONE);
        SetEntProp(weapon1, Prop_Data, "m_CollisionGroup", 2);   
        AttachEnt(client, weapon1, "rhand", pos, ang);
    }
    
    int weapon2 = CreateEntityByName("prop_dynamic_override");   
    if(IsValidEntity(weapon2))
    {
        float pos[3];
        float ang[3];
        
        SetEntityModel(weapon2, Weapons2[Random2[client]]);
        DispatchSpawn(weapon2); 
        SetEntPropFloat(weapon2, Prop_Send,"m_flModelScale", 2.5);    
  
        SetVector(pos, 4.0, 0.0, -3.0);
        SetVector(ang, 0.0, -11.0, 100.0);
			
        SetEntityMoveType(weapon2, MOVETYPE_NONE);
        SetEntProp(weapon2, Prop_Data, "m_CollisionGroup", 2);   
        AttachEnt(client, weapon2, "lhand", pos, ang);
    }
	
	L4D2_SetEntGlow(weapon1, L4D2Glow_OnLookAt, 999999, 0, {255, 0, 0}, true);
	L4D2_SetEntGlow(weapon2, L4D2Glow_OnLookAt, 999999, 0, {255, 0, 0}, true);
}

void AttachEnt(int owner, int ent, char[] positon = "medkit", float pos[3] = NULL_VECTOR, float ang[3] = NULL_VECTOR)
{
    char tname[60];
    Format(tname, sizeof(tname), "target%d", owner);
    DispatchKeyValue(owner, "targetname", tname);         
    DispatchKeyValue(ent, "parentname", tname);
    
    SetVariantString(tname);
    AcceptEntityInput(ent, "SetParent", ent, ent, 0); 
    
    if(strlen(positon)!=0)
    {
        SetVariantString(positon); 
        AcceptEntityInput(ent, "SetParentAttachment");
    }
    
    TeleportEntity(ent, pos, ang, NULL_VECTOR);
    
    SetEntProp(ent, Prop_Send, "m_hOwnerEntity", owner);
}

float SetVector(float target[3], float x, float y, float z)
{
    target[0] = x;
    target[1] = y;
    target[2] = z;
}

bool IsValidClient(int client)
{
    return (1 <= client <= MaxClients && IsClientInGame(client));
}


bool IsTank(int client)
{
    if (IsValidClient(client) && GetClientTeam(client) == 3)
    {
        int class = GetEntProp(client, Prop_Send, "m_zombieClass");
        if (class == 8)
            return true;
        return false;
    }
    return false;
}