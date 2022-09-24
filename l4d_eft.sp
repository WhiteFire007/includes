//<3 i love sourcemod

//WHITEFIRE, THE NOOB SCRIPTER

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#pragma newdecls required

#define SPAWN                    "electrical_arc_01_system"
#define PARTICLE_BURST            "gas_explosion_initialburst" // Large explosion
#define PARTICLE_BLAST            "gas_explosion_initialburst_blast" // Large explosion HD
#define PARTICLE_HIT            "missile_hit1" // Particle when tank hit

#define SOUND "ui/pickup_secret01.wav"

char Sounds[][] =
{
    "ambient/explosions/explode_1.wav",
    "ambient/explosions/explode_3.wav",
    "weapons/hegrenade/explode3.wav",
    "weapons/hegrenade/explode4.wav",
    "weapons/hegrenade/explode5.wav"
};

#define SOUND_HOWL        "player/tank/voice/pain/tank_fire_08.wav"

bool IsMap = false, BoolJump[MAXPLAYERS+1] = false;

int LastButton[MAXPLAYERS+1], Time[MAXPLAYERS+1] = 0;

float OldPos[MAXPLAYERS+1][3];

public Plugin myinfo =
{
    name = "[L4D2] Extra Function Tank",
    author = "King_OXO",
    version = "2.0"
}

public void OnPluginStart()
{
    HookEvent("player_spawn", Event_spawntank);
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnMapStart()
{
    IsMap = true;
    PrecacheParticle(PARTICLE_BLAST);
    PrecacheParticle(PARTICLE_BURST);
    PrecacheParticle(SPAWN);
    PrecacheParticle(PARTICLE_HIT);
    
    PrecacheSound(SOUND, true);
    PrecacheSound(SOUND_HOWL, true);
    for(int i; i < sizeof Sounds; i++)
        PrecacheSound(Sounds[i], true);
}
public void OnMapEnd()
{
    IsMap = false;
}

//==========================================
// PSYK0TIK HEALTH SHOW SCRIPT
//==========================================
public void OnGameFrame()
{
    char sHealthBar[51];
    float Percentage = 0.0;
    int Tank = 0, iHealth = 0, iMaxHealth = 0, iTotalHealth = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i))
        {
            Tank = GetClientAimTarget(i);
            if (IsTank(Tank))
            {
                sHealthBar[0] = '\0';
                iHealth = IsPlayerIncap(Tank) ? 0 : GetEntProp(Tank, Prop_Data, "m_iHealth");
                iMaxHealth = GetEntProp(Tank, Prop_Data, "m_iMaxHealth");
                iTotalHealth = (iHealth > iMaxHealth) ? iHealth : iMaxHealth;
                Percentage = ((float(iHealth) / float(iTotalHealth)) * 100.0);

                PrintInstructorHintText(i, "%N [%i/%i HP (%.0f%s)]", Tank, iHealth, iTotalHealth, Percentage, "%%");
            }
        }
        else if(IsValidClient(i) && IsTank(i))
        {
            sHealthBar[0] = '\0';
            iHealth = IsPlayerIncap(i) ? 0 : GetEntProp(i, Prop_Data, "m_iHealth");
            iMaxHealth = GetEntProp(i, Prop_Data, "m_iMaxHealth");
            iTotalHealth = (iHealth > iMaxHealth) ? iHealth : iMaxHealth;
            Percentage = ((float(iHealth) / float(iTotalHealth)) * 100.0);

            PrintInstructorHintText(i, "%N [%i/%i HP (%.0f%s)]", i, iHealth, iTotalHealth, Percentage, "%%");
        }
    }
}
//==========================================

