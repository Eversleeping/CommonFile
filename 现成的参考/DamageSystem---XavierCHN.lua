--[[
        DamageSystem.lua Created by XavierCHN @ 04.14.2015, inspired by ����B
        ʹ�÷�����
        ������ļ��ŵ�scripts\vscripts\�ļ���(��Ȼ�ˣ����������ļ���ҲOK��ֻҪ����KV����д�϶�Ӧ��·������)��������Ҫ����˺���KV�ļ��У�ʹ�ã�
        "RunScript"
        {
                "ScriptFile"                "scripts/vscripts/DamageSystem.lua"
                "Function"                        "Damage"
                "formula"                        "(s_GetStrength - t_GetStrength + %min_strength_diff) * 2"
                // �����������̣�֧�����е�API�����������Զ����API������Ҫ�����API��������Ҫ�κβ���
                // �Զ����API��Ҫ��CDOTA_BaseNPC��Entities�ĳ�Ա����������Բο����������·��Ĵ���
                // ���̵�д���������� "s_GetAP * %ap_amp" �����ʩ���ߵ����ϻ�ȡAP��ֵ��Ȼ����Լ��ܵȼ������AP�˺�ϵ������ʩ�Ӹ�Ŀ���˺�
                // ��s_��ͷ�Ĵ����ʩ�������ϻ�ȡ��ֵ����t_��ͷ�Ĵ����Ŀ�����ϻ�ȡ��ֵ
                // ֧��+-*/^()��%����AbilitySpecial�е���ֵ��
                // ������̵���˼�ǣ���Ŀ�� (ʩ���ߵ�����ֵ - Ŀ�������ֵ + ������������) * 2 ���˺�
                "Type"                                "DAMAGE_TYPE_MAGICAL" // ��ѡ��֧��ħ���˺��������˺��ʹ����˺���Ĭ��Ϊ�����˺�
                "Flags"                                "DOTA_UNIT_TARGET_FLAG_INVULNERABLE | DOTA_UNIT_TARGET_FLAG_NO_INVIS" // �˺�Flags�����չٷ�д��д����
                "Target"                        "TARGET" // ����Ϊ�κ�Ŀ��Value�������Ҫ�Զ����λ����˺�����ô���淽����Center����
        }
]]
 
-- ��ĳ���ַ��滻Ϊ��һ���ַ�
local function stringReplace(str, src, res)
        local result = ""
        for i = 1, string.len(str) do
                local s = string.sub(str,i,i)
                if s == src then
                        result = result .. res
                else
                        result = result .. s
                end
        end
        return result
end
 
