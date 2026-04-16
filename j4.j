library MyToollibrary initializer setorigin
    globals
        private hashtable Hash= InitHashtable()
        private timer T = CreateTimer() 
        private integer Count = 0       
        private Projectile array ALL
        //判断变量
        private boolexpr filter = null
        private boolexpr Groupfilter = null
        private boolexpr SametypeID = null
        private unit filterunit = null
        private player filterplayer = null
        private integer filterID = 0
        //区域变量
        private region map 
        //设置哈希表字符____________
        private integer Invincible_t = StringHashBJ("Invincible")
        private integer hero_t = StringHashBJ("hero")
        private integer existinggroup_t = StringHashBJ("existinggroup")
        private integer Projectileloop_t = StringHashBJ("Projectileloop")
        private integer Z_shapedSlash_t = StringHashBJ("Z_shapedSlash")
        private integer CircularBlood_t = StringHashBJ("CircularBlood")
    endglobals

    function interface ProjectileBack takes unit hero, unit u, integer ID, real x, real y returns nothing

    function stsound takes unit u, string s1 returns nothing
        local sound s = CreateSound(s1, false, false, true, 5, 5, "Default")
        local real x = GetUnitX(u)
        local real y = GetUnitY(u)
        call SetSoundPosition(s, x, y, 0)
        call SetSoundVolume(s, 127)
        call StartSound(s)
        call KillSoundWhenDone(s)
        set u = null
        set s = null
    endfunction

    function Invincible takes unit u ,boolean t returns nothing
        call SetUnitInvulnerable( u, t )
        call SaveBoolean(Hash,GetHandleId(u), Invincible_t,t)
    endfunction
     
    function Setplayerheroes takes player p returns nothing
        local unit u
        //set u = CreateUnit( p, 'Hamg',GetUnitX(gg_unit_ngme_0026), GetUnitY(gg_unit_ngme_0026),0 )
        //call SaveUnitHandle(Hash,GetPlayerId(p),hero_t,u)
        set u = null
    endfunction

    function angleUnits takes unit u1, unit u2 returns real
        return bj_RADTODEG * Atan2(GetUnitY(u2) - GetUnitY(u1), GetUnitX(u2) - GetUnitX(u1))
    endfunction

    function IsPointInRange takes real x1, real y1, real x2, real y2, real range returns boolean
        local real dx = x2 - x1
        local real dy = y2 - y1
        return (dx * dx + dy * dy) <= (range * range)
    endfunction

    function GetAngleBetween takes real x1, real y1, real x2, real y2 returns real
        return bj_RADTODEG * Atan2(y2 - y1, x2 - x1)
    endfunction

    function GetDistance takes real x1, real y1, real x2, real y2 returns real
        local real dx = x2 - x1
        local real dy = y2 - y1
        return SquareRoot(dx * dx + dy * dy)
    endfunction

    function moveunit takes unit u, unit target, real dist returns nothing
        local real x = GetUnitX(u)
        local real y = GetUnitY(u)
        local real angle = Atan2(GetUnitY(target) - y, GetUnitX(target) - x) -180
        call SetUnitX(u, x + dist * Cos(angle))
        call SetUnitY(u, y + dist * Sin(angle))
    endfunction

    function shareMoney takes player p returns nothing

    endfunction

    public function HasItem takes unit u, integer id returns item
        local integer i = 0
        loop
            exitwhen i >= 6
            if GetItemTypeId(UnitItemInSlot(u, i)) == id then
                return UnitItemInSlot(u, i)
            endif
            set i = i + 1
        endloop              
        return null
    endfunction

    struct setGroup
        real grouptype
        static method Sametypetrue takes nothing returns boolean
            local unit u1 = GetFilterUnit()
            local boolean result = filterplayer == GetOwningPlayer(u1) and GetUnitState(u1, UNIT_STATE_LIFE) > 1.00 and not IsUnitHiddenBJ(u1) and filterID == GetUnitTypeId(u1)
            set u1 = null
            return result
        endmethod

        static method filterEnemy takes nothing returns boolean
            local unit u1 = GetFilterUnit()
            local boolean result = IsUnitEnemy(u1, GetOwningPlayer(filterunit)) and GetUnitState(u1, UNIT_STATE_LIFE) > 1.00 and not IsUnitHiddenBJ(u1) and GetUnitAbilityLevel(u1, 'Avul') == 0
            set u1 = null
            return result
        endmethod

        static method Groupenemy takes nothing returns boolean
            local unit u1 = GetFilterUnit()
            local group g = LoadGroupHandle(Hash, GetHandleId(filterunit), existinggroup_t)
            local boolean result = IsUnitEnemy(u1, GetOwningPlayer(filterunit)) and GetUnitState(u1, UNIT_STATE_LIFE) > 1.00 and not IsUnitHiddenBJ(u1) and GetUnitAbilityLevel(u1, 'Avul') == 0 and IsUnitInGroup(u1, g) == false
            call GroupAddUnit(g, u1)
            set u1 = null
            set g = null
            return result
        endmethod

        static method DeleteGroupUnit takes group g returns group
            local unit  u
            loop
                set u = FirstOfGroup(g)
                exitwhen u == null
                call RemoveUnit(u)
                call GroupRemoveUnit(g, u)
            endloop
            set u = null
            return g
        endmethod

        static method Sametype takes player p, real r, real x, real y,integer i returns group
            local group g = CreateGroup()
            set filterplayer = p
            set filterID = i
            call GroupEnumUnitsInRange(g,x,y,r,SametypeID)
            set filterID = 0
            set filterplayer = null
            return g
        endmethod

        static method Hostile takes unit u, real r, real x, real y,real z returns group
            local group g = CreateGroup()
            set filterunit = u
            if z == 1 then
                call GroupEnumUnitsInRange(g,x,y,r,Groupfilter)
            else
                call GroupEnumUnitsInRange(g,x,y,r,filter)
            endif
            //call BJDebugMsg(I2S(CountUnitsInGroup(g)))
            set u = null
            set filterunit = null
            return g
        endmethod
        //返回单个敌人
        static method BackEnemy takes unit u,unit hero,integer ID, real range, real x, real y,ProjectileBack cb returns nothing
            local group g = Hostile(u,range,x,y,1)
            local unit  u1
            loop
                set u1 = FirstOfGroup(g)
                exitwhen u1 == null
                call GroupRemoveUnit(g, u1)
                if u1 != null then
                    call cb.evaluate(hero, u1, ID, x, y)
                endif
            endloop
            call DestroyGroup(g)
            set u = null
            set g = null
        endmethod

        //返回直线范围敌人
        static method LineEnemy takes unit u, unit hero, integer ID, real startX, real startY, real targetX, real targetY, real radius, ProjectileBack cb returns nothing
            local real angle = GetAngleBetween(startX, startY, targetX, targetY)
            local real dist = GetDistance(startX, startY, targetX, targetY)
            local real step = radius * 0.75 
            local real currentDist = 0
            local real x
            local real y
            local group g = LoadGroupHandle(Hash, GetHandleId(u), existinggroup_t)
            local boolean isNewGroup = false
            if GetHandleId(g) == 0 then
                set g = CreateGroup()
                call SaveGroupHandle(Hash, GetHandleId(u), existinggroup_t, g)
                set isNewGroup = true
            endif
            loop
                exitwhen currentDist > dist
                set x = startX + currentDist * Cos(angle * bj_DEGTORAD)
                set y = startY + currentDist * Sin(angle * bj_DEGTORAD)
                call setGroup.BackEnemy(u, hero, ID, radius, x, y, cb)
                set currentDist = currentDist + step
            endloop
            set x = startX + dist * Cos(angle * bj_DEGTORAD)
            set y = startY + dist * Sin(angle * bj_DEGTORAD)
            call setGroup.BackEnemy(u, hero, ID, radius, x, y, cb)
            if isNewGroup then
                call DestroyGroup(g)
                call RemoveSavedHandle(Hash, GetHandleId(u), existinggroup_t)
            else
                call GroupClear(g)
            endif
            set g = null
        endmethod

        static method damagegroup takes unit u, real range, real x, real y, string s, real d, boolean t, attacktype at, damagetype dt, weapontype wt, group g1 returns nothing
            local unit u1
            local group g 
            if GetHandleId(g1) > 0 then
                set g = g1
            else
                set g = Hostile(u,range,x,y,0)
            endif
            if StringLength(s) > 0 then
                call DestroyEffect(AddSpecialEffect(s,x,y))
            else
            endif
            if CountUnitsInGroup(g) > 0 then
                loop
                    exitwhen CountUnitsInGroup(g) == 0
                    set u1 = FirstOfGroup(g)
                    call GroupRemoveUnit(g, u1)
                    call UnitDamageTarget(u, u1, d, t, false, at, dt, wt)
                endloop
            else
            endif
            call DestroyGroup(g)
            set g =null
            set g1 =null
            set u = null
            set u1 = null
        endmethod

        static method GetSingleEnemy takes unit u, real r returns unit
            local group g = Hostile(u, r, GetUnitX(u), GetUnitY(u), 0) 
            local unit target = FirstOfGroup(g)
            call DestroyGroup(g) 
            set g = null
            return target
        endmethod

        static method sgroup takes unit u, real damage, real x, real y,real range,real explosionrange returns boolean
            local boolean result
            local group g = Hostile(u,range,x,y,1)
            if CountUnitsInGroup(g) > 0 then
                set result=true
            else
                set result=false
            endif
            if explosionrange > 0 and result==true then
                call DestroyGroup(g)
                set g =null
            else
            endif
            call damagegroup(u,explosionrange-range,x,y,"",damage,false, ATTACK_TYPE_HERO, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_METAL_MEDIUM_SLICE,g)
            set g =null
            return result
        endmethod
    endstruct

    struct LensSettings
        player p
        real r
        timer t
        integer i 
        static method EndOfShaking takes nothing returns nothing
            local thistype d = LoadInteger(Hash, GetHandleId(GetExpiredTimer()), 0)
            loop 
                exitwhen d.i == 8
                call CameraClearNoiseForPlayer( Player(d.i) )
                set d.i = d.i + 1
            endloop
            set d.i = 0
            call FlushChildHashtable(Hash, GetHandleId(d.t))
            call DestroyTimer(d.t)
            call d.destroy()
        endmethod
    
        static method ShakyCamera takes real r, real endtime returns nothing
            local thistype d = thistype.allocate()
            loop 
                exitwhen d.i == 8
                call CameraSetEQNoiseForPlayer( Player(d.i), r )
                set d.i = d.i + 1
            endloop
            set d.i = 0
            set d.r = r
            set d.t = CreateTimer()
            call SaveInteger(Hash, GetHandleId(d.t), 0, d)
            call TimerStart(d.t, endtime, false, function thistype.EndOfShaking)
        endmethod
    endstruct

    struct DelayedSkill
        unit u
        unit u1
        string order
        real tx
        real ty
        timer t
    
        static method ending takes nothing returns nothing
            local thistype d = LoadInteger(Hash, GetHandleId(GetExpiredTimer()), 0)
            if d.u1 == null then
                call IssuePointOrder(d.u, d.order, d.tx, d.ty)
            else
                call IssueTargetOrder( d.u,d.order, d.u1 )
            endif
            call FlushChildHashtable(Hash, GetHandleId(d.t))
            call DestroyTimer(d.t)
            call d.destroy()
        endmethod
    
        static method Delayed takes unit u, string order, real tx, real ty, real delay returns nothing
            local thistype d = thistype.allocate()
            set d.u = u
            set d.u1 = null
            set d.order = order
            set d.tx = tx
            set d.ty = ty
            set d.t = CreateTimer()
            call SaveInteger(Hash, GetHandleId(d.t), 0, d)
            call TimerStart(d.t, delay, false, function thistype.ending)
        endmethod
        static method Delayedunit takes unit u, string order, unit u1, real delay returns nothing
            local thistype d = thistype.allocate()
            set d.u = u
            set d.u1 = u1
            set d.order = order
            set d.t = CreateTimer()
            call SaveInteger(Hash, GetHandleId(d.t), 0, d)
            call TimerStart(d.t, delay, false, function thistype.ending)
        endmethod
    endstruct

    struct Projectile
        unit u
        unit hero
        real originx
        real originy
        real nextx
        real nexty
        real distance
        real speed
        real InitialSpeed
        real moved
        real damage
        real angle
        real range
        real explosionrange
        real killu
        real TargetHeight
        real CurrentHeight
        real StartHeight
        string e
        real ecount
        integer SkillID
        ProjectileBack cb
        method destroy takes nothing returns nothing
            call RemoveSavedInteger(Hash, GetHandleId(this.u), Projectileloop_t)
            call DestroyGroup(LoadGroupHandle(Hash, GetHandleId(this.u), existinggroup_t))
            call RemoveSavedHandle(Hash, GetHandleId(this.u),existinggroup_t)
            set this.u = null
            set this.cb = 0
            set this.TargetHeight = 0
            call this.deallocate()
        endmethod

        static method Projectileloop takes nothing returns nothing
            local Projectile d
            local integer i = 0
            local boolean result
            local unit u
            local unit hero
            local integer SkillID
            local real x
            local real y
            loop
                exitwhen i>=Count
                set d =ALL[i]
                set d.moved=d.moved+d.speed
                set d.nextx = d.originx + d.moved * Cos(d.angle * bj_DEGTORAD)
                set d.nexty = d.originy + d.moved * Sin(d.angle * bj_DEGTORAD)
                if d.TargetHeight != -1 and d.distance > 0 then
                    //set d.CurrentHeight = d.CurrentHeight + (d.TargetHeight - d.CurrentHeight) * (d.moved / d.distance)
                    set d.CurrentHeight = d.StartHeight + (d.TargetHeight - d.StartHeight) * (d.moved / d.distance)
                    call SetUnitFlyHeight(d.u,d.CurrentHeight, 0)
                endif
                if d.moved>=d.distance or GetUnitState(d.u, UNIT_STATE_LIFE) <= 0 or  IsPointInRegion(map, d.nextx, d.nexty) == false  then
                    set u = d.u
                    set hero = d.hero
                    set SkillID = d.SkillID
                    set x = d.nextx
                    set y = d.nexty

                    if d.cb != 0 and d.damage <= 0 then
                        call d.cb.evaluate(d.hero, d.u, d.SkillID, d.nextx, d.nexty)
                    endif
                    if GetUnitUserData(d.u) == 50 then
                        call KillUnit(d.u)
                    endif
                    call d.destroy()
                    call Skill.MoveCallBack(u,hero,SkillID,x,y)
                    set Count = Count - 1
                    set ALL[i] = ALL[Count]
                    set i = i - 1
                    if Count == 0 then
                        call PauseTimer(T)
                    endif
                else
                    //call BJDebugMsg(R2S(d.angle))
                    call SetUnitX(d.u,d.nextx)
                    call SetUnitY(d.u,d.nexty)
                    if StringLength(d.e) > 0 then
                        if d.ecount == 5 then
                            set d.ecount=0
                            call DestroyEffect(AddSpecialEffect(d.e,d.nextx,d.nexty))
                        else
                            set d.ecount=d.ecount+1
                        endif
                    else
                    endif 
                    if d.damage > 0 then
                        if d.cb != 0 then
                            call setGroup.BackEnemy(d.u,d.hero,d.SkillID,d.range,d.nextx,d.nexty,d.cb)
                        else
                            set result=setGroup.sgroup(d.u,d.damage,d.nextx,d.nexty,d.range,d.explosionrange)
                            if result == true and  d.killu == 1 then
                                call KillUnit(d.u)
                            endif
                        endif
                    endif
                endif
                set i=i+1
            endloop
            set u = null
            set hero = null
        endmethod

        static method SetMove takes unit u, real distance, real speed, real damage, real range,real angle,real explosionrange, real killu,string e, real TargetHeight ,integer SkillID,unit hero,ProjectileBack cb returns nothing
            local thistype d = LoadInteger(Hash, GetHandleId(u), Projectileloop_t)
            local group g = LoadGroupHandle(Hash, GetHandleId(u), existinggroup_t)
            if d != 0 then
            else
                set d=thistype.allocate()
                set ALL[Count]=d
                set Count=Count+1
            endif
            set d.cb = cb
            set d.u=u
            set d.hero = hero
            set d.speed=speed
            set d.InitialSpeed = d.speed
            set d.damage=damage
            set d.originx=GetUnitX(u)
            set d.originy=GetUnitY(u)
            set d.angle=angle
            set d.distance=distance
            set d.range=range
            set d.explosionrange=explosionrange
            set d.killu=killu
            set d.e=e
            set d.SkillID = SkillID
            set d.TargetHeight = TargetHeight
            set d.CurrentHeight = GetUnitFlyHeight(d.u)
            set d.StartHeight = d.CurrentHeight
            set d.moved = 0
            call SaveInteger(Hash, GetHandleId(u), Projectileloop_t, d)
            if GetHandleId(g) == 0 and damage > 0 then
                call SaveGroupHandle(Hash, GetHandleId(u), existinggroup_t,CreateGroup())
            else
            endif
            if Count == 1 then
                call TimerStart(T, 0.01, true, function thistype.Projectileloop)
            endif
            set g = null
        endmethod

        static method GetUnitInstance takes unit u returns Projectile
            return LoadInteger(Hash, GetHandleId(u), Projectileloop_t)
        endmethod

        static method SetMoveSpeed takes unit u,real r returns nothing
            local Projectile d = GetUnitInstance(u)
            if d != 0 then
                set d.speed = r
            endif
        endmethod

        static method GetMoveSpeed takes unit u returns real
            local Projectile d = GetUnitInstance(u)
            if d != 0 then
                return d.speed
            endif
            return 0.0
        endmethod

        static method GetUnitAngle takes unit u returns real
            local Projectile d = GetUnitInstance(u)
            if d != 0 then
                return d.angle
            endif
            return 0.0
        endmethod

        static method SetUnitAngle takes unit u,real r returns nothing
            local Projectile d = GetUnitInstance(u)
            if d != 0 then
                set d.angle = r
            endif
        endmethod
        
        static method GetTargetHeight takes unit u returns real
            local Projectile d = GetUnitInstance(u)
            if d != 0 then
                return d.TargetHeight
            endif
            return 0.0
        endmethod

        static method SetTargetHeight takes unit u,real r returns nothing
            local Projectile d = GetUnitInstance(u)
            if d != 0 then
                set d.TargetHeight = r
            endif
        endmethod

        static method GetPointMoveGroup takes real x, real y, real r returns group
            local group g = CreateGroup()
            local integer i = 0
            local Projectile d
            loop
                exitwhen i >= Count 
                set d = ALL[i]
                if IsPointInRange(d.nextx,d.nexty,x,y,r) == true then
                    call GroupAddUnit(g, d.u)
                endif
                set i = i + 1
            endloop
            return g
        endmethod

    endstruct

    struct Skill
        timer t
        unit u
        unit ua
        unit ub
        effect ef
        lightning l
        real AF
        real AFmax
        real AFConstant
        real Change
        real array thetime[20]
        real x
        real y
        real nx
        real ny
        real z
        real high
        real speed
        real i
        real ID = 0
        real CheckID = 0
        real SignalID = 0
        real SpecialID
        real nextx
        real nexty
        real angle
        real distance
        real CurrentSize
        real initialSize
        real TargetSize
        real SpeedSize
        real array AnimationMax[20] 
        real array Animationspeed[20]
        integer array AnimationID[20]
        integer Countid
        real max
        integer SkillID
        real array TheDestroy[5]
        ProjectileBack cb

        method DestroyAndTimer takes timer t returns nothing
            call FlushChildHashtable(Hash, GetHandleId(t))
            call DestroyTimer(t)
            set this.ID = 0
            set this.Countid = 0
            set this.CheckID = 0
            set this.i = 0
            set this.max = 0
            set this.speed = 0
            set this.high = 0
            set this.z = 0
            set this.cb = 0
            set this.u = null
            set this.ua = null
            set this.ub = null
            call this.deallocate()
        endmethod
        
        //缩放,透明,动画速度三合一的函数,在三者都处理完之后再结束计时.
        static method AnimationFades takes nothing returns nothing
            local timer t = GetExpiredTimer()
            local thistype c =LoadInteger(Hash, GetHandleId(t), 0)
            //处理缩放的部分
            if c.TargetSize > 0 and c.CurrentSize != c.TargetSize then
                if c.initialSize > c.TargetSize then
                    if c.CurrentSize < c.TargetSize then
                        set c.CurrentSize = c.TargetSize
                    else
                        set c.CurrentSize = c.CurrentSize - c.SpeedSize
                    endif
                else
                    if c.CurrentSize > c.TargetSize then
                        set c.CurrentSize = c.TargetSize
                    else
                        set c.CurrentSize = c.CurrentSize + c.SpeedSize
                    endif
                endif
                call SetUnitScalePercent( c.ua, c.CurrentSize, c.CurrentSize, c.CurrentSize )
            endif
            //处理动画速度的部分
            if c.Countid > 0 then
                if c.AnimationMax[c.Countid] > 0 then
                    set c.AnimationMax[c.Countid] = c.AnimationMax[c.Countid] - c.Animationspeed[c.Countid] 
                    call SetUnitTimeScalePercent(c.ua,c.AnimationMax[c.Countid])
                endif
            endif
            //处理单位透明度的部分
            if c.AF <= c.AFmax then
                set c.AF = -999
                set c.AFmax = c.AFmax - c.AFConstant
                if c.Change == 1 then
                else
                    call SetUnitVertexColorBJ( c.ua, 100, 100, 100, 100-c.AFmax )
                endif
                //call BJDebugMsg("透明度为："+R2S(100 - c.AFmax))
            else
                set c.AF = c.AF - c.AFConstant
                if c.Change == 1 then
                else
                    call SetUnitVertexColorBJ( c.ua, 100, 100, 100, c.AF )
                endif
            endif
            //计算缩放是否完成
            if c.TargetSize > 0 then
                if c.CurrentSize == c.TargetSize then
                    set c.TheDestroy[1] = 1
                endif
            else
                set c.TheDestroy[1] = 1
            endif
            //计算透明是否完成
            if c.AFConstant != 0 then
                if c.AFmax <= 0 then
                    set c.TheDestroy[2] = 1
                endif
            else
                set c.TheDestroy[2] = 1
            endif
            //计算动画速度是否完成
            if c.Countid > 0 then
                if c.AnimationMax[c.Countid] == 0 then
                    set c.TheDestroy[3] = 1
                endif
            else
                set c.TheDestroy[3] = 1
            endif
            //结束部分
            if c.TheDestroy[1] == 1 and c.TheDestroy[2] == 1 and c.TheDestroy[3] == 1 then
                set c.TargetSize = 0
                set c.AFConstant = 0
                set c.TheDestroy[1] = 0
                set c.TheDestroy[2] = 0
                set c.TheDestroy[3] = 0
                set c.Change = 0
                call c.DestroyAndTimer(t)
                //call BJDebugMsg("结束运行")
            endif
        endmethod

        //创建单位的函数 
        static method IllusionCreation takes player p , string s, real x ,real y ,real a,real Size, real transparency, real Duration,integer Animation,real AnimationSpeed  returns unit
            local unit u = CreateUnit(p,'ewsp',x,y,a)
            call DzSetUnitModel( u, s )
            call SetUnitScalePercent( u, Size, Size, Size )
            call SetUnitVertexColorBJ( u, 100, 100, 100, transparency )
            call UnitApplyTimedLife( u, 'BHwe', Duration )
            if Animation != -1 then
                call SetUnitAnimationByIndex( u, Animation )
            endif
            call SetUnitTimeScalePercent(u,AnimationSpeed)
            return u
        endmethod

        static method MoveCallBack takes unit u, unit hero, integer ID ,real x ,real y returns nothing
            local thistype d 
            if ID == 'A005' then
                set d = LoadInteger(Hash, GetHandleId(u), Z_shapedSlash_t)
                if d != 0 and d.i > 0 then
                    call d.Z_ShapedSlash()
                endif
            endif
            if ID == 'A007' then
                call DestroyEffect(AddSpecialEffect("war3mapimported\\buff_dw186.mdx",x,y))
            endif
            if ID == 'A011' then
                set d = LoadInteger(Hash, GetHandleId(u), CircularBlood_t)
                if d != 0  and d.ID > 0 then
                    call d.MoveRingSword()
                endif
            endif
            if ID == 'A012' and GetUnitTypeId(u) == 'ewsp' and GetUnitUserData(u) != 50 then
                call RemoveUnit(u)
            endif
        endmethod


        //让单位动画按不同的世界播放的函数,使用计时器回调的方法
        static method next takes nothing returns nothing
            local timer t1 = GetExpiredTimer()
            local timer t2 
            local timer t3 
            local thistype d = LoadInteger(Hash, GetHandleId(t1), 0)
            local thistype c
            local thistype e
            //call BJDebugMsg(I2S(d.Countid) + "运行编号")
            if d.Countid == d.max and d.CheckID == 0 then
                call d.DestroyAndTimer(t1)
            else
                //播放单位动画______________________________________________________
                if d.Countid <= d.max then
                    set d.Countid=d.Countid+1
                    call SetUnitTimeScalePercent(d.u,d.Animationspeed[d.Countid])
                    if d.AnimationID[d.Countid] == -1 and d.AnimationID[d.Countid] != 0 then
                    else
                        call SetUnitAnimationByIndex(d.u,d.AnimationID[d.Countid])
                    endif
                    if d.Countid == 0 then
                        call SetUnitAnimationByIndex(d.u,d.AnimationID[d.Countid])
                        call SetUnitTimeScalePercent(d.u,d.Animationspeed[d.Countid])
                    else
                    endif
                endif
                //__________________________________________________________________
                //call BJDebugMsg(I2S(d.AnimationID[d.Countid])+"and"+R2S(d.Animationspeed[d.Countid]))
                if d.CheckID == 0 then
                    call TimerStart(d.t, d.thetime[d.Countid], false, function thistype.next)
                endif
            endif
            set t1 = null
        endmethod

        //哥斯拉的原子吐息
        static method EnergyCondensation takes nothing returns nothing
            local timer t = GetExpiredTimer()
            local timer t1 
            local thistype d = LoadInteger(Hash, GetHandleId(t), 0)
            local thistype c
            local real r_xy
            local real angle
            local real radius = 600
            local unit u
            //call BJDebugMsg(R2S(d.i))
            //销毁
            if d.i >= 120 then
                set d.i = 0
                call KillUnit(d.ua)
                set d.ua = null
                call d.DestroyAndTimer(t)
            else
                set d.i = d.i + 1
                //创建特效
                if d.i == 10 then
                    set d.ua = IllusionCreation(GetOwningPlayer(d.u), "war3mapimported\\buff_yuanqidan.mdl", d.x, d.y, 0,100 * d.initialSize,0,10,-1,100)
                    call SetUnitFlyHeight(d.ua, 600, 0)
                endif
                //执行中端特效的部分
                if d.i == 40 then
                    call LensSettings.ShakyCamera(5,8 * d.thetime[1])
                    call KillUnit(d.ua)
                    set d.ua = null
                    set c = thistype.allocate()
                    set c.ua = IllusionCreation(GetOwningPlayer(d.u),"war3mapimported\\buff_vamy-yc_bluesmokecircle-900.mdl",GetUnitX(d.u),GetUnitY(d.u),GetUnitFacing(d.u),10 * d.thetime[1],0,9,-1,100)
                    set c.AFmax = 0
                    set c.AF = 0
                    set c.AFConstant = 0
                    set c.initialSize = 100
                    set c.CurrentSize = 15
                    set c.TargetSize = 400
                    set t1 = CreateTimer()
                    call SaveInteger(Hash, GetHandleId(t1),0, c)
                    call TimerStart(t1, 0.04, true, function thistype.AnimationFades)
                endif
                //执行吐息的部分
                if d.i > 40 then
                    set d.ID = d.ID + 1
                    set d.nextx = d.x + d.distance * Cos(d.angle * bj_DEGTORAD)
                    set d.nexty = d.y + d.distance * Sin(d.angle * bj_DEGTORAD)
                    set d.distance = d.distance + ( 40 + d.speed)
                    if d.distance > 3000 then
                        set d.i = 120
                    endif
                    if d.ID == 3 then
                        set d.ID = 0
                        set d.ef = AddSpecialEffect("blink gold target.mdx",d.x,d.y)
                        call EXSetEffectZ( d.ef, 410 + d.high )
                        call DestroyEffect(d.ef)
                        set d.ef = null
                    endif
                    set u = IllusionCreation(GetOwningPlayer(d.u), "prismbeam_master.mdl", d.x, d.y, 0,200 * d.initialSize,0,2,-1,100)
                    call SetUnitFlyHeight(u, 570 + d.high, 0)
                    call SetUnitUserData(u,50)
                    call Projectile.SetMove(u,d.distance,30,0,0,d.angle,0,0,"",0,'A001',d.u,d.cb)
                    call SaveUnitHandle(Hash,GetHandleId(u),hero_t,d.u)
                    set u = null
                    set u = IllusionCreation(GetOwningPlayer(d.u), "void arrow.mdl", d.x, d.y, d.angle,150 * d.initialSize,0,2,-1,100)
                    call SetUnitFlyHeight(u, 570 + d.high, 0)
                    call SetUnitUserData(u,50)
                    call Projectile.SetMove(u,d.distance,30,0,0,d.angle,0,0,"",0,'A000',d.u,0)
                    call TimerStart(t, 0.1, false, function thistype.EnergyCondensation)
                    //计时器回调,但是可以不用回调,因为这个技能的每一次时间都是固定0.1秒
                else
                    //执行能量聚集的部分
                    if d.i > 10 and d.i < 40 then
                        call SetUnitScalePercent( d.ua, 200+(d.i*10), 200+(d.i*10), 200+(d.i*10) )
                    endif
                    set d.z = GetRandomReal(-radius, radius)
                    set r_xy = SquareRoot(radius * radius - d.z * d.z)
                    set angle = GetRandomReal(0, 2 * bj_PI)
                    set d.nextx = d.x + r_xy * Cos(angle)
                    set d.nexty = d.y + r_xy * Sin(angle)
                    set u = IllusionCreation(GetOwningPlayer(d.u), "Abilities\\Weapons\\SpiritOfVengeanceMissile\\SpiritOfVengeanceMissile.mdl", d.nextx, d.nexty, 0,100 * d.initialSize,0,2,-1,100)
                    call SetUnitFlyHeight(u, 570 + d.high, 0)
                    call Projectile.SetMove(u,r_xy,4/d.thetime[1],0,0,(angle * bj_RADTODEG)+180,0,0,"",570 + d.high,'A000',d.u,0)
                    call SetUnitUserData(u,50)
                    call TimerStart(t, 0.1*d.thetime[1], false, function thistype.EnergyCondensation)
                endif
            endif
            set u = null
        endmethod

        //启动哥斯拉技能的函数,只需传入x,y,角度,单位
        static method Skill1 takes unit u, real x,real y,real high,real RelDist,real Size,real time ,real speed,ProjectileBack cb  returns nothing
            local thistype d
            set d=thistype.allocate()
            set d.cb = cb
            set d.u=u
            set d.t=CreateTimer() 
            set d.distance = 300
            set d.angle= GetAngleBetween(GetUnitX(u),GetUnitY(u),x,y)
            set d.x = GetUnitX(u) + RelDist * Cos(d.angle * bj_DEGTORAD)
            set d.y = GetUnitY(u) + RelDist * Sin(d.angle * bj_DEGTORAD)
            set d.initialSize = Size
            set d.high = high
            set d.thetime[1] = time 
            set d.speed = speed
            call SaveInteger(Hash, GetHandleId(d.t),0, d)
            call TimerStart(d.t, 0.01, false, function thistype.EnergyCondensation)
        endmethod

        //陨石
        static method meteorite takes nothing returns nothing
            local timer t = GetExpiredTimer()
            local thistype d = LoadInteger(Hash, GetHandleId(t), 0)
            local thistype c
            local unit u
            local real radius = GetRandomReal(200,300 + (d.max * 20))
            local real angle = d.i * 36.0
            set d.nextx = d.x + radius * Cos(angle * bj_DEGTORAD)
            set d.nexty = d.y + radius * Sin(angle * bj_DEGTORAD)
            if d.i >= d.ID and d.CheckID == 0 then
                call LensSettings.ShakyCamera(5,5)
                set u = CreateUnit(GetOwningPlayer(d.u),'e006',d.x+180*Cos(360 * bj_DEGTORAD),d.y+180*Sin(360 * bj_DEGTORAD),180)
                set d.CheckID = 1
                call SetUnitUserData(u,50)
                call SetUnitFlyHeight(u, 1500, 0)
                call Projectile.SetMove(u,500,d.speed*0.5,0,0,180,0,1,"",-150,'A002',d.u,d.cb)
            else
                set u = IllusionCreation(GetOwningPlayer(d.u), "war3mapImported\\buff_huoqiu.mdl", d.nextx,d.nexty, 180,40*GetRandomReal(0.7,1.3),0,4,-1,100)
                call SetUnitUserData(u,50)
                call SetUnitFlyHeight(u, 1500, 0)
                call Projectile.SetMove(u,500,d.speed*GetRandomReal(0.7,1.5),0,0,180,0,1,"",-150,'A003',d.u,d.cb)
            endif
            set d.i = d.i + 1
            set u = null
            if d.i >= d.max then
                call d.DestroyAndTimer(t)
            endif
            //call BJDebugMsg(R2S(d.i))
        endmethod

        //启动陨石的函数
        static method StartMeteorite takes unit u, real x,real y,real max,real time,real speed,ProjectileBack cb  returns nothing
            local thistype d
            set d=thistype.allocate()
            set d.cb = cb
            set d.u=u
            set d.t=CreateTimer() 
            set d.x = x + 500 * Cos(360 * bj_DEGTORAD)
            set d.y = y + 500 * Sin(360 * bj_DEGTORAD)
            set d.max = max
            set d.speed = speed
            set d.ID = max * 0.7
            call SaveInteger(Hash, GetHandleId(d.t),0, d)
            call TimerStart(d.t, time, true, function thistype.meteorite)
        endmethod

        //地震____________________
        static method Earthquake takes nothing returns nothing
            local integer i = 0
            local timer t1 = GetExpiredTimer()
            local timer t2 
            local integer points
            local real currentDist
            local thistype d = LoadInteger(Hash, GetHandleId(t1), 0)
            local thistype c 
            if d.SignalID == 0 then
                set currentDist = d.ID * 200.0
            else
                set currentDist = (d.max - d.SignalID ) * 200.0
            endif
            if currentDist < 100 then
                set points = 1 
            else
                set points = 6 + R2I(currentDist / 100.0) 
            endif
            loop
                exitwhen i == points
                set d.angle = (i * 360.0 / points) * bj_DEGTORAD
                if d.SignalID == 0 then
                    set d.nx = d.x + (d.ID * 200.0) * Cos(d.angle)
                    set d.ny = d.y + (d.ID * 200.0) * Sin(d.angle)
                else
                    set d.nx = d.x + ((d.max - d.SignalID) * 200.0) * Cos(d.angle)
                    set d.ny = d.y + ((d.max - d.SignalID )* 200.0) * Sin(d.angle)
                endif
                if d.SignalID == 0 then
                    call d.cb.evaluate(d.u, d.u, 'A004', d.nx, d.ny)
                else
                    call DestroyEffect(AddSpecialEffect("Objects\\Spawnmodels\\Undead\\ImpaleTargetDust\\ImpaleTargetDust.mdl",d.nx,d.ny))
                endif
                set i = i + 1
            endloop
            if d.SignalID == 0 and d.ID == 0 then
                //能量罩创建________________________________________________
                set c = thistype.allocate()
                set c.ua = IllusionCreation(GetOwningPlayer(d.u),"war3mapimported\\buff_vamy-yc_bluesmokecircle-900.mdx",d.x,d.y,GetUnitFacing(d.u),6,0,4,-1,100)
                set c.AFmax = 100
                set c.AF = 0
                set c.AFConstant = 1
                set c.Change = 1
                set c.initialSize = 10
                set c.CurrentSize = c.initialSize
                set c.TargetSize = 19 * d.max
                set c.SpeedSize = 4
                set t2 = CreateTimer()
                call SaveInteger(Hash, GetHandleId(t2),0, c)
                call TimerStart(t2, 0.04, true, function thistype.AnimationFades)
                set t2 = null
            endif
            if d.SignalID == 0 then
                set d.ID=d.ID + 1
            else
                set d.SignalID = d.SignalID - 1
            endif
            if d.ID == d.max then
                call d.DestroyAndTimer(t1)
            endif
            set t1 = null
        endmethod
        //启动地震的函数
        static method StarEarthquake takes unit u, real max,real x,real y,ProjectileBack cb  returns nothing
            local thistype d = thistype.allocate()
            set d.x = x
            set d.y = y
            set d.cb = cb
            set d.u = u
            set d.t = CreateTimer()
            set d.max = max
            set d.SignalID = max
            call SaveInteger(Hash, GetHandleId(d.t),0, d)
            call TimerStart(d.t, 0.2, true, function thistype.Earthquake)
        endmethod

        //z字斩
        method Z_ShapedSlash takes nothing returns nothing
            local real r
            local real r1
            if this.i == 0 then
                call RemoveSavedInteger(Hash, GetHandleId(this.u), Z_shapedSlash_t)
                call this.DestroyAndTimer(null)
            else
                set this.i = this.i - 1
                if this.i == 2 then
                    set r = 900
                endif
                if this.i == 1 then
                    set r = 1400
                    set this.angle = this.angle + 150
                endif
                if this.i == 0 then
                    set r = GetDistance(this.x,this.y,GetUnitX(this.u),GetUnitY(this.u))
                    set this.angle = GetAngleBetween(GetUnitX(this.u),GetUnitY(this.u),this.x,this.y)
                endif
                set r1 = r/2
                set this.nextx = GetUnitX(this.u) + r1 * Cos(this.angle * bj_DEGTORAD)
                set this.nexty = GetUnitY(this.u) + r1 * Sin(this.angle * bj_DEGTORAD)
                call DestroyEffect(AddSpecialEffect("war3mapimported\\buff_jianqikuozhang.mdx",GetUnitX(this.u),GetUnitY(this.u)))
                set this.ua = IllusionCreation(GetOwningPlayer(this.u), "war3mapimported\\buff_baici.mdl", this.nextx,this.nexty, this.angle,130,0,1,-1,100)
                set this.ub = IllusionCreation(GetOwningPlayer(this.u), "war3mapimported\\buff_az_hit-2.mdx", GetUnitX(this.u),GetUnitY(this.u), this.angle,130,0,1,-1,100)
                call Projectile.SetMove(this.u,r,55,0.5,100,this.angle,0,0,"",-1,'A005',this.u,this.cb)
            endif
        endmethod

        //启动z字斩
        static method StarZ_ShapedSlash takes unit u, real x,real y, integer ID,ProjectileBack cb returns nothing
            local thistype d = thistype.allocate()
            local real a = GetAngleBetween(GetUnitX(u),GetUnitY(u),x,y) 
            set d.u = u
            set d.x = GetUnitX(u) + 1100 * Cos(a * bj_DEGTORAD)
            set d.y = GetUnitY(u) + 1100 * Sin(a * bj_DEGTORAD)
            set d.angle = (a - 60) 
            set d.cb = cb
            set d.SkillID = ID
            set d.i = 3
            call SaveInteger(Hash, GetHandleId(u),Z_shapedSlash_t, d)
            call d.Z_ShapedSlash()
        endmethod

        //超级斩击
        static method SuperSlash takes nothing returns nothing
            local timer t = GetExpiredTimer()
            local thistype d = LoadInteger(Hash, GetHandleId(t), 0)
            local real timeA = 0.5
            local real x = GetUnitX(d.u)
            local real y = GetUnitY(d.u)
            local real i = 0
            local real a = 0
            local real loopmax = 0
            if d.i >= 51 then
                call SetUnitTimeScalePercent( d.u, 100.00)
                call ResetUnitAnimation( d.u)
                call d.DestroyAndTimer(t)
            else
                set d.i = d.i + 1
                if d.i == 1 or d.i == 2 or d.i == 4 or d.i == 20 or d.i == 35 or d.i == 50 then
                    call SetUnitAnimation( d.u, "attack")
                    call SetUnitTimeScalePercent( d.u, 150.00)
                endif
                if  d.i == 1 then
                    set timeA = 0.5
                    call DestroyEffect(AddSpecialEffect("war3mapimported\\buff_zj_hl.mdx",x,y))
                    set d.ub = IllusionCreation(GetOwningPlayer(d.u), "war3mapimported\\buff_dg_sword_hong.mdx", x,y, d.angle,130,0,5,-1,100)
                    call SetUnitUserData(d.ub,50)
                    call Projectile.SetMove(d.ub,1500,20,0.5,180,d.angle,0,0,"Abilities\\Spells\\Undead\\OrbOfDeath\\OrbOfDeathMissile.mdl",-1,'A006',d.u,d.cb)
                endif
                if d.i == 2 then
                    set timeA = 0.5
                    call DestroyEffect(AddSpecialEffect("war3mapimported\\buff_jianqikuozhang.mdx",x,y))
                    set d.ub = IllusionCreation(GetOwningPlayer(d.u), "war3mapimported\\buff_lansedaoguang.mdx", x,y, d.angle,230,0,5,-1,100)
                    call SetUnitUserData(d.ub,50)
                    call Projectile.SetMove(d.ub,1500,20,0.5,180,d.angle,0,0,"Abilities\\Weapons\\ChimaeraLightningMissile\\ChimaeraLightningMissile.mdl",-1,'A006',d.u,d.cb)
                endif
                if d.i == 3 then
                    set timeA = 1.5
                    set d.ub = IllusionCreation(GetOwningPlayer(d.u), "war3mapimported\\buff_leiyun.mdx", x,y, d.angle,500,0,8,-1,100)
                    set d.ub = IllusionCreation(GetOwningPlayer(d.u), "war3mapimported\\buff_gh_luojitiandao.mdl", x,y, d.angle,150,0,8,-1,100)
                endif
                if d.i == 4 then
                    set timeA = 1
                    loop
                        exitwhen i == 3
                        set a = d.angle + (30 * (i-1))
                        set d.nx = x + 200 * Cos(a * bj_DEGTORAD)
                        set d.ny = y + 200 * Sin(a * bj_DEGTORAD)
                        call DestroyEffect(AddSpecialEffect("war3mapimported\\buff_zj_hl.mdx",d.nx,d.ny))
                        set d.ub = IllusionCreation(GetOwningPlayer(d.u), "war3mapimported\\buff_dg_sword_hong.mdx", d.nx,d.ny, a,130,0,5,-1,100)
                        call SetUnitUserData(d.ub,50)
                        call Projectile.SetMove(d.ub,1500,20,0.5,180,a,0,0,"Abilities\\Spells\\Undead\\OrbOfDeath\\OrbOfDeathMissile.mdl",-1,'A006',d.u,d.cb)
                        set i = i + 1
                    endloop
                endif
                if d.i > 4 then
                    set timeA = 0.15
                    set a = d.angle + d.i * 20.0
                    set d.nx = x + 200 * Cos(a * bj_DEGTORAD)
                    set d.ny = y + 200 * Sin(a * bj_DEGTORAD)
                    call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Orc\\FeralSpirit\\feralspirittarget.mdl",d.nx,d.ny))
                    set d.ub = IllusionCreation(GetOwningPlayer(d.u), "war3mapimported\\buff_dg1.mdx", d.nx,d.ny, a,150,0,5,-1,100)
                    call SetUnitUserData(d.ub,50)
                    call Projectile.SetMove(d.ub,1500,20,0.5,100,a,0,0,"",-1,'A006',d.u,d.cb)
                endif
                if d.i == 20 or d.i == 35 or d.i == 50 then
                    if d.i == 20 then
                        set loopmax = 8
                    endif
                    if d.i == 35 then
                        set loopmax = 13
                    endif
                    if d.i == 50 then
                        set loopmax = 20
                    endif
                    loop
                        exitwhen i == loopmax
                        set a = d.angle + (i - (loopmax - 1) / 2.0) * 20.0
                        set d.nx = x + 200 * Cos(a * bj_DEGTORAD)
                        set d.ny = y + 200 * Sin(a * bj_DEGTORAD)
                        call DestroyEffect(AddSpecialEffect("war3mapimported\\buff_jianqikuozhang.mdx",d.nx,d.ny))
                        set d.ub = IllusionCreation(GetOwningPlayer(d.u), "war3mapimported\\buff_dg_sword_lan.mdx", d.nx,d.ny, a,120,0,5,-1,100)
                        call SetUnitUserData(d.ub,50)
                        call Projectile.SetMove(d.ub,1500,15,0.5,200,a,0,0,"Abilities\\Weapons\\ChimaeraLightningMissile\\ChimaeraLightningMissile.mdl",-1,'A007',d.u,d.cb)
                        set i = i + 1
                    endloop
                endif
                call TimerStart(t,timeA, false, function thistype.SuperSlash)
            endif
        endmethod

        //启动超级斩击的函数
        static method StarSuperSlash takes unit u, real x,real y,ProjectileBack cb returns nothing
            local thistype d = thistype.allocate()
            set d.x = x
            set d.y = y
            set d.angle = GetAngleBetween(GetUnitX(u),GetUnitY(u),x,y) 
            set d.cb = cb
            set d.u = u
            set d.t = CreateTimer()
            call SaveInteger(Hash, GetHandleId(d.t),0, d)
            call TimerStart(d.t, 0.2, false, function thistype.SuperSlash)
        endmethod

        //变身结束
        static method TransformationEnd takes nothing returns nothing
            local integer i = 0
            local timer t = GetExpiredTimer()
            local integer points
            local real currentDist
            local thistype d = LoadInteger(Hash, GetHandleId(t), 0)
            set currentDist = d.ID * 200.0
            if currentDist < 100 then
                set points = 1 
            else
                set points = 6 + R2I(currentDist / 100.0) 
            endif
            loop
                exitwhen i == points
                set d.angle = (i * 360.0 / points) * bj_DEGTORAD
                set d.nx = d.x + (d.ID * 200.0) * Cos(d.angle)
                set d.ny = d.y + (d.ID * 200.0) * Sin(d.angle)
                call DestroyEffect(AddSpecialEffect("war3mapimported\\buff_ziyan_2.mdx",d.nx,d.ny))
                set i = i + 1
            endloop
            set d.ID=d.ID + 1
            if d.ID == d.max then
                call d.cb.evaluate(d.u, d.u, 'A008', d.x, d.y)
                call d.DestroyAndTimer(t)
            else
                call TimerStart(t, 0.07, false, function thistype.TransformationEnd)
            endif
            set t = null
        endmethod

        //启动变身
        static method StarTransformation takes unit u, real x,real y,ProjectileBack cb returns nothing
            local thistype d = thistype.allocate()
            local thistype c = thistype.allocate()
            local thistype f = thistype.allocate()
            local real i = 0
            set d.x = x
            set d.y = y
            set d.angle = GetUnitFacing(u)
            set d.cb = cb
            set d.u = u
            set d.ua = IllusionCreation(GetOwningPlayer(d.u), "aizen-bengyu-5.mdx", d.x,d.y, d.angle,20,100,8,6,-50)
            set d.AF = 100
            set d.AFmax = 30
            set d.AFConstant = 0.5
            set d.initialSize = 20
            set d.CurrentSize = d.initialSize
            set d.TargetSize = 170
            set d.SpeedSize = 2.2
            set d.t = CreateTimer()
            call SaveInteger(Hash, GetHandleId(d.t),0, d)
            call TimerStart(d.t, 0.03, true, function thistype.AnimationFades)
            //____________________________________________________________
            loop 
                exitwhen i == 20
                if i <= 8 then
                    set d.nx = x + 350 * Cos((45*i) * bj_DEGTORAD)
                    set d.ny = y + 350 * Sin((45*i) * bj_DEGTORAD)
                    set d.ub = IllusionCreation(GetOwningPlayer(d.u), "war3mapimported\\buff_leiyun.mdx", d.nx,d.ny, d.angle,700,0,5,-1,100)
                endif
                set d.nx = x + 1200 * Cos((18*i) * bj_DEGTORAD)
                set d.ny = y + 1200 * Sin((18*i) * bj_DEGTORAD)
                set d.ub = IllusionCreation(GetOwningPlayer(d.u), "war3mapimported\\buff_ziyan.mdx", d.nx,d.ny, d.angle,50,0,5,-1,100)
                set i = i + 1
            endloop
            set d.ub = IllusionCreation(GetOwningPlayer(d.u), "war3mapimported\\buff_sasuke_r.mdx", d.x,d.y, d.angle,300,0,5,-1,100)
            //____________________________________________________________
            set c.u = d.ua
            set c.Animationspeed[1] = -100
            set c.AnimationID[1] = -1
            set c.Animationspeed[2] = 100
            set c.AnimationID[2] = 8 
            set c.Animationspeed[3] = 30
            set c.AnimationID[3] = -1
            set c.thetime[1] = 2.7
            set c.thetime[2] = 1.5
            set c.thetime[3] = 0.01
            set c.max = 3
            set c.t = CreateTimer()
            call SaveInteger(Hash, GetHandleId(c.t),0, c)
            call TimerStart(c.t, 0.01, false, function thistype.next)
            //_________________________________________________________
            set f.u = u
            set f.x = x
            set f.y = y
            set f.cb = cb
            set f.max = 6
            set f.t = CreateTimer()
            call SaveInteger(Hash, GetHandleId(f.t),0, f)
            call TimerStart(f.t, 3.7, false, function thistype.TransformationEnd)
        endmethod

        //时间结界
        static method TimeStop takes nothing returns nothing
            local timer t = GetExpiredTimer()
            local thistype d = LoadInteger(Hash, GetHandleId(t), 0)
            local Projectile c
            local integer i = 0
            local real x
            local real y
            if d.ID >= 600 then
                call RemoveUnit(d.ub)
                call d.DestroyAndTimer(t)
                set i = 0
                loop
                    exitwhen i >= Count 
                    set c = ALL[i]
                    set c.speed = c.InitialSpeed
                    set i = i + 1
                endloop
            endif
            set d.ID = d.ID + 1
            loop
                exitwhen i >= Count 
                set c = ALL[i]
                set x = c.nextx - d.x
                set y = c.nexty - d.y
                if (x * x + y * y) <= 360000 then
                    set c.speed = 2 
                    call SetUnitTimeScalePercent(c.u,20) 
                else
                    set c.speed = c.InitialSpeed
                    call SetUnitTimeScalePercent(c.u,100) 
                endif
                set i = i + 1
            endloop
            set t = null
        endmethod

        //启动时间结界
        static method StarTimeStop takes unit u, real x,real y,ProjectileBack cb returns nothing
            local thistype d = thistype.allocate()
            set d.u = u
            set d.x = x
            set d.y = y
            set d.t = CreateTimer()
            set d.ub = IllusionCreation(GetOwningPlayer(d.u), "buff_qiu.mdx", d.x,d.y, 0,500,0,10,-1,100)
            call SaveInteger(Hash, GetHandleId(d.t),0, d)
            call TimerStart(d.t, 0.01, true, function thistype.TimeStop)
        endmethod

        //环形冲击结束
        static method CircularImpactEnd takes nothing returns nothing
            local timer t = GetExpiredTimer()
            local thistype d = LoadInteger(Hash, GetHandleId(t), 0)
            local real x
            local real y
            local real i = 0
            call DestroyEffect(d.ef)
            loop
                exitwhen i == 8
                set x = GetUnitX(d.ua) + (500+(200*i)) * Cos(d.angle  * bj_DEGTORAD)
                set y = GetUnitY(d.ua) + (500+(200*i)) * Sin(d.angle  * bj_DEGTORAD)
                call DestroyEffect(AddSpecialEffect("war3mapimported\\buff_flamestrike blood ii.mdx",x,y))
                call d.cb.evaluate(d.u, d.u, 'A009', x,y) 
                set i = i + 1
            endloop
            call d.DestroyAndTimer(t)
        endmethod

        //环形冲击
        static method CircularImpact takes nothing returns nothing
            local timer t = GetExpiredTimer()
            local thistype d = LoadInteger(Hash, GetHandleId(t), 0)
            local thistype c 
            local thistype f
            local real x
            local real y
            local real a = 0.1
            local real i = 0
            if d.ID <= 6 then
                set a = 0.2
                set x = d.x + (150 * d.ID) * Cos((d.angle - 90 ) * bj_DEGTORAD)
                set y = d.y + (150 * d.ID) * Sin((d.angle - 90 ) * bj_DEGTORAD)
                call DestroyEffect(AddSpecialEffect("dark conversion.mdl",x,y))
                call d.cb.evaluate(d.u, d.u, 'A009', x,y)
                set x = d.x + (150 * d.ID) * Cos((d.angle + 90 ) * bj_DEGTORAD)
                set y = d.y + (150 * d.ID) * Sin((d.angle + 90 ) * bj_DEGTORAD)
                call DestroyEffect(AddSpecialEffect("dark conversion.mdl",x,y))
                call d.cb.evaluate(d.u, d.u, 'A009', x,y)                            
            endif
            if d.ID >= 6 and d.ID <=18 then
                set a = 0.07
                set x = d.x + 1200 * Cos((180 + (15*d.ID) ) * bj_DEGTORAD)
                set y = d.y + 1200 * Sin((180 + (15*d.ID) ) * bj_DEGTORAD)
                set d.ua = IllusionCreation(GetOwningPlayer(d.u), "dark conversion.mdl", x,y, 0,200,0,8,-1,100)
                set x = d.x + 1200 * Cos((360 - (15*d.ID) ) * bj_DEGTORAD)
                set y = d.y + 1200 * Sin((360 - (15*d.ID) ) * bj_DEGTORAD)
                set d.ua = IllusionCreation(GetOwningPlayer(d.u), "dark conversion.mdl", x,y, 0,200,0,8,-1,100)
            endif
            if d.ID >= 18 and d.ID <= 42 then
                set a = 0.1
                set d.angle = d.angle + 15
                loop
                    exitwhen i == 6
                    set x = d.x + (200 * i) * Cos(d.angle  * bj_DEGTORAD)
                    set y = d.y + (200 * i) * Sin(d.angle  * bj_DEGTORAD)
                    call DestroyEffect(AddSpecialEffect("dark conversion.mdl",x,y))
                    call d.cb.evaluate(d.u, d.u, 'A009', x,y) 
                    set i = i + 1
                endloop
            endif
            if d.ID >= 43 and d.ID <= 53 then
                set a = 0.15
                set x = d.x - 1300 * Cos(d.angle + ((360/10)*(d.ID-42)) * bj_DEGTORAD)
                set y = d.y - 1300 * Sin(d.angle + ((360/10)*(d.ID-42)) * bj_DEGTORAD)
                set c = thistype.allocate()
                set c.ua = IllusionCreation(GetOwningPlayer(d.u), "wightunit.mdx", x,y, GetAngleBetween(x,y,d.x,d.y),50,30,8,7,50)
                call Projectile.SetMove(c.ua,400,2,0,0,GetAngleBetween(x,y,d.x,d.y),0,0,"",-1,'A000',d.u,0)
                set c.AF = 30 
                set c.AFmax = 100 
                set c.AFConstant = 1.1
                set c.initialSize = 50
                set c.CurrentSize = c.initialSize
                set c.TargetSize = 400
                set c.SpeedSize = 9
                set c.t = CreateTimer()
                call SaveInteger(Hash, GetHandleId(c.t),0, c)
                call TimerStart(c.t, 0.03, true, function thistype.AnimationFades)
                //______________________________________
                set f = thistype.allocate()
                set f.ef = AddSpecialEffectTarget("war3mapimported\\buff_xz_qiu.mdx",c.ua, "weapon")
                set f.ua =c.ua
                set f.u = d.u
                set f.x = d.x
                set f.y = d.y
                set f.angle = GetAngleBetween(x,y,d.x,d.y)
                set f.cb = d.cb
                set f.t = CreateTimer()
                call SaveInteger(Hash, GetHandleId(f.t),0, f)
                call TimerStart(f.t, 1.1, false, function thistype.CircularImpactEnd)
            endif 
            set d.ID = d.ID + 1
            if d.ID >= 54 then
                call d.DestroyAndTimer(t)
            else
                call TimerStart(t, a, false, function thistype.CircularImpact)
            endif
        endmethod

        //启动环形冲击的函数
        static method StarCircularImpact takes unit u, real x,real y,ProjectileBack cb returns nothing
            local thistype d = thistype.allocate()
            set d.x = x
            set d.y = y
            set d.angle = GetAngleBetween(GetUnitX(u),GetUnitY(u),x,y) 
            set d.cb = cb
            set d.u = u
            set d.t = CreateTimer()
            call SaveInteger(Hash, GetHandleId(d.t),0, d)
            call TimerStart(d.t, 0.2, false, function thistype.CircularImpact)
        endmethod

        //扇形冲击 
        static method sickle takes nothing returns nothing
            local timer t = GetExpiredTimer()
            local thistype d = LoadInteger(Hash, GetHandleId(t), 0)
            local real i = 0
            if d.ID == 0 then
                call DestroyEffect(d.ef)
                loop
                    exitwhen i == 6
                    set d.nextx = d.x + 500 * Cos((d.angle + (i - (6 - 1) / 2.0) * 20) * bj_DEGTORAD)  
                    set d.nexty = d.y + 500 * Sin((d.angle + (i - (6 - 1) / 2.0) * 20) * bj_DEGTORAD)
                    call DestroyEffect(AddSpecialEffect("war3mapimported\\buff_flamestrike blood ii.mdx",d.nextx,d.nexty))
                    call setGroup.BackEnemy(d.u,d.u,'A010',100,d.nextx,d.nexty,d.cb)
                    set i = i + 1
                endloop
            endif
            if d.ID == 1 then
                loop
                    exitwhen i == 6
                    set d.nextx = d.x + 500 * Cos((d.angle + (i - (6 - 1) / 2.0) * 20) * bj_DEGTORAD)  
                    set d.nexty = d.y + 500 * Sin((d.angle + (i - (6 - 1) / 2.0) * 20) * bj_DEGTORAD)
                    call DestroyEffect(AddSpecialEffect("war3mapimported\\buff_soul armor psyche.mdx",d.nextx,d.nexty))
                    set d.ua = IllusionCreation(GetOwningPlayer(d.u), "war3mapimported\\buff_xz_longtou.mdx", d.nextx,d.nexty, d.angle + (i - (6 - 1) / 2.0) * 20.0,400,0,5,-1,100)
                    call SetUnitUserData(d.ua,50)
                    call Projectile.SetMove(d.ua,1200,15,0.5,150,d.angle + (i - (6 - 1) / 2.0) * 20.0,0,0,"war3mapimported\\buff_xz_longtou.mdx",-1,'A010',d.u,d.cb)
                    set i = i + 1
                endloop
            endif
            if d.ID >= 2 then
                call d.DestroyAndTimer(t)
            else
                set d.ID = d.ID + 1
            endif
        endmethod

        //启动扇形冲击的函数
        static method StarSickle takes unit u, real x,real y,ProjectileBack cb returns nothing
            local thistype d = thistype.allocate()
            local thistype c = thistype.allocate()
            set d.x = x
            set d.y = y
            set d.angle = GetAngleBetween(GetUnitX(u),GetUnitY(u),x,y) 
            set d.cb = cb
            set d.u = u
            set d.t = CreateTimer()
            call SaveInteger(Hash, GetHandleId(d.t),0, d)
            call TimerStart(d.t, 1.1, true, function thistype.sickle)
            //_______________________________________________
            set c.ua = IllusionCreation(GetOwningPlayer(d.u), "wightunit.mdx", x,y, d.angle,50,100,5,5,50)
            set d.ef = AddSpecialEffectTarget("war3mapimported\\buff_xz_qiu.mdx",c.ua, "weapon")
            set c.AF = 100
            set c.AFmax = 30
            set c.AFConstant = 1.1
            set c.initialSize = 50
            set c.CurrentSize = c.initialSize
            set c.TargetSize = 400
            set c.SpeedSize = 9
            set c.t = CreateTimer()
            call SaveInteger(Hash, GetHandleId(c.t),0, c)
            call TimerStart(c.t, 0.03, true, function thistype.AnimationFades)
        endmethod

        //移动环形剑
        method MoveRingSword takes nothing returns nothing
            local real R
            local real L = this.ID * 100
            local real currentAngle
            local real theta
            local real moveAngle
            local integer i = R2I(this.ID)
            if this.CheckID == 0 then
                call this.cb.evaluate(this.u, this.u, '0000', GetUnitX(this.u), GetUnitY(this.u))
                call DestroyEffect(AddSpecialEffect("war3mapimported\\buff_wood_effect_tianhuo_2_1.mdx",GetUnitX(this.u),GetUnitY(this.u)))
                call KillUnit(this.u)
                call FlushChildHashtable(Hash, GetHandleId(this.u))
                call this.DestroyAndTimer(null)
            else
                set this.CheckID = this.CheckID - 1
                set R = this.ID * 250.0 
                if L > R * 2.0 then
                    set L = R * 2.0 
                endif
                set currentAngle = Atan2(GetUnitY(this.u) - this.y, GetUnitX(this.u) - this.x) * bj_RADTODEG
                set theta = Asin(L / (2.0 * R)) * bj_RADTODEG * 2.0
                if ModuloInteger(i, 2) == 0 then
                    set moveAngle = currentAngle + 90.0 + (theta / 2.0)
                else
                    set moveAngle = currentAngle - 90.0 - (theta / 2.0)
                endif
                if  GetUnitState(this.u, UNIT_STATE_LIFE) <= 0 then
                    call FlushChildHashtable(Hash, GetHandleId(this.u))
                    call this.DestroyAndTimer(null)
                else
                    call Projectile.SetMove(this.u, L, 3 + (1*this.ID), 0, 100, moveAngle, 0, 0, " ", -1, 'A011', this.u, 0) 
                endif
            endif
        endmethod

        //环形剑
        static method RingSword takes unit u, real x,real y,integer z ,ProjectileBack cb returns nothing
            local thistype d = thistype.allocate()
            local thistype c
            local integer i = 0
            local integer points
            local real currentDist
            set d.x = x
            set d.y = y
            set d.cb = cb
            set d.u = u
            loop 
                exitwhen d.ID == z
                set currentDist = d.ID * 250.0
                if currentDist < 100 then
                    set points = 1 
                else
                    set points = 6 + R2I(currentDist / 100.0) 
                endif
                set i = 0
                loop
                    exitwhen i == points
                    set d.angle = (i * 360.0 / points) 
                    set d.nx = d.x + (d.ID * 250.0) * Cos(d.angle * bj_DEGTORAD)
                    set d.ny = d.y + (d.ID * 250.0) * Sin(d.angle * bj_DEGTORAD)
                    if d.ID != 0 then
                        set d.ua = IllusionCreation(GetOwningPlayer(d.u), "war3mapimported\\buff_fuwenjian.mdx", d.x,d.y, d.angle ,150,0,25,-1,100)
                        call SetUnitFlyHeight(d.ua, 200, 0)
                        call Projectile.SetMove(d.ua,GetDistance(d.x,d.y,d.nx,d.ny),3+(d.ID*1),0,100,d.angle,0,0,"",100+(d.ID * 150),'A011',d.u,0)
                        set c = thistype.allocate()
                        set c.u = d.ua
                        set c.ID = d.ID
                        set c.CheckID = c.ID + (6 - c.ID)
                        set c.x = d.x 
                        set c.y = d.y 
                        set c.cb = d.cb
                        call SaveInteger(Hash, GetHandleId(c.u),CircularBlood_t, c)
                    endif
                    set i = i + 1
                endloop
                set d.ID = d.ID + 1
            endloop
            call d.DestroyAndTimer(null)
        endmethod

        //红色跳跃
        static method RedJump takes nothing returns nothing
            local timer t = GetExpiredTimer()
            local thistype d = LoadInteger(Hash, GetHandleId(t), 0)
            local real i = 0
            local real a = 0.8
            if d.ID >= 6 then
                call SetUnitTimeScalePercent(d.u,100)
                call ResetUnitAnimation( d.u)
                call d.DestroyAndTimer(t)
            else
                set d.ID = d.ID + 1
                if d.ID == 6 then
                    call DestroyEffect(d.ef)
                    loop 
                        exitwhen i == 4
                        set d.nextx = d.nx + 450 * Cos((d.angle + 180.0 + (i - 1.5) * 60.0) * bj_DEGTORAD)
                        set d.nexty = d.ny + 450 * Sin((d.angle + 180.0 + (i - 1.5) * 60.0) * bj_DEGTORAD)
                        set d.ua = IllusionCreation(GetOwningPlayer(d.u), "war3mapimported\\buff_xz_xsmp.mdl", d.nextx,d.nexty, d.angle ,50,0,5,-1,100)
                        call SetUnitFlyHeight(d.ua, 500, 0)
                        call SetUnitUserData(d.ua,50)
                        call Projectile.SetMove(d.ua,GetDistance(d.nextx,d.nexty,d.x,d.y),20,0,100,GetAngleBetween(d.nextx,d.nexty,d.x,d.y),0,1,"",0,'A012',d.u,d.cb)
                        set i = i + 1
                    endloop
                endif
                if d.ID == 2 then
                    set a = 0.1
                    set d.nextx = GetUnitX(d.u)
                    set d.nexty = GetUnitY(d.u)
                    call Projectile.SetMove(d.u,GetDistance(d.x,d.y,GetUnitX(d.u),GetUnitY(d.u)),25,0,100,d.angle,0,0,"",0,'A012',d.u,d.cb)
                endif
                if d.ID > 1 and d.ID < 6 then
                    set a = 0.1
                    set d.ua = IllusionCreation(GetOwningPlayer(d.u), "dw_xuesesishen.mdl", d.nextx,d.nexty, d.angle ,150,0,5,5,50)
                    call SetUnitFlyHeight(d.ua, 300, 0)
                    call Projectile.SetMove(d.ua,GetDistance(d.x,d.y,d.nextx,d.nexty),25,0,100,d.angle,0,1,"",0,'A012',d.u,0)
                endif
                if d.ID == 1 then
                    set a = 0.7
                    call SetUnitAnimationByIndex( d.u, 5 )
                    call SetUnitTimeScalePercent(d.u,50)
                endif
                call TimerStart(d.t, a, false, function thistype.RedJump)
            endif
            set t = null
        endmethod

        //启动红色跳跃
        static method StarRedJump takes unit u, real x,real y,ProjectileBack cb returns nothing
            local thistype d = thistype.allocate()
            set d.x = x
            set d.y = y
            set d.cb = cb
            set d.u = u
            set d.nx = GetUnitX(d.u)
            set d.ny = GetUnitY(d.u)
            set d.angle = GetAngleBetween(d.nx,d.ny,d.x,d.y)
            call UnitAddAbility( d.u, 'Arav')
            call UnitRemoveAbility( d.u, 'Arav')
            set d.ef = AddSpecialEffectTarget("war3mapimported\\buff_xz_qiu.mdx",d.u, "weapon")
            call Projectile.SetMove(d.u,300,3,0,100,d.angle,0,0,"",400,'A000',d.u,0)
            set d.t = CreateTimer()
            call SaveInteger(Hash, GetHandleId(d.t),0, d)
            call TimerStart(d.t, 0.1, false, function thistype.RedJump)
        endmethod

        //天灾
        static method disaster takes nothing returns nothing
            local timer t = GetExpiredTimer()
            local thistype d = LoadInteger(Hash, GetHandleId(t), 0)
            local real i = 0
            local real r = 0
            local real a = 0
            local real z = 2000
            if d.ID >= 24 then
                call PauseUnit( d.u, false)
                call DestroyLightning(d.l)
                call d.DestroyAndTimer(t)
            else
                set d.ID = d.ID + 1
                if d.ID == 1 then
                    call PauseUnit( d.u, true)
                    set d.ua = IllusionCreation(GetOwningPlayer(d.u), "war3mapimported\\buff_longjuanfeng.mdl", d.x,d.y, 0,300,0,14,-1,30)
                endif
                if d.ID <= 4 then
                    set d.ef = AddSpecialEffect("war3mapimported\\buff_xuli.mdx",d.x,d.y)
                    call EXSetEffectSize( d.ef, 4)
                    call DestroyEffect(d.ef)
                endif
                if d.ID >= 4 then
                    set r =  GetRandomReal(300,600)
                    set a =  GetRandomReal(0,360)
                    set d.nextx = d.x + r * Cos(a * bj_DEGTORAD)
                    set d.nexty = d.y + r * Sin(a * bj_DEGTORAD)
                    set d.ua = IllusionCreation(GetOwningPlayer(d.u), "war3mapimported\\buff_shuilongjuan.mdl", d.nextx,d.nexty, 0 ,110,0,5,-1,100)
                    call SetUnitUserData(d.ua,50)
                    call Projectile.SetMove(d.ua,600,3.5,0.5,180,a,0,0,"",-1,'AX13',d.u,d.cb)
                endif
                if d.ID >= 8 then
                    set i = 0
                    loop
                        exitwhen i == 2
                        set r =  GetRandomReal(500,1200)
                        set a =  GetRandomReal(0,360)
                        set d.nextx = d.x + r * Cos(a * bj_DEGTORAD)
                        set d.nexty = d.y + r * Sin(a * bj_DEGTORAD)
                        set d.ua = IllusionCreation(GetOwningPlayer(d.u), "war3mapImported\\buff_huoqiu.mdl", d.nextx,d.nexty, 180,40*GetRandomReal(0.7,1.3),0,4,-1,100)
                        call SetUnitUserData(d.ua,50)
                        call SetUnitFlyHeight(d.ua, 1500, 0)
                        call Projectile.SetMove(d.ua,500,4,0,0,180,0,1,"",-150,'AC13',d.u,d.cb)
                        set i = i + 1
                    endloop
                endif
                if d.ID == 10 then
                    call LensSettings.ShakyCamera(7,10)
                    set d.ua = IllusionCreation(GetOwningPlayer(d.u), "war3mapimported\\buff_orgia mode4.mdx", d.x,d.y, 0,400,0,8,-1,100)
                endif
                if d.ID == 12 then
                    set i = 0
                    loop
                        exitwhen i == 3
                        set d.nx = d.x + 450 * Cos((120*i) * bj_DEGTORAD)
                        set d.ny = d.y + 450 * Sin((120*i) * bj_DEGTORAD)
                        set d.ua = IllusionCreation(GetOwningPlayer(d.u), "war3mapimported\\buff_leiyun.mdx", d.nx,d.ny, d.angle,700,50,8,-1,100)
                        call SetUnitFlyHeight(d.ua, 1000, 0)
                        set i = i + 1
                    endloop
                endif
                if d.ID > 12 then
                    set r =  GetRandomReal(500,1200)
                    set a =  GetRandomReal(0,360)
                    set d.nextx = d.x + r * Cos(a * bj_DEGTORAD)
                    set d.nexty = d.y + r * Sin(a * bj_DEGTORAD)
                    set d.nx = d.nextx + 300 * Cos(a * bj_DEGTORAD)
                    set d.ny = d.nexty + 300 * Sin(a * bj_DEGTORAD)
                    call DestroyLightning(d.l)
                    set d.l = AddLightningEx("FORK",true,d.nx,d.ny,z,d.nextx,d.nexty,0)
                    //call DestroyEffect(AddSpecialEffect("war3mapimported\\buff_by_wood_effect_yubanmeiqin_lightning_zhenzhengdeluolei.mdx",d.nextx,d.nexty))
                    call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\Bolt\\BoltImpact.mdl",d.nextx,d.nexty))
                    call d.cb.evaluate(d.u, d.u, 'AD13', d.nextx,d.nexty)
                endif
            endif
            set t = null
        endmethod

        //启动天灾
        static method StarDisaster takes unit u, real x,real y,ProjectileBack cb returns nothing
            local thistype d = thistype.allocate()
            local thistype c = thistype.allocate()
            set d.x = x
            set d.y = y
            set d.cb = cb
            set d.u = u
            set d.t = CreateTimer()
            call SaveInteger(Hash, GetHandleId(d.t),0, d)
            call TimerStart(d.t, 0.7, true, function thistype.disaster)
            set c.u = d.u
            set c.Animationspeed[1] = 100
            set c.AnimationID[1] = 6
            set c.Animationspeed[2] = 50
            set c.AnimationID[2] = 6 
            set c.Animationspeed[3] = 50
            set c.AnimationID[3] = 6
            set c.Animationspeed[4] = 50
            set c.AnimationID[4] = 6
            set c.Animationspeed[5] = 100
            set c.AnimationID[5] = 6
            set c.Animationspeed[6] = 100
            set c.AnimationID[6] = 0
            set c.thetime[1] = 0.1
            set c.thetime[2] = 4
            set c.thetime[3] = 4
            set c.thetime[4] = 5
            set c.thetime[5] = 3
            set c.thetime[6] = 0.1
            set c.max = 6
            set c.t = CreateTimer()
            call SaveInteger(Hash, GetHandleId(c.t),0, c)
            call TimerStart(c.t, 0.01, false, function thistype.next)
        endmethod

        //执行能量爆发
        static method EnergyBurst takes nothing returns nothing
            local timer t = GetExpiredTimer()
            local thistype d = LoadInteger(Hash, GetHandleId(t), 0)
            local real a = 0.1
            local unit u 
            local real x
            local real y
            local real r
            if d.i >= 60 then
                call KillUnit(d.ua)
                call PauseUnit( d.u, false)
                call d.DestroyAndTimer(t)
            else
                set d.i = d.i + 1
                if d.i == 1 then
                    call PauseUnit( d.u, true)
                endif
                if d.i <= 7 then
                    set u = IllusionCreation(GetOwningPlayer(d.u), "yx_xiaoyuanxuli2.mdl", d.nx, d.ny, 0,300 ,0,2,-1,100)
                    call SetUnitFlyHeight(u, 400 , 0)
                endif
                if d.i == 12 then
                    call LensSettings.ShakyCamera(9,4.8)
                    set d.ef = AddSpecialEffect("war3mapimported\\buff_yuanqidan.mdx",d.nx,d.ny)
                    call EXSetEffectZ( d.ef, 300 )
                    call EXSetEffectSize( d.ef, 3)
                    call DestroyEffect(d.ef)
                    set d.ua = IllusionCreation(GetOwningPlayer(d.u), "war3mapimported\\buff_hdjg.mdx", d.nx,d.ny, d.angle,50,0,10,-1,70)
                    call SetUnitFlyHeight(d.ua, 300, 0)   
                endif
                if d.i >= 12 then
                    set r = GetRandomReal(1000,3000)
                    set x = d.nx + 3000 * Cos(d.angle * bj_DEGTORAD)
                    set y = d.ny + 3000 * Sin(d.angle * bj_DEGTORAD)
                    call setGroup.LineEnemy(d.u,d.u,'A014',d.nx,d.ny,x,y,250,d.cb)
                    set d.nextx = d.nx + r * Cos(d.angle * bj_DEGTORAD)
                    set d.nexty = d.ny + r * Sin(d.angle * bj_DEGTORAD)
                    set d.ID = d.ID + 1
                    if d.ID >= 5 then
                        set d.ID = 0
                        set d.ef = AddSpecialEffect("war3mapimported\\buff_valkdust.mdx",GetUnitX(d.u),GetUnitY(d.u))
                        call EXSetEffectSize( d.ef, 5)
                        call DestroyEffect(d.ef)
                        call DestroyEffect(AddSpecialEffect("war3mapimported\\buff_hebao.mdx",d.nextx,d.nexty))
                        call setGroup.BackEnemy(d.u,d.u,'A015',800,d.nextx,d.nexty,d.cb)
                    endif
                    set d.CheckID  = d.CheckID + 1
                    if d.CheckID == 1 then
                        set d.CheckID = 0
                        set d.SignalID = d.SignalID + 1
                        set d.angle = d.angle + 2.5
                        set d.nx = GetUnitX(d.u) + 350 * Cos(d.angle * bj_DEGTORAD)
                        set d.ny = GetUnitY(d.u) + 350 * Sin(d.angle * bj_DEGTORAD)
                        call SetUnitFacing(d.u,d.angle)
                        call SetUnitFacing(d.ua,d.angle)
                        call SetUnitX(d.ua,d.nx)
                        call SetUnitY(d.ua,d.ny)
                    endif
                endif
                call TimerStart(t, a, false, function thistype.EnergyBurst)
            endif
            set t = null
            set u = null
        endmethod

        //启动能量爆发
        static method StarEnergyBurst takes unit u, real x,real y,ProjectileBack cb returns nothing
            local thistype d = thistype.allocate()
            local thistype c = thistype.allocate()
            set d.x = x
            set d.y = y
            set d.cb = cb
            set d.u = u
            set d.nx = GetUnitX(d.u)
            set d.ny = GetUnitY(d.u)
            set d.angle = GetAngleBetween(d.nx,d.ny,d.x,d.y)
            set d.nx = d.nx + 350 * Cos(d.angle * bj_DEGTORAD)
            set d.ny = d.ny + 350 * Sin(d.angle * bj_DEGTORAD)
            set d.z = 200
            set d.t = CreateTimer()
            call SaveInteger(Hash, GetHandleId(d.t),0, d)
            call TimerStart(d.t, 0.1, false, function thistype.EnergyBurst)
            set c.u = d.u
            set c.Animationspeed[1] = 100
            set c.AnimationID[1] = 4
            set c.Animationspeed[2] = 30
            set c.AnimationID[2] = -1 
            set c.Animationspeed[3] = 100
            set c.AnimationID[3] = 0
            set c.thetime[1] = 0.5
            set c.thetime[2] = 6
            set c.thetime[3] = 0.1
            set c.max = 3
            set c.t = CreateTimer()
            call SaveInteger(Hash, GetHandleId(c.t),0, c)
            call TimerStart(c.t, 0.1, false, function thistype.next)
        endmethod

        //扇形尖刺
        static method spikes takes nothing returns nothing
            local timer t = GetExpiredTimer()
            local thistype d = LoadInteger(Hash, GetHandleId(t), 0)
            local real x = GetUnitX(d.u)
            local real y = GetUnitY(d.u)
            local real i = 0
            local real a = 0
            if d.i >= 10 then
                loop
                    exitwhen i == 12
                    set a = d.angle + (15 * (i-5))
                    set d.nx = x + 200 * Cos(a * bj_DEGTORAD)
                    set d.ny = y + 200 * Sin(a * bj_DEGTORAD)
                    call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Orc\\FeralSpirit\\feralspirittarget.mdl",d.nx,d.ny))
                    set d.ub = IllusionCreation(GetOwningPlayer(d.u), "Abilities\\Weapons\\BristleBackMissile\\BristleBackMissile.mdl", d.nx,d.ny, a,450,0,5,-1,100)
                    call SetUnitUserData(d.ub,50)
                    call Projectile.SetMove(d.ub,1500,12,0.5,80,a,0,0,"Abilities\\Weapons\\SentinelMissile\\SentinelMissile.mdl",-1,'A016',d.u,d.cb)
                    set i = i + 1
                endloop
                call PauseUnit( d.u, false)
                call d.DestroyAndTimer(t)
            else
                loop
                    exitwhen i == 2
                    if i == 1 then
                        set a = d.angle + (10 * d.i)
                    else
                        set a = d.angle - (10 * d.i)
                    endif
                    set d.nx = x + 200 * Cos(a * bj_DEGTORAD)
                    set d.ny = y + 200 * Sin(a * bj_DEGTORAD)
                    call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Orc\\FeralSpirit\\feralspirittarget.mdl",d.nx,d.ny))
                    set d.ub = IllusionCreation(GetOwningPlayer(d.u), "Abilities\\Weapons\\BristleBackMissile\\BristleBackMissile.mdl", d.nx,d.ny, a,450,0,5,-1,100)
                    call SetUnitUserData(d.ub,50)
                    call Projectile.SetMove(d.ub,1500,12,0.5,80,a,0,0,"Abilities\\Weapons\\SentinelMissile\\SentinelMissile.mdl",-1,'A016',d.u,d.cb)
                    set i = i + 1
                endloop
                set d.i = d.i + 1
            endif
            set t = null
        endmethod

        //启动扇形尖刺
        static method StarSpikes takes unit u, real x,real y,ProjectileBack cb returns nothing
            local thistype d = thistype.allocate()
            local thistype c = thistype.allocate()
            set d.cb = cb
            set d.u = u
            set d.x = GetUnitX(d.u)
            set d.y = GetUnitY(d.u)
            set d.nextx = x
            set d.nexty = y
            set d.angle = GetAngleBetween(d.x,d.y,x,y)
            set d.t = CreateTimer()
            call SaveInteger(Hash, GetHandleId(d.t),0, d)
            call TimerStart(d.t, 0.2, true, function thistype.spikes)
            call PauseUnit( d.u, true)
            set c.u = d.u
            set c.Animationspeed[1] = 150
            set c.AnimationID[1] = 2
            set c.Animationspeed[2] = 100
            set c.AnimationID[2] = 3
            set c.Animationspeed[3] = 100
            set c.AnimationID[3] = 2
            set c.Animationspeed[4] = 100
            set c.AnimationID[4] = 0
            set c.thetime[1] = 0.5
            set c.thetime[2] = 1
            set c.thetime[3] = 1
            set c.thetime[4] = 0.1
            set c.max = 4
            set c.t = CreateTimer()
            call SaveInteger(Hash, GetHandleId(c.t),0, c)
            call TimerStart(c.t, 0.1, false, function thistype.next)
        endmethod

    endstruct

    public function unitdie takes nothing returns boolean
        local unit u = GetTriggerUnit()
        local unit hero
        set u = null
        set hero = null
        return false
    endfunction

    public function SpellCastAction takes nothing returns boolean
        local unit u = GetTriggerUnit()
        local location p = null
        local real x
        local real y
        set u = null
        set p = null
        return false
    endfunction

    public function setorigin takes nothing returns nothing
        local trigger t = CreateTrigger()
        local trigger t1 = CreateTrigger()
        local region area9 = CreateRegion()
        set map = CreateRegion()
        call RegionAddRect(map, bj_mapInitialPlayableArea)
        call TriggerRegisterAnyUnitEventBJ(t, EVENT_PLAYER_UNIT_SPELL_EFFECT)
        call TriggerAddCondition(t, Condition(function SpellCastAction))
        call TriggerRegisterAnyUnitEventBJ(t1, EVENT_PLAYER_UNIT_DEATH)
        call TriggerAddCondition(t1, Condition(function unitdie))
        //设置刷怪区域和触发区域
        set t = null
        //设置条件
        set filter = Filter(function setGroup.filterEnemy)
        set Groupfilter = Filter(function setGroup.Groupenemy)
        set SametypeID = Filter(function setGroup.Sametypetrue)
        set area9 = null
    endfunction
endlibrary