void PrintInstructorHintText(int client, char[] message, any ...)
{
    char buffer[512];
    SetGlobalTransTarget(client);
    VFormat(buffer, sizeof(buffer), message, 3);

    ReplaceString(buffer, sizeof(buffer), "{default}", "");
    ReplaceString(buffer, sizeof(buffer), "{white}", "");
    ReplaceString(buffer, sizeof(buffer), "{cyan}", "");
    ReplaceString(buffer, sizeof(buffer), "{lightgreen}", "");
    ReplaceString(buffer, sizeof(buffer), "{orange}", "");
    ReplaceString(buffer, sizeof(buffer), "{green}", "");
    ReplaceString(buffer, sizeof(buffer), "{olive}", "");

    ReplaceString(buffer, sizeof(buffer), "\x01", "");
    ReplaceString(buffer, sizeof(buffer), "\x03", "");
    ReplaceString(buffer, sizeof(buffer), "\x04", "");
    ReplaceString(buffer, sizeof(buffer), "\x05", "");

    char clienttargetname[64];
    GetEntPropString(client, Prop_Data, "m_iName", clienttargetname, sizeof(clienttargetname));

    char hintTarget[18];
    Format(hintTarget, sizeof(hintTarget), "l4d_eft_hint_%d", client);
        
    int entity = CreateEntityByName("env_instructor_hint");
    DispatchKeyValue(client, "targetname", hintTarget);
    DispatchKeyValue(entity, "hint_target", hintTarget);
    DispatchKeyValue(entity, "targetname", "l4d_eft");
    DispatchKeyValue(entity, "hint_caption", buffer);

    DispatchKeyValue(entity, "hint_icon_onscreen", "icon_skull");
    
    char sTemp[16];
        
    Format(sTemp, sizeof(sTemp), "%d %d %d", RoundToNearest(Cosine(client + 8.0 * GetGameTime() + 1) * 127.5 + 127.5),
    RoundToNearest(Cosine(client + 8.0 * GetGameTime() + 3) * 127.5 + 127.5), RoundToNearest(Cosine(client + 8.0 * GetGameTime() + 5) * 127.5 + 127.5));

    DispatchKeyValue(entity, "hint_color", sTemp);
    DispatchKeyValue(entity, "hint_pulseoption", "2");
    DispatchKeyValue(entity, "hint_shakeoption", "1");

    DispatchSpawn(entity);
    AcceptEntityInput(entity, "ShowHint", client);

    SetVariantString("OnUser1 !self:Kill::1.0:-1");
    AcceptEntityInput(entity, "AddOutput");
    AcceptEntityInput(entity, "FireUser1");

    DispatchKeyValue(client, "targetname", clienttargetname);
}

public Action Event_spawntank( Event event, const char[] name, bool dontBroadcast )
{
    int tank = GetClientOfUserId(event.GetInt("userid"));
    if (IsTank(tank))
    {
        EmitSoundToAll(SOUND, tank, SNDCHAN_AUTO, SNDLEVEL_HELICOPTER);
        EmitSoundToAll(SOUND_HOWL, tank, SNDCHAN_AUTO, SNDLEVEL_HELICOPTER);
        
        float Pos[3];
        GetClientAbsOrigin(tank, Pos);
        ShowParticle(Pos, SPAWN);
        
        for (int client = 1; client <= MaxClients; client++)
        {
            if (!IsClientInGame(client))
                continue;

            if (IsFakeClient(client))
                continue;
        }
    }
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
    if (!(LastButton[client] & IN_USE) && (buttons & IN_USE) && !BoolJump[client] && IsTank(client) && GetEntityFlags(client) & FL_ONGROUND)
    {
        BoolJump[client] = true;
        TankThrow(client);
        int flame = AttachFlame(client);
        vDeleteEntity(flame, 3.0);
        CreateTimer(1.0, Reset, client, TIMER_REPEAT);
    }
    if(!(LastButton[client] & IN_USE) && (buttons & IN_USE) && BoolJump[client] && IsTank(client))
    {
        CPrintToChat(client, "Wait {olive}•%d• {default}seconds to \x03Super Jump \x04again", 10 - Time[client]);
    }
    
    LastButton[client] = buttons;
    
    return Plugin_Continue;
}

public Action TankCollide(int client, int target)
{
    float TankPos[3];
    GetClientAbsOrigin(client, TankPos);
    if(GetVectorDistance(OldPos[client], TankPos) >= 2000.0)
    {
        ShowParticle(TankPos, PARTICLE_HIT);
        for (int i = 1; i <= MaxClients; i++)
        {
            if(IsValidClient(i) && GetClientTeam(i) == 2)
            {
                float Pos[3];
                GetClientAbsOrigin(i, Pos);
                if(GetVectorDistance(TankPos, Pos) <= 400.0) 
                {
                    float Damage = 400.0 - GetVectorDistance(TankPos, Pos);
                    SDKHooks_TakeDamage(i, client, client, Damage, DMG_BLAST);
                    StaggerClient(GetClientUserId(i), TankPos);
                }
            }
        }
        EmitSoundToAll(Sounds[GetRandomInt(0, sizeof Sounds - 1)], client, SNDCHAN_AUTO, SNDLEVEL_HELICOPTER);
        
        SDKUnhook(client, SDKHook_StartTouch, TankCollide);
    }
    else
    {
        SDKUnhook(client, SDKHook_StartTouch, TankCollide);
    }
}

public Action Reset(Handle timer, int client)
{
    if(Time[client] == 10)
    {
        KillTimer(timer);
        
        BoolJump[client] = false;
        Time[client] = 0;
    }
    else if(Time[client] >= 0)
    {
        Time[client] += 1;
    }
    
    return Plugin_Continue;
}