-- �ж��Ƿ��Ǳ������Ŀ�ͷ
local function isValidVarStarter(ch)
        return (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z") or (ch == "_") or (ch == "%")
end
 
-- �ж��Ƿ���Ȼ�ǺϷ����������ַ�
local function isValidVar(ch)
        return isValidVarStarter(ch) or (ch >= "1" and ch <= "9")
end
 
-- ����ַ���
local function stringSplit(str, sep)
        if type(str) ~= 'string' or type(sep) ~= 'string' then
        return nil
    end
    local res_ary = {}
    local cur = nil
    for i = 1, #str do
        local ch = string.byte(str, i)
        local hit = false
        for j = 1, #sep do
            if ch == string.byte(sep, j) then
                hit = true
                break
            end
        end
        if hit then
            if cur then
                table.insert(res_ary, cur)
            end
            cur = nil
        elseif cur then
            cur = cur .. string.char(ch)
        else
            cur = string.char(ch)
        end
    end
    if cur then
        table.insert(res_ary, cur)
    end
    return res_ary
end
 
-- �ж�����������ŵ����ȼ�
local function verifyOperatorPriority(op1, op2)
        if(op1 == "^") then
                return true
        elseif (op1 == "*" and op2 == "+") then
                return true
        elseif (op1 == "*" and op2 == "-") then
                return true
        elseif (op1 == "/" and op2 == "+") then
                return true
        elseif (op1 == "/" and op2 == "-") then
                return true
        else
                return false
        end
end
 
-- ������ѧ����
local function calculate(op1, op2, opr)
        if opr == "*" then
                op1 = op1 * op2
        elseif opr == "/" then
                if (op2 == 0) then
                        Warning("MATH WARNING!!!! Divided By 0!!! returning 99999")
                        op1 = 99999
                else
                        op1 = op1 / op2
                end
        elseif opr == "+" then
                op1 = op1 + op2
        elseif opr == "-" then
                op1 = op1 - op2
        elseif opr == "^" then
                op1 = op1 ^ op2
        end
        return op1
end
 
-- �����ʽת��Ϊ������ʽ
local function CalculateParenthesesExpression(sExpression)
        local vOperatorList = {} -- ��������
        local sOperator = "" -- ������
        local sExpString = "" -- ������ʽ
        local sOperand = "" -- ������
        local __s = "" -- ���ʽ�ĵ�ǰ�ַ�
        local __sExpression = sExpression -- �ݴ�һ�·���ʽ
         
        -- �滻�����пո�
        sExpression = stringReplace(sExpression, " ", "")
         
        -- �����ַ������������ʽ
        while(string.len(sExpression) > 0) do
                sOperand = ""
                -- ��������
                __s = string.sub(sExpression,1,1)
                if(tonumber(__s)) then
                        while((tonumber(__s)) or (__s == ".")) do
                                sOperand = sOperand .. __s
                                sExpression = string.sub(sExpression,2,string.len(sExpression))
                                if (sExpression == "") then break end
                                __s = string.sub(sExpression,1,1)
                        end
                        sExpString = sExpString .. sOperand .. "|"
                end
                 
                sOperand = ""
                 
                -- ����Ӣ���ַ������� s_GetStrength ���� %str_buff
                __s = string.sub(sExpression,1,1)
                if(isValidVarStarter(__s)) then
                        while(isValidVar(__s)) do
                                sOperand = sOperand .. __s
                                sExpression = string.sub(sExpression,2,string.len(sExpression))
                                if (sExpression == "") then break end
                                __s = string.sub(sExpression,1,1)
                        end
                        sExpString = sExpString .. sOperand .. "|"
                end
                 
                 
                -- ���� ������"("
                if (string.len(sExpression) > 0 and string.sub(sExpression,1,1) == "(") then
                        vOperatorList[#vOperatorList + 1] = "("
                        sExpression = string.sub(sExpression,2,string.len(sExpression))
                end
                 
                -- ���� ������")"
                sOperand = ""
                if (string.len(sExpression) > 0 and string.sub(sExpression,1,1) == ")") then
                        while (true) do
                                if (vOperatorList[#vOperatorList] ~= "(") then
                                        sOperand = sOperand .. vOperatorList[#vOperatorList] .. "|"
                                        vOperatorList[#vOperatorList] = nil
                                else
                                        vOperatorList[#vOperatorList] = nil
                                        break
                                end
                        end
                        sExpString = sExpString .. sOperand
                        sExpression = string.sub(sExpression,2,string.len(sExpression))
                end
                 
                -- ��������������+-*/^
                sOperand = ""
                if (string.len(sExpression) > 0) then
                        __s = string.sub(sExpression,1,1)
                        if ((__s == "+") or (__s == "-") or (__s == "*") or (__s == "/") or (__s == "^")) then
                                sOperator = __s
                                if (#vOperatorList > 0) then
                                        if ((vOperatorList[#vOperatorList] == "(") or verifyOperatorPriority(sOperator, vOperatorList[#vOperatorList])) then
                                                vOperatorList[#vOperatorList + 1] = sOperator
                                        else
                                                sOperand = sOperand .. vOperatorList[#vOperatorList] .. "|"
                                                vOperatorList[#vOperatorList] = nil
                                                vOperatorList[#vOperatorList + 1] = sOperator
                                                sExpString = sExpString .. sOperand
                                        end
                                else
                                        vOperatorList[#vOperatorList + 1] = sOperator
                                end
                                sExpression = string.sub(sExpression,2,string.len(sExpression))
                        end
                end
        end
         
        sOperand = ""
        -- ����������Ŷ�ջ
        while(#vOperatorList ~= 0) do
                sOperand = sOperand .. vOperatorList[#vOperatorList] .. "|"
                vOperatorList[#vOperatorList] = nil
        end
        -- ȥ�����һ��|����ӵ������������ʽ
        sExpString = sExpString .. string.sub(sOperand,1,string.len(sOperand) - 1)
        -- ����ת���õĺ�����ʽ
        return sExpString
end
 
-- �ж�ĳ���������Ƿ�Ϊ������(���������ʱ����ǲ�������~)
local function isOperand(str)
        return not( str == "+" or str == "-" or str == "*" or str == "/" or str == "^")
end
 
-- �������ȡ��ֵ
local function getNumber(source, target, ability, str)
        -- �����ֱ��ת��Ϊ��ֵ����ôֱ�ӷ���ת�������ֵ
        if (tonumber(str)) then return tonumber(str) end
 
        if (string.sub(str,1,2) == "s_") then -- ��s_��ͷ�ģ�Ϊsource��API����
                local apiFunc = string.sub(str,3,string.len(str))
                if (source[apiFunc]) then
                        if (type(source[apiFunc]) == "function") then
                                return source[apiFunc](source)
                        end
                end
                Warning("DamageSystem.lua throws an error: "..str.." is not a valid engiene api, returning 1\n")
                return 1
        end
 
        if (string.sub(str,1,2) == "t_") then -- ��t_��ͷ�ģ�Ϊtarget��API����
                local apiFunc = string.sub(str,3,string.len(str))
                if (target[apiFunc]) then
                        if (type(target[apiFunc]) == "function") then
                                return target[apiFunc](target)
                        end
                end
                Warning("DamageSystem.lua throws an error: "..str.." is not a valid engiene api\nDID YOU FORGET THE \"s_\" or \"t_\"\n this operand is returning 1\n")
                return 1
        end
 
        if (string.sub(str,1,1) == "%") then -- ��%��ͷ�ģ���ôȥ�Ӽ��ܻ�ȡSpecialValue
                local specialString = string.sub(str,2,string.len(str))
                return ability:GetLevelSpecialValueFor(specialString, ability:GetLevel() - 1)
        end
        -- ��Ȼ�׳�һ�����󷵻�1
        Warning("DamageSystem.lua throws an error: "..str.." is not a valid format, returning 1")
        return 1
end
 
-- �����˺���ֵ�ĺ���
local function CalculateDamage(source, target , ability, formula, formated_formula)
        local vOperandList = {}
        local fOperand1 = nil
        local fOperand2 = nil
         
        formated_formula = stringReplace(formated_formula," ", "")
        local vOperand = stringSplit(formated_formula,"|")
         
        for i = 1, #vOperand do
                -- ֻҪ����������ģ���ô��ȥ��ȡ�������ֵ
                if (isOperand(vOperand[i])) then
                        vOperandList[#vOperandList + 1] = getNumber(source, target, ability, vOperand[i])
                        print("getNumber result for ".. vOperand[i].." is "..getNumber(source, target, ability, vOperand[i]))
                else
                        -- ������������һ����������ջ����
                        fOperand2 = tonumber(vOperandList[#vOperandList])
                        vOperandList[#vOperandList] = nil
                        fOperand1 = tonumber(vOperandList[#vOperandList])
                        vOperandList[#vOperandList] = nil
                        if (fOperand1 == nil or fOperand2 == nil) then
                                Warning("MATH ERROR! ExpressionError! The fomular is:" .. formula, "returning nil")
                                return nil
                        end
                        vOperandList[#vOperandList + 1] = calculate(fOperand1,fOperand2,vOperand[i])
                end
        end
 
        -- ���ظ��ڵ�
        return vOperandList[1]
end
 
vDamage = {}
local vDamage = vDamage
setmetatable(vDamage, vDamage)
 
vDamage.damage_mt = {
        __index = {
                attacker = nil,
                victim = nil,
                damage = 0,
                damage_type = DAMAGE_TYPE_PURE,
                damage_flags = 0
        }
}
 
-- �˺�����
function Damage(keys)
        -- �˺���Դ��ʩ���ߣ���Ŀ���б�����ʽ������
        local source = keys.caster
        local targets = keys.target_entities
        local formula = keys.formula
        local ability = keys.ability
        if not (source and targets and ability and formula and #targets > 0) then return end
         
        local damage = keys
 
        setmetatable(damage, vDamage.damage_mt)
 
        damage.attacker = source
        damage.damage_type = _G[damage.Type] or damage.Type
 
        local nDamageFlags = 0
        if damage.Flags and type(damage.Flags) == "string" then
                local sDamageFlags = stringReplace(damage.Flags," ","")
                local vDamageFlags = stringSplit(sDamageFlags,"|")
                for _,flag in pairs(vDamageFlags) do
                        nDamageFlags = nDamageFlags + (_G[flag] or 0)
                end
        end
 
        damage.damage_flags = nDamageFlags
 
        -- ������ʽת��Ϊ������ʽ
        local formated_formula = CalculateParenthesesExpression(formula)
         
        for _, target in pairs(targets) do
                if target:IsAlive() then
                        damage.victim = target
                        -- ���ݺ�����ʽ�����˺���ֵ
                        damage.damage = CalculateDamage(source, target, ability, formula, formated_formula)
                        print("DamageSystem: damage calculation result is:", damage.damage)
                        print("DamageSystem: damage type is:".. damage.damage_type)
                        if (damage.damage ~= nil and damage.damage ~= 0) then
                                local damage_dealt = ApplyDamage(damage)
                                print("DamageSystem: Damage dealt to target ".. target:GetUnitName() .. " is "..damage_dealt)
                        end
                end
        end
end
 
 
function CDOTA_BaseNPC:GetAP()
        return self.__ap or 100
end
 
function CDOTA_BaseNPC:SetAP(value)
        self.__ap = value
end