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