stock void TankThrow(int client)
{
    GetClientAbsOrigin(client, OldPos[client]);
    
    float vAng[3];
    float vPos[3];
    
    GetClientEyePosition( client,vPos );
    GetClientEyeAngles( client, vAng );
    Handle hTrace = TR_TraceRayFilterEx( vPos, vAng, MASK_SHOT, RayType_Infinite, bTraceEntityFilterPlayer );
    
    if ( TR_DidHit( hTrace ) )
    {
        float vBuffer[3];
        float vStart[3];
        float vDistance = -35.0;
        
        TR_GetEndPosition( vStart, hTrace );
        GetVectorDistance( vPos, vStart, false );
        GetAngleVectors( vAng, vBuffer, NULL_VECTOR, NULL_VECTOR );
        
        vPos[0] = vStart[0] + ( vBuffer[0] * vDistance );
        vPos[1] = vStart[1] + ( vBuffer[1] * vDistance );
        vPos[2] = vStart[2] + ( vBuffer[2] * vDistance );
        
        float ClientPos[3];
        float bfAng[3];
        float bfVol[3];
        GetEntPropVector( client, Prop_Send, "m_vecOrigin", ClientPos );
        GetEntPropVector( client, Prop_Data, "m_angRotation", bfAng );
        
        MakeVectorFromPoints( ClientPos, vPos, bfVol );
        NormalizeVector( bfVol, bfVol );
        GetVectorAngles( bfVol, bfAng );
        ScaleVector( bfVol, 1200.0 );
        TeleportEntity( client, NULL_VECTOR, bfAng, bfVol );
    }
    SDKHook(client, SDKHook_StartTouch, TankCollide);
    
    delete hTrace;
}

public bool bTraceEntityFilterPlayer( int entity, int contentsMask )
{
    return ( entity > MaxClients || !entity );
}

public void OnEntityDestroyed(int entity)
{
    if(IsMap)
    {
        if (entity > 32 && IsValidEntity(entity))
        {
            char classname[32];
            GetEdictClassname(entity, classname, sizeof(classname));
            if (StrEqual(classname, "tank_rock", true))
            {
                float RockPos[3];
                GetEntPropVector(entity, Prop_Send, "m_vecOrigin", RockPos);
                
                ShowParticle(RockPos, PARTICLE_BURST);
                ShowParticle(RockPos, PARTICLE_BLAST);
                
                for (int i = 1; i <= MaxClients; i ++)
                {
                    if (IsValidClient( i ) && GetClientTeam( i ) == 2)
                    {
                        float SurvivorPoS[3];
                        GetClientAbsOrigin(i, SurvivorPoS);
                        float distance = GetVectorDistance(RockPos, SurvivorPoS);
                        if (distance <= 150.0)
                        {
                            StaggerClient(GetClientUserId(i), RockPos);
                            SDKHooks_TakeDamage(i, 0, 0, 40.0, DMG_BLAST);
                        }
                    }
                }
            }
        }
    }
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (StrEqual(classname, "tank_rock", false))
        RequestFrame(OnTankRockNextFrame, EntIndexToEntRef(entity));
}

void OnTankRockNextFrame(int iEntRef)
{
    if (!IsValidEntRef(iEntRef))
        return;
    
    int entity = EntRefToEntIndex(iEntRef);
    
    int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
    
    if (!IsValidClient(client))
        return;
    
    if (!IsPlayerAlive(client))
        return;

    if (GetClientTeam(client) != 3)
        return;
        
    int RGBA[4];
    GetEntityRenderColor( client, RGBA[0], RGBA[1], RGBA[2], RGBA[3] );

    SetEntProp(entity, Prop_Send, "m_glowColorOverride",  RGBA[0] + (RGBA[1] *256) + (RGBA[2] * 65536) );
    SetEntProp(entity, Prop_Send, "m_iGlowType", 2);
    SetEntProp(entity, Prop_Send, "m_nGlowRange", 999999);
    SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", 0);
}

