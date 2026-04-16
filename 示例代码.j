//启动天灾
call Skill.StarDisaster(GetTriggerUnit(),GetOrderPointX(), GetOrderPointY(),ProjectileBack.GetDisaster)

//天灾坐标捕获______________________________
function GetDisaster takes unit hero, unit u, integer ID, real x, real y returns nothing 
    if ID == 'AX13' then
        call BJDebugMsg("飓风击中敌人名称为："+GetUnitName(u)+"击中来源为："+GetUnitName(hero))
    endif
    if ID == 'AC13' then
        call BJDebugMsg("陨石击中了！在目标位置创建了一个科多兽特效")
        call DestroyEffect(AddSpecialEffect("units\\orc\\KotoBeast\\KotoBeast.mdx",x,y))
    endif
    if ID == 'AD13' then
        call BJDebugMsg("闪电击中了！在目标位置创建了一个科多兽特效")
        call DestroyEffect(AddSpecialEffect("units\\orc\\KotoBeast\\KotoBeast.mdx",x,y))
    endif
endfunction

//启动能量爆发
call Skill.StarEnergyBurst(GetTriggerUnit(),GetOrderPointX(), GetOrderPointY(),ProjectileBack.GetEnergyBurst)
//能量爆发敌人捕获______________________________
function GetEnergyBurst takes unit hero, unit u, integer ID, real x, real y returns nothing 
    //A014为直线伤害，A015为大范围爆炸伤害。
    if ID == 'A014' then
        call BJDebugMsg("能量爆发击中敌人名称为："+GetUnitName(u)+"击中来源为："+GetUnitName(hero))
    endif
    if ID == 'A015' then
        call BJDebugMsg("爆炸中敌人名称为："+GetUnitName(u)+"击中来源为："+GetUnitName(hero))
    endif
endfunction

//启动扇形尖刺
call Skill.StarSpikes(GetTriggerUnit(),GetOrderPointX(), GetOrderPointY(),ProjectileBack.GetSpikes)
//扇形尖刺敌人捕获______________________________
function GetSpikes takes unit hero, unit u, integer ID, real x, real y returns nothing 
    if ID == 'A016' then
        call BJDebugMsg("尖刺击中敌人名称为："+GetUnitName(u)+"击中来源为："+GetUnitName(hero))
    endif
endfunction