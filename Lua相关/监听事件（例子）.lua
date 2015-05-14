--注册
if CEventGameMode == nil then
        CEventGameMode = class({})
end
 
--用于模型，特效，音效的预载入
function Precache( context )
 
end
 
--激活某些函数
function Activate()
        CEventGameMode:InitGameMode()
end

--用于游戏的初始化
function CEventGameMode:InitGameMode()
        print( "CEventGameMode:InitGameMode is loaded." )
 
        --监听游戏进度
        ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(CEventGameMode,"OnGameRulesStateChange"), self)
 
        --监听单位被击杀的事件
        ListenToGameEvent("entity_killed", Dynamic_Wrap(CEventGameMode, "OnEntityKilled"), self)
 
        --同一事件名可以有不同的函数，但是基本没这个必要
        ListenToGameEvent("entity_killed", Dynamic_Wrap(CEventGameMode, "OnEntityKilledHero"), self)
 
        --监听单位受到伤害事件
        ListenToGameEvent("entity_hurt", Dynamic_Wrap(CEventGameMode, "OnEntityHurt"), self)
 
        --监听单位重生或者创建事件
        ListenToGameEvent("npc_spawned", Dynamic_Wrap(CEventGameMode, "OnNPCSpawned"), self)
 
        --监听玩家断开连接的事件
        ListenToGameEvent("player_disconnect", Dynamic_Wrap(CEventGameMode, "OnPlayerDisconnect"), self)
 
        --监听物品被购买的事件
        ListenToGameEvent("dota_item_purchased", Dynamic_Wrap(CEventGameMode, "OnDotaItemPurchased"), self)
 
        --监听玩家聊天事件
        ListenToGameEvent("player_say", Dynamic_Wrap(CEventGameMode, "PlayerSay"), self)
end
 
 
function CEventGameMode:OnGameRulesStateChange( keys )
        print("OnGameRulesStateChange")
        DeepPrintTable(keys)    --详细打印传递进来的表
 
        GameRules:SetPreGameTime( 10.0)
 
        --获取游戏进度
        local newState = GameRules:State_Get()
 
        if newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
                print("Player begin select hero")  --玩家处于选择英雄界面
 
        elseif newState == DOTA_GAMERULES_STATE_PRE_GAME then
                print("Player ready game begin")  --玩家处于游戏准备状态
 
        elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
                print("Player game begin")  --玩家开始游戏
 
        end
end
 
function CEventGameMode:OnEntityKilled( keys )
        print("OnEntityKilled")
        DeepPrintTable(keys)    --详细打印传递进来的表
end
 
function CEventGameMode:OnEntityKilledHero( keys )
        print("OnEntityKilledHero")
        DeepPrintTable(keys)    --详细打印传递进来的表
end
 
function CEventGameMode:OnEntityHurt( keys )
        print("OnEntityHurt")
        DeepPrintTable(keys)    --详细打印传递进来的表
 
        local attacker = EntIndexToHScript(keys.entindex_attacker)
        local killed = EntIndexToHScript(keys.entindex_killed)
 
        print(attacker:GetUnitName()..","..killed:GetUnitName())
 
end
 
function CEventGameMode:OnNPCSpawned( keys )
        print("OnNPCSpawned")
        DeepPrintTable(keys)    --详细打印传递进来的表
end
 
function CEventGameMode:OnPlayerDisconnect( keys )
        print("OnPlayerDisconnect")
        DeepPrintTable(keys)    --详细打印传递进来的表
end
 
function CEventGameMode:OnDotaItemPurchased( keys )
        print("OnDotaItemPurchased")
        DeepPrintTable(keys)    --详细打印传递进来的表
end
 
function CEventGameMode:PlayerSay( keys )
        print("PlayerSay")
        DeepPrintTable(keys)    --详细打印传递进来的表
End