int AttachFlame(int client)
{
    int iFlame = CreateEntityByName( "env_steam" );
    if ( iFlame != -1 )
    {
        float vPos[3], vAng[3];
        GetEntPropVector(client, Prop_Data, "m_vecOrigin", vPos);
        vPos[2] += 30.0;
        vAng[0] = 90.0;
        vAng[1] = 0.0;
        vAng[2] = 0.0;

        DispatchKeyValue(iFlame, "spawnflags", "1");
        DispatchKeyValue(iFlame, "Type", "0");
        DispatchKeyValue(iFlame, "InitialState", "1");
        DispatchKeyValue(iFlame, "Spreadspeed", "10");
        DispatchKeyValue(iFlame, "Speed", "500");
        DispatchKeyValue(iFlame, "Startsize", "200");
        DispatchKeyValue(iFlame, "EndSize", "50");
        DispatchKeyValue(iFlame, "Rate", "60");
        DispatchKeyValue(iFlame, "JetLength", "500");

        SetEntityRenderColor(iFlame, 255, 90, 30, 255);
        TeleportEntity(iFlame, vPos, vAng, NULL_VECTOR);
        DispatchSpawn(iFlame);
        
        SetVariantString("!activator");
        AcceptEntityInput(iFlame, "SetParent", client);
    }
    
    return iFlame;
}

stock void vDeleteEntity(int ref, float duration = 0.1)
{
    if (IsValidEntRef(ref))
    {
        int iObject = EntRefToEntIndex(ref);
        if (IsValidEntity(iObject))
        {
            char sVariant[64];
            FormatEx(sVariant, sizeof sVariant, "OnUser1 !self:ClearParent::%f:-1", duration);
            SetVariantString(sVariant);
            AcceptEntityInput(iObject, "AddOutput");
            AcceptEntityInput(iObject, "FireUser1");

            FormatEx(sVariant, sizeof sVariant, "OnUser1 !self:Kill::%f:-1", duration + 0.1);
            SetVariantString(sVariant);
            AcceptEntityInput(iObject, "AddOutput");
            AcceptEntityInput(iObject, "FireUser1");
        }
    }
}

bool IsValidEntRef(int iEntRef)
{
    return iEntRef != 0 && EntRefToEntIndex(iEntRef) != INVALID_ENT_REFERENCE;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if( IsValidClient(attacker) && GetClientTeam(attacker) == 2 && IsTank(victim))
    {
        damage = damage * 0.4;
        return Plugin_Changed;
    }
    
    return Plugin_Continue;
}

public int ScreenFade(int target, int red, int green, int blue, int alpha, int duration, int type)
{
    Handle msg = StartMessageOne("Fade", target);
    BfWriteShort(msg, 500);
    BfWriteShort(msg, duration);
    if (type == 0)
        BfWriteShort(msg, (0x0002 | 0x0008));
    else
        BfWriteShort(msg, (0x0001 | 0x0010));
    BfWriteByte(msg, red);
    BfWriteByte(msg, green);
    BfWriteByte(msg, blue);
    BfWriteByte(msg, alpha);
    EndMessage();
}

public void ScreenShake(int target, float intensity)
{
    Handle msg;
    msg = StartMessageOne("Shake", target);
    
    BfWriteByte(msg, 0);
    BfWriteFloat(msg, intensity);
    BfWriteFloat(msg, 10.0);
    BfWriteFloat(msg, 3.0);
    EndMessage();
}
  
public Action ShowParticle( float Pos[3], char[] particlename )
{
    int particle = CreateEntityByName("info_particle_system");
    if( particle != -1 )
    {
        DispatchKeyValue(particle, "effect_name", particlename);
        
        DispatchSpawn(particle);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");

        TeleportEntity(particle, Pos, NULL_VECTOR, NULL_VECTOR);

        SetVariantString("OnUser1 !self:Kill::5.0:-1");
        AcceptEntityInput(particle, "AddOutput");
        AcceptEntityInput(particle, "FireUser1"); 
    }
}

void PrecacheParticle(const char[] sEffectName)
{
    static int table = INVALID_STRING_TABLE;
    if( table == INVALID_STRING_TABLE )
    {
        table = FindStringTable("ParticleEffectNames");
    }

    if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
    {
        bool save = LockStringTables(false);
        AddToStringTable(table, sEffectName);
        LockStringTables(save);
    }
}

bool IsPlayerIncap( int client )
{
    if( GetEntProp( client, Prop_Send, "m_isIncapacitated", 1 ) ) 
        return true;
    
    return false;
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

void StaggerClient(int iUserID, const float fPos[3])
{
    static int iScriptLogic = INVALID_ENT_REFERENCE;
    if( iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic) )
    {
        iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
        if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic))
            LogError("Could not create 'logic_script");

        DispatchSpawn(iScriptLogic);
    }

    char sBuffer[96];
    Format(sBuffer, sizeof(sBuffer), "GetPlayerFromUserID(%d).Stagger(Vector(%d,%d,%d))", iUserID, RoundFloat(fPos[0]), RoundFloat(fPos[1]), RoundFloat(fPos[2]));
    SetVariantString(sBuffer);
    AcceptEntityInput(iScriptLogic, "RunScriptCode");
    RemoveEntity(iScriptLogic);
}