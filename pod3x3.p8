pico-8 cartridge // http://www.pico-8.com
version 8
__lua__

credits = {}
credits.s = "                                   <3 pod3x3 - a game by ossian boren. <3  super special thanks to: erik svedang, peter bjorklund, anna elwing. <3"
credits.p = 1
start_gfx_p1 = -100
start_gfx_p2 = 228
start_gfx_logo = -50
start_gfx_circle = 150
game_start = false
start_counter = 30
end_counter = 90
deadzone = 0.01
playercolors = {2,3,4,8,9,12,13,14}
numberofcolors = 8
center = {}
center.x = 64
center.y = 64
arena = 65
sprite = 8
maintimer = 60 * 30
freeze = 0
frames = 0

cam = {}
cam.x = 0
cam.y = 0
car = {}

p1 = {}
p1.ready = false
p1.ai = false
p1.wins = 0
p1.nr = 1
p1.clr = 14
p1.x = 0
p1.y = 0
p1.car = 1
p1.winner = false
p1.deathcount = 0
p1.guage = 5

p2 = {}
p2.ready = false
p2.ai = false
p2.wins = 0
p2.nr = 2
p2.clr = 3
p2.x = 0
p2.y = 0
p2.car = 1
p2.winner = false
p2.deathcount = 0
p2.guage = 5

function splash()
  frames += 1
  palt(12,true)
  palt(0,false)
  if frames > 45 then lid.y = lerp(lid.y,trash.y-1,0.08) end
  if flr(lid.y) == trash.y - 1 then lid.spr = 68 end
  if frames < 200 then
    rectfill(0,0,128,128,10)
    spr(64,trash.x,trash.y,4,4)
    spr(lid.spr,lid.x,lid.y,4,2)
  end
  if frames > 55 and trash.sfx then
  		sfx(14,0)
  		trash.sfx = false
  end
  if frames > 75 and frames < 220 then
    line(trash.x+13,trash.y+7,trash.x+13,trash.y+8,10)
    line(trash.x+18,trash.y+7,trash.x+18,trash.y+8,10)

    local c = 72
    local a = 73
    local t = 74
    local n = 75
    local i = 88
    local p = 89
    local d = 90
    local e = 91
    local x = 32
    local y = trash.y + 32
    spr(c,x,y)
    spr(a,x+1*7,y)
    spr(t,x+2*7,y)
    spr(n,x+3*7,y)
    spr(i,x+4*7-1,y)
    spr(p,x+5*7-2,y)
    spr(p,x+6*7-2,y)
    spr(e,x+7*7-2,y)
    spr(d,x+8*7-2,y)
  end
  if frames > 260 then trash.done = true frames = 0 end
  palt()
end

function init_splash()
  trash = {}
  trash.x = 47
  trash.y = 46
  trash.sfx = true
  trash.done = false
  lid = {}
  lid.spr = 100
  lid.x = trash.x
  lid.y = trash.y+2
  frames = 0
end

function carspawn (nr,plr) --car array
  car[nr] = {}
  car[nr].x = 0
  car[nr].y = 0
  car[nr].hp = 5
  car[nr].owner = plr.nr
  car[nr].status = "happy"
  car[nr].dead = false
  car[nr].death_counter = 0
  car[nr].turret = 0
  car[nr].attack_offset = {}
  car[nr].attack_counter = 0
  car[nr].target = 1
  car[nr].damaged = false
  car[nr].damagedcounter = 0
  if plr.nr == 1 then
    car[nr].rot = 0.75
    car[nr].dir = 0.75
  elseif plr.nr == 2 then
    car[nr].rot = 0.25
    car[nr].dir = 0.25
  end
  car[nr].throt = 0
  car[nr].vel = 0
  car[nr].clr = plr.clr
  car[nr].active = false
  car[nr].nr = nr
  car[nr].hitbox = 4
  car[nr].timer = 0
  car[nr].rotspeed = 0.01
  car[nr].tracks_left_x = {}
  car[nr].tracks_left_y = {}
  car[nr].tracks_right_x = {}
  car[nr].tracks_right_y = {}
  car[nr].tracks_length = 0
  car[nr].tracks_counter = 0
  car[nr].shield = false
end

function every(a,b) -- a: number of frames true b: 1-30 where 1 is every frame, 30 is once each second.
  return frames % b < a
end

function cardraw(p)


  --wheels
  if p.dead == false then
    if p.rot <= 0.25  then
      spr(13-6*(p.rot*4),p.x-4,p.y-4,1,1,true)
    elseif p.rot > 0.25 and p.rot <= 0.5 then
      spr((8+6*(p.rot*4))-6,p.x-4,p.y-4)
    elseif p.rot > 0.5 and p.rot <= 0.75 then
      spr(13-6*(p.rot*4)+12,p.x-4,p.y-4,1,1,true)
    elseif p.rot > 0.75 then
      spr((8+6*(p.rot*4))-18,p.x-4,p.y-4)
    end
  else
    spr(15,p.x-4,p.y-4)
  end

  circfill(p.x-0.5,p.y-0.5,2,p.clr) --body

  --status light
  if p.dead == true then
    circfill(p.x+1*sin(p.turret+0.15),p.y+1*cos(p.turret+0.15),0,0)
  elseif p.status == "danger" then
    circfill(p.x+1*sin(p.turret+0.15),p.y+1*cos(p.turret+0.15),0,10)
  else
    circfill(p.x+1*sin(p.turret+0.15),p.y+1*cos(p.turret+0.15),0,11)
  end

  --turret
  if p.hit == false then
    -- circfill(p.x+4*sin(p.turret),p.y+4*cos(p.turret),1,10)
    line(p.x+2*sin(p.turret),p.y+2*cos(p.turret),p.x+4*sin(p.turret),p.y+4*cos(p.turret),6)
  else
    line(p.x+2*sin(p.turret),p.y+2*cos(p.turret),p.x+6*sin(p.turret),p.y+6*cos(p.turret),7)
  end

  --shield
  function shieldcircle(c,p)
    if p > 3 then local plr = p2 else plr = p1 end
    if c.shield == true and plr.guage < 1 then
      if every(3,6) == true then
        circfill(c.x-0.5,c.y-0.5,7,7)
      end
    elseif c.shield == true then
      circfill(c.x-0.5,c.y-0.5,7,7)
      if every(4,8) == true then
        circfill(c.x-0.5,c.y-0.5,7,11)
      end
    end
  end

  shieldcircle(p,p.owner)

end

function cargui(p)
  --damage
  if p.damaged == true and p.shield == false then
    circfill(p.x-3+rnd(3),p.y-3+rnd(3),3,7)
  elseif p.damaged == true and p.shield == true then
    circfill(p.x-3+rnd(7),p.y-3+rnd(7),2,5)
  end
  --gui
  if p.active == true then
    if p.dead == false then --circle
      if p.vel > 0 then
        circ( p.x + p.attack_offset.x, p.y + p.attack_offset.y, 10+flr(p.vel), p.clr)
      else
        circ( p.x, p.y, 10, p.clr)
      end
    else
      circ(p.x,p.y,7,p.clr)
    end
    if p.dead == false then --reticule
      local ret = 9
      line( p.x+ret*sin(p.rot), p.y+ret*cos(p.rot), p.x+(ret+2)*sin(p.rot), p.y+(ret+2)*cos(p.rot),p.clr)

      line(p.x+ret*sin(p.dir),p.y+ret*cos(p.dir),p.x+(ret+3)*sin(p.dir),p.y+(ret+3)*cos(p.dir),7)
    elseif p.dead == true then --cross if dead
      line(p.x-5,p.y-5,p.x+5,p.y+5,p.clr)
      line(p.x+5,p.y-5,p.x-5,p.y+5,p.clr)
    end
  end

  if p.active == true then
    local next = p.nr + 1
    if p.nr == 3 or p.nr == 6 then
      next = p.nr - 2
    end
    local nx = car[next].x
    local ny = car[next].y
    circ(nx+5,ny+5,1,p.clr)
  end
end

function tracks(c)
  local length = 100
  if c.tracks_counter > 10 and c.dead == false then
    add(c.tracks_left_x,c.x+2.5*sin(c.rot-0.25))
    add(c.tracks_left_y,c.y+2.5*cos(c.rot-0.25))
    add(c.tracks_right_x,c.x+2.5*sin(c.rot+0.25))
    add(c.tracks_right_y,c.y+2.5*cos(c.rot+0.25))
    c.tracks_length += 1
    c.tracks_counter = 0
    if c.tracks_length >= length then
      del(c.tracks_left_x,c.tracks_left_x[1])
      del(c.tracks_left_y,c.tracks_left_y[1])
      del(c.tracks_right_x,c.tracks_right_x[1])
      del(c.tracks_right_y,c.tracks_right_y[1])
      c.tracks_length -= 1
    end

  else
    c.tracks_counter += 0.5
  end

  for x = c.tracks_length-length ,c.tracks_length do
    if x-1 >= 1 then
      line(c.tracks_left_x[x],c.tracks_left_y[x],c.tracks_left_x[x-1],c.tracks_left_y[x-1],0)
      line(c.tracks_right_x[x],c.tracks_right_y[x],c.tracks_right_x[x-1],c.tracks_right_y[x-1],0)
    end
  end
end

function caranim(p)
  p.x = p.x+(p.vel*0.05)*sin(p.rot)
  p.y = p.y+(p.vel*0.05)*cos(p.rot)
  p.vel = lerp(p.vel,p.throt,0.025)
  p.rot = home(p.rot,p.dir,p.rotspeed)
  if p.vel > 0.5 then p.rotspeed = 0.005/(p.vel*0.3) end
end

function attack_roll(c)
  c.hit = false
  if c.dead == false and pythagoras(c.x+c.attack_offset.x,c.y+c.attack_offset.y,car[c.target]) < 12+c.vel then
    if c.attack_counter == 0 and c.shield == false then
      c.hit = true
      sfx(7)
      car[c.target].damaged = true
      c.attack_counter += 0.5
    else
      c.attack_counter += 0.5
      if c.attack_counter > 5 then c.attack_counter = 0 end
    end
  end
end

function health(c)
  if c.damaged == true then
    local old_hp = c.hp
    if c.damagedcounter == 0 and c.shield == true then c.hp -= 0.01
    elseif c.damagedcounter == 0 and c.shield == false then c.hp -= 0.1 end
    if flr(old_hp) > flr(c.hp) then freeze = 5 sfx(6) end
    c.damagedcounter += 0.5
    if c.damagedcounter > 1 then
      c.damaged = false
      c.damagedcounter = 0
    end
  end
end

function collision(c)
  local collide = false

  for a = 1,6 do

    if c.nr != car[a].nr then
      if pythagoras(c.x,c.y,car[a]) < c.hitbox + car[a].hitbox then
        collide = true
      end
    end

    if collide == true then
      if c.timer == 0 then
        c.vel -= 1
        c.rot += 0.01
      end
    end
  end

  if collide == true then
    c.timer += 0.5
    collide = false
    if c.timer > 10 then
      c.timer = 0
    end
  end

end

function death_anim(c)
  if c.death_counter <= 15 then
    circfill(c.x,c.y,c.death_counter,10)
    circfill(c.x,c.y,15 - c.death_counter*0.7,7)
    c.death_counter += 0.5
  end
end

function turret(c,a,b)
  local length = {}
  for x = a,b do
    if car[x].dead == false then
      i = pythagoras(c.x,c.y,car[x])
      length[x] = i
    end
  end

  c.target = smallest(length)
  if c.dead == false then
    c.turret = rotlerp(c.turret,atan2(car[c.target].y-c.y,car[c.target].x-c.x),0.1)
  end
end

function smallest(t)
  local m = {1000,6}
  for k,v in pairs(t) do
    if m[1]>v then
         m[1]=v
         m[2]=k
    end
  end
  return m[2]
end

function control_active(x,plr)
  local p=plr.nr-1
  if x.active == true then
    if btnp(2,p) then
      if x.throt < 5 then
        x.throt += 1
        sfx(3)
      end
    end
    if btnp(3,p) then
      if x.throt > 0 then
        x.throt += -1
        sfx(4)
      end
    end
    if btn(1,p) then
      x.dir += 0.015
    end
    if btn(0,p) then
      x.dir += -0.015
    end

    if btn(5,p) and plr.guage > 0 and x.dead == false then
      x.shield = true
    else x.shield = false end
  end
end

function switch(plr)
  function activecheck(a,b)
    for x = a,b do
      if car[x].active == true then
        car[x].active = false
        car[x].shield = false
        return x
      end
    end
    return -1
  end

  if plr.nr == 1 then
    local active = activecheck(1,3)+1
    if active < 0 then
      for y = 1,3 do
        if car[y].dead == false then
          active=y
          break
        end
      end
    end
    if active < 0 then return end
    if active > 3 or active < 1 then
      active = 1
    end
    p1.car = active
    car[active].active = true
  end

  if plr.nr == 2 then
    local active = activecheck(4,6)+1
    if active < 0 then
      for y = 4,6 do
        if car[y].dead == false then
          active=y
          break
        end
      end
    end
    if active < 0 then return end
    if active > 6 or active < 4 then
      active = 4
    end
    car[active].active = true
  end
end

function set_active(a,plr)
  if a.active == true then
    plr.x = a.x
    plr.y = a.y
    plr.throt = a.throt
  end
end

function current_car(plr)
  for x = 1*plr.nr,3*plr.nr do
    set_active(car[x],plr)
  end
end

function lerp(a,b,t)
  return a + t*(b-a)
end

function rotlerp(a, b, t)
   while a < 0 do
      a = a + 1
   end
   while b < 0 do
      b = b + 1
   end
   diff = b - a
   if diff > 0.5 then
      b -= 1
   elseif diff < -0.5 then
      b += 1
   end
   return a + t * (b - a)
end

function home(current, goal, speed)
   while current < 0 do
      current = current + 1
   end
   while goal < 0 do
      goal = goal + 1
   end
   while current > 1 do
      current = current - 1
   end
   while goal > 1 do
      goal = goal - 1
   end
   diff = goal - current
   dir = 1
   if diff > 0.5 then
      dir = -1
   elseif diff < -0.5 then
      dir = -1
   end
   sign = 0
   if diff < -deadzone then
      sign = -1
   elseif diff > deadzone then
      sign = 1
   end
   return current + sign * speed * dir
end

function pythagoras(x,y,b)
  local p = {}
  p.x = b.x-x
  p.y = b.y-y
  return sqrt(p.x*p.x + p.y*p.y)
end

function ui(x,y,c,p)
  box = {}
  box.height = 6
  box.width = 30

  if p == p1 then
    x = x+(box.width+2)*(c.nr-1)
    status_position = box.height
  elseif p == p2 then
    x = x+(box.width+2)*(c.nr-3)
    status_position = 0-2-box.height
  end
  if c.dead == true then
    rectfill(x,y,x+box.width,y+box.height,0)
  elseif c.active == true then
    rectfill(x,y,x+box.width,y+box.height,p.clr)
  else
    rectfill(x,y,x+box.width,y+box.height,5)
  end

  --speed
  local throttle = x+13+c.throt*2
  local velocity = x+13+flr(c.vel*2)
  if velocity < 0 then velocity = 0 end
  rectfill(x+13,y+1,velocity,y+box.height-1,0)
  line(throttle,y+1,throttle,y+box.height-1,7)
  spr(37+c.throt,x+box.width-5,y+1)
  --health
  if c.damaged == true then pal(7,0) end
  spr(36,x+1,y+1) spr(37+c.hp,x+7,y+1)
  pal()
  --special status
  if c.status == "danger" and c.dead == false then
    if every(12,16) == true then spr(48,x,y+status_position,4,1) end
  elseif c.status == "auto" and c.dead == false then
    spr(32,x,y+status_position,4,1)
  end

end

function attack_offset(c)
  c.attack_offset.x = 1.5*c.vel*sin(c.rot)
  c.attack_offset.y = 1.5*c.vel*cos(c.rot)
end

function brake(p)
  if p.nr == 1 then
    for x = 1,3 do
      car[x].throt = 0
    end
  end

  if p.nr == 2 then
    for x = 4,6 do
      car[x].throt = 0
    end
  end
end

function shield(c,p)
  if c.shield == true then
    if every(2,10) == true then sfx(5, -1, 1) end
    p.guage -= 0.025
    if p.guage <= 0 then
      c.shield = false
    end
    c.hitbox = 7
  elseif c.shield == false then
    if p.guage < 5 then p.guage += 0.025 end
    c.hitbox = 3
  end
  if p.guage > 5 then p.guage = 5 end
end

function drawshield(x,y,p)
  if p.guage >= 1 then
    line(x,y,x+(94*(p.guage/5)),y,7)
    if p.guage < 2.5 then line(x,y,x+(94*(p.guage/5)),y,10) end
    for c = 1*p.nr,3*p.nr do
      if car[c].shield == true and every(4,8) == true then
        line(x,y,x+(94*(p.guage/5)),y,11)
      end
    end
  elseif p.guage < 1 and every(4,6) == true then
    line(x,y,x+(94*(p.guage/5)),y,7)
  end
end

function randomizeclr(plr)
  plr.clr = playercolors[flr(rnd(numberofcolors)+1)]
  del(playercolors,plr.clr)
  numberofcolors -= 1
end

function initiate_cars()
  for x=1,3 do
    carspawn(x,p1)
  end
  for x=4,6 do
    carspawn(x,p2)
  end

  car[1].x = center.x -30
  car[1].y = center.y -30
  car[1].dir = -0.125
  car[2].x = center.x
  car[2].y = center.y -40
  car[2].dir = 0
  car[3].x = center.x -40
  car[3].y = center.y
  car[3].dir = -0.25

  car[4].x = center.x +30
  car[4].y = center.y +30
  car[4].dir = -0.675
  car[5].x = center.x
  car[5].y = center.y +40
  car[5].dir = 0.5
  car[6].x = center.x +40
  car[6].y = center.y
  car[6].dir = 0.25

  car[1].active = true
  car[4].active = true
end

function _init()
  cls()
  init_splash()
  for x=0,24,1 do
    for y=0,24,1 do
      mset(x,y,flr(rnd(6)+1))
    end
  end
end

function ai(plr)
  local a = 1
  local b = 3
  if plr.nr == 1 then a=1 b=3 c=4 d=6
  elseif plr.nr == 2 then a=4 b=6 c=1 d=3 end

  if every(1,120+rnd(60)) == true and rnd(10) > 5 then
    switch(plr) sfx(2)
    for x = a,b do
      if car[x].active == true and car[x].dead == true then switch(plr) end
    end
    for x = a,b do
      if car[x].active == true and car[x].dead == true then switch(plr) end
    end
  end

  for x = a,b do
    if car[x].active == true then
      local cartarget = car[x].target
      for y = c,d do
        if car[y].hp < car[cartarget].hp then car[x].target = y
        end
      end
      local distance = pythagoras(car[x].x,car[x].y,car[cartarget])

      local target = atan2(car[cartarget].y-car[x].y,car[cartarget].x-car[x].x)
      car[x].dir = rotlerp(car[x].dir,target,0.05)

      if distance < 10 then car[x].dir += rnd(0.01) end
      if car[x].damaged == true and distance > 10-car[x].vel and car[x].dead == false then car[x].shield = true end
      if every(1,60+rnd(60)) == true then
        if distance > 15 and car[x].throt < 5 then
          if rnd(10) > 4 then car[x].throt += 1 sfx(3) end
        elseif car[x].throt > 0 and car[x].throt < 5 then
          if rnd(10) > 2 then car[x].throt += flr(rnd(2)) sfx(3) else car[x].throt -= flr(rnd(2)) sfx(4) end
        end
      end
    end
  end

end

function game_update()
  local countdown = flr(start_counter/30)
  if start_counter > 0 then start_counter -= 0.5 end
  if countdown > flr(start_counter/30) then sfx(4) end

  for x = 1,6 do
    local y = car[x].throt
    if y >= 1 then sfx(8+y,-1,1) end
  end

  frames += 0.5
  if frames > 30*100 then
    frames = 0
  end

  if start_counter == 0 then
    --controls
    if p1.ai == false then
      for x = 1,3 do
        control_active(car[x],p1)
      end

      if btnp(4,0) then
        switch(p1)
        sfx(2)
      end

      if btn(5,0) and btn(4,0) then
        brake(p1)
        sfx(4)
      end
    elseif p1.ai == true then ai(p1) end

    if p2.ai == false then

      for x = 4,6 do
        control_active(car[x],p2)
      end

      if btnp(4,1) then
        switch(p2)
        sfx(2)
      end

      if btn(5,1) and btn(4,1) then
        brake(p2)
        sfx(4)
      end
    elseif p2.ai == true then ai(p2) end

    current_car(p1)
    current_car(p2)

    --camera
    cam.x = lerp(cam.x, lerp(64,lerp(p1.x,p2.x,0.5),0.5)-64, 0.025)
    cam.y = lerp(cam.y, lerp(64,lerp(p1.y,p2.y,0.5),0.5)-64, 0.025)
  end

  if freeze > 0 then
    freeze -= 1
    return
  end

  --turret
  for x = 1,3 do
    turret(car[x],4,6)
    shield(car[x],p1)
  end
  for x = 4,6 do
    turret(car[x],1,3)
    shield(car[x],p2)
  end

  for x = 1,6 do
    attack_offset(car[x])
    attack_roll(car[x])
  end

  for x = 1,6 do
    caranim(car[x])
    health(car[x])
  end

  for x = 1,6 do
    collision(car[x])
  end

  for x = 1,6 do
    car[x].status = "happy"
    if car[x].hp < 1 then
      if car[x].dead == false then
        freeze = 20
        if car[x].active and x > 0 and x < 4 then
          switch(p1)
        end
        if car[x].active and x > 3 and x < 7 then
          switch(p2)
        end
        sfx(1)
      end
      car[x].dead = true
      car[x].throt = 0
      car[x].hp = 0
    elseif pythagoras(center.x,center.y,car[x]) > arena then
      car[x].dir = atan2(64-car[x].y,64-car[x].x)
      car[x].status = "auto"
      car[x].vel = lerp(car[x].vel,2,0.05)
    elseif car[x].hp < 2 then car[x].status = "danger" end
  end
  -- sudden death
  if start_counter == 0 then maintimer -= 0.5 end
  if arena > 25 then
    if maintimer <= 0 then arena -= 0.03 end
  end
  -- winners!
  for x = 1,3 do -- p1 lose
    if car[x].dead == true then p1.deathcount += 1 end
  end
  if p1.deathcount == 3 then p2.winner = true end
  p1.deathcount = 0
  for x = 4,6 do -- p2 lose
    if car[x].dead == true then p2.deathcount += 1 end
  end
  if p2.deathcount == 3 then p1.winner = true end
  p2.deathcount = 0
  if p1.winner == true or p2.winner == true then end_counter -= 0.5 end
  if end_counter < 0 then
    if p1.winner == true then
      p1.wins += 1
      p2.ready = false
      p2.wins = 0
      add(playercolors,p2.clr)
    end
    if p2.winner == true then
      p2.wins += 1
      p1.ready = false
      p1.wins = 0
      add(playercolors,p1.clr)
    end
    start_gfx_p1 = -100
    start_gfx_p2 = 228
    start_gfx_logo = -50
    start_gfx_circle = 150
    game_start = false
    end_counter = 90
    start_counter = 30
    maintimer = 60 * 30
    car = {}
    frames = 0
  end
end

function game_draw()

  map(0,0,-32,-32,24,24)

  for x=1,6 do
    tracks(car[x])
  end

  for x=1,6 do
    cardraw(car[x])
  end
  for x=1,6 do
    if car[x].dead == true then
      death_anim(car[x])
    end
    cargui(car[x])
  end
  if maintimer < 0 then
    if every(1,20) == true then
      circ(center.x,center.y,arena+6,5)
    end
    if every(2,20) == true then
      circ(center.x,center.y,arena+4,6)
    end
    if every(3,20) == true then
      circ(center.x,center.y,arena+2,6)
    end
  end
  circ(center.x,center.y,arena,7)
  camera(cam.x,cam.y)
  for x = 1,3 do
   ui(cam.x+3,cam.y+2,car[x],p1)
  end
  for x = 4,6 do
   ui(cam.x-2,cam.y+119,car[x],p2)
  end
  drawshield(cam.x+3,cam.y,p1)
  drawshield(cam.x+30,cam.y+127,p2)

  if maintimer >= 0 and start_counter == 0 then
    local x = center.x+arena*sin(maintimer/1800-0.25)
    local y = center.y+arena*cos(maintimer/1800-0.25)

    if x < cam.x+4 then x = cam.x+4 elseif x > cam.x+123 then x = cam.x+123 end
    if y < cam.y+13 then y = cam.y+13 elseif y > cam.y+114 then y = cam.y+114 end
    rectfill(x-4,y-3,x+4,y+3,7)
    if maintimer/30 >= 10 then
      print(flr(maintimer/30),x-3,y-2,0)
    else
      print("0" .. flr(maintimer/30),x-3,y-2,0)
    end
  end

  if p1.winner == true then
    local y = 62
    rectfill(cam.x,cam.y+y-1,cam.x+128,cam.y+y+5,p1.clr)
    spr(53,cam.x+36,cam.y+y)
    spr(38,cam.x+44,cam.y+y)
    spr(54,cam.x+52,cam.y+y,5,1)
  end
  if p2.winner == true then
    local y = 62
    rectfill(cam.x,cam.y+y-1,cam.x+128,cam.y+y+5,p2.clr)
    spr(53,cam.x+36,cam.y+y)
    spr(39,cam.x+44,cam.y+y)
    spr(54,cam.x+52,cam.y+y,5,1)
  end

  if start_counter > 0 then spr(37+(start_counter/30),center.x-3,center.y-3) end
end

function title_update()
  frames += 0.5
  gfx_p1_target = center.x-55
  gfx_p2_target = center.x-5
  logo_target = center.y+8
  gfx_circle_target = 0

  start_gfx_logo = lerp(start_gfx_logo,logo_target,0.025)
  start_gfx_p1 = lerp(start_gfx_p1,gfx_p1_target,0.025)
  start_gfx_p2 = lerp(start_gfx_p2,gfx_p2_target,0.025)
  start_gfx_circle = lerp(start_gfx_circle,gfx_circle_target,0.025)

  if frames > 30*60 then
    p1.ready = true
    p2.ready = true
    p1.ai = true
    p2.ai = true
  end

  if btnp(4,0) == true and p1.ready == false then
    p1.ready = true
    randomizeclr(p1)
    sfx(0)
  end
  if btnp(4,1) == true and p2.ready == false then
     p2.ready = true
     randomizeclr(p2)
     sfx(0)
  end

  if btnp(5,0) == true and p1.ready == false then
    p1.ready = true
    p1.ai = true
    randomizeclr(p1)
    sfx(0)
  end
  if btnp(5,1) == true and p2.ready == false then
     p2.ready = true
     p2.ai = true
     randomizeclr(p2)
     sfx(0)
  end

  if btnp(4,0) == true and p1.ai == true then
    p1.ai = false
    p1.ready = false
    p1.wins = 0
    add(playercolors,p1.clr)
    numberofcolors += 1
    start_counter = 30
  end
  if btnp(4,1) == true and p2.ai == true then
    p2.ai = false
    p2.ready = false
    p2.wins = 0
    add(playercolors,p2.clr)
    numberofcolors += 1
    start_counter = 30
  end


  if p1.ready == true and btnp(5,0) == true and p1.ai == false then
    p1.ready = false
    p1.wins = 0
    add(playercolors,p1.clr)
    numberofcolors += 1
    start_counter = 30
  end
  if p2.ready == true and btnp(5,1) == true and p2.ai == false then
    p2.ready = false
    p2.wins = 0
    add(playercolors,p2.clr)
    numberofcolors += 1
    start_counter = 30
  end
  if p1.ready == true and p2.ready == true then
    start_counter -= 1
    if start_counter < 0 then

      start_counter = 90

      --generate background
      for x=0,24,1 do
        for y=0,24,1 do
          mset(x,y,flr(rnd(6)+1))
        end
      end

      initiate_cars()
      p1.winner = false
      p1.deathcount = 0
      p1.guage = 5
      p2.winner = false
      p2.deathcount = 0
      p2.guage = 5
      arena = 65
      cam.x = 0
      cam.y = 0
      game_start = true
    end
  end
end

function title_draw()
  camera(0,0)

  map(0,0,-32,-32,24,24)
  if start_gfx_circle > 3 then
    circfill(center.x,center.y,start_gfx_circle,0)
  end

  pal(10,p1.clr)
  spr(128,start_gfx_p1,center.y-55,8,8)
  pal()
  pal(10,p2.clr)
  spr(136,start_gfx_p2,center.y-35,8,8)
  pal()

  if p1.ready == false then
    local x = center.x-50
    local y = start_gfx_logo*1.15
    rectfill(x,y,x+24,y+6,playercolors[flr(rnd(numberofcolors)+1)])
    print("ready?",x+1,y+1,7)
  elseif p1.ready == true then
    local x = center.x-50
    local y = start_gfx_logo*1.15
    rectfill(x,y,x+24,y+6,p1.clr)
    print("ready!",x+1,y+1,7)
  end
  if p2.ready == false then
    local x = center.x-50
    local y = start_gfx_logo*1.3
    rectfill(x,y,x+24,y+6,playercolors[flr(rnd(numberofcolors)+1)])
    print("ready?",x+1,y+1,7)
  elseif p2.ready == true then
    local x = center.x-50
    local y = start_gfx_logo*1.3
    rectfill(x,y,x+24,y+6,p2.clr)
    print("ready!",x+1,y+1,7)
  end

  if p1.wins > 0 then
    local x = center.x-25
    local y = start_gfx_logo*1.15
    if p1.wins < 10 then rectfill(x,y,x+24,y+6,7)
    else rectfill(x,y,x+28,y+6,7) end
    print("wins:" .. p1.wins, x+1, y+1,0)
  end
  if p2.wins > 0 then
    local x = center.x-25
    local y = start_gfx_logo*1.30
    if p2.wins < 10 then rectfill(x,y,x+24,y+6,7)
    else rectfill(x,y,x+28,y+6,7) end
    print("wins:" .. p2.wins, x+1, y+1,0)
  end

  if p1.ai == true then
    local x = center.x-59
    local y = start_gfx_logo*1.15
    rectfill(x,y,x+8,y+6,0)
    print("ai", x+1, y+1,p1.clr)
  end

  if p2.ai == true then
    local x = center.x-59
    local y = start_gfx_logo*1.30
    rectfill(x,y,x+8,y+6,0)
    print("ai", x+1, y+1,p2.clr)
  end


  pal(10,p1.clr)
  pal(11,p2.clr)
  spr(16,center.x-50,start_gfx_logo,9,1)
  pal()

  print(sub(credits.s,1+credits.p,32+credits.p),1,121,0)
  print(sub(credits.s,1+credits.p,32+credits.p),0,120,7)
  credits.p += 0.1c
  if credits.p > #credits.s then credits.p = 1 end
end

function _update()
  if game_start == false and trash.done == true then
    title_update()
  end
  if game_start == true then
    game_update()
  end
end

function _draw()
  cls()
  if game_start == false and trash.done == false then
    splash()
  elseif game_start == false and trash.done == true then
    title_draw()
  end

  if game_start == true then
    game_draw()
  end

  -- print(stat(1),cam.x+20,cam.y+20,11)
end

__gfx__
00000000111111111111111111111111111111111111111111111001000000000000000000000000050000000000500000000500050000500500005006050000
00000000111111110011111111111110101111111111111110111111550000555500005505500000005000005000650005006500056006500560065050000050
00000000111111110111111111111111111111111111111111111111066006600660066000660055006600500560600005606000006006000060060000600600
00000000111111111111111111111111111110011111111111111111000770000007700000077660000776650067700000677000000770000007700060077056
00000000111111111111111111101111011111111111111111111100000770000007700006677000566770000007760000077600000770000007700005077000
00000000111111111111100111111111111111111111111111111111066006600660066055006600050066000006065000060650006006000060060000600605
00000000111111111111111111111111111111111010011111111111550000555500005500000550000005000056000500560050056006500560065050000000
00000000111111111111111110000111111111111111111111111111000000000000000000000000000000500005000000500000050000500500005006005060
55555555555555555555555555555555555555555557777757777777777777777700000000000000000000000000000000000000000000000000000000000000
55777777777777755577777777777775557777777777777757aaaaa77777bbbbb700000000000000000000000000000000000000000000000000000000000000
57777755555777775777775555577777577777555557777757777aa75757777bb700000000000000000000000000000000000000000000000000000000000000
577777555557777757777755555777775777775555577777577aaaa775777bbbb700000000000000000000000000000000000000000000000000000000000000
57777755555777775777775555577777577777555557777757777aa75757777bb700000000000000000000000000000000000000000000000000000000000000
57777777777777755577777777777775557777777777777557aaaaa77777bbbbb700000000000000000000000000000000000000000000000000000000000000
57777755555555555555555555555555555555555555555557777777777777777700000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000070700007777700077770000777770007777700077077000777770000000000000000000000000000000000000000000
00000000000000000000000000000000777770007707700007770000000770000007700077077000770000000000000000000000000000000000000000000000
77777770770007707777777077777770777770007707700007770000777770000777700077777000777770000000000000000000000000000000000000000000
77000770770007700077700077000770077700007707700007770000770000000007700000077000000770000000000000000000000000000000000000000000
77777770770007700077700077000770007000007777700077777000777770007777700000077000777770000000000000000000000000000000000000000000
77000770770007700077700077000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77000770777777700077700077777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000007777770077000770077777007700077007777770077700000000000000000000000000000000000000000000
00000000000000000000000000000000000000007700770077000770007770007777077007700000077700000000000000000000000000000000000000000000
77777000770007700777777077777770000000007777770077070770007770007700777007777770077700000000000000000000000000000000000000000000
77000770777707707700000077000770000000007700000077070770007770007700077000000770000000000000000000000000000000000000000000000000
77000770770077707700777077000770000000007700077077777770077777007700077007777770077700000000000000000000000000000000000000000000
77000770770007707700077077777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777000770007700777777077000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000ccccc000ccccc0ccccc0c000ccc00000000000000000000000000000000
ccccccccccccccccccccccccccccccccccccccccccccc000000ccccccccccccc0cccc0ccc0ccc0cc000000cc00ccc0cc00000000000000000000000000000000
ccccccccccccccccccccccccccccccccccccccccccccc0cccc0ccccccccccccc0cccccccccccc0cccc0ccccc0cccc0cc00000000000000000000000000000000
ccccccccccccccccccccccccccccccccccccccc000000000000000000ccccccc0ccccccccc0000cccc0ccccc0cccc0cc00000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccc07777777777777777770cccccc0cccccccc0ccc0cccc0ccccc0cccc0cc00000000000000000000000000000000
cccccccccccc00000000cccccccccccccccccc07777777777777777770cccccc0cccc0cc0ccc00cccc0ccccc0cccc0cc00000000000000000000000000000000
cccccccccc000000000000cccccccccccccccc00000000000000000000ccccccc0000cccc000c0ccccc000cc0cccc0cc00000000000000000000000000000000
cccccccc0000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000
ccccccc000000000000000000ccccccccccccccccccccccccccccccccccccccccc0ccccc0c000cccccccc0ccc0000ccc00000000000000000000000000000000
ccccccc000000000000000000ccccccccccccccccccccccccccccccccccccccccc0ccccc00ccc0ccc000c0cc0cccc0cc00000000000000000000000000000000
ccccccc077000000000000770ccccccccccccccccccccccccccccccccccccccccc0ccccc0cccc0cc0ccc00cc0cccc0cc00000000000000000000000000000000
ccccccc077770000000077770ccccccccccccccccccccccccccccccccccccccccc0ccccc0cccc0cc0cccc0cc000000cc00000000000000000000000000000000
ccccccc070777777777777070ccccccccccccccccccccccccccccccccccccccccc0ccccc00ccc0cc0cccc0cc0ccccccc00000000000000000000000000000000
ccccccc070777777777777070ccccccccccccccccccccccccccccccccccccccccc0ccccc0c000ccc0ccc00cc0cccc0cc00000000000000000000000000000000
ccccccc070777077770777070ccccccccccccccccccccccccccccccccccccccccc0ccccc0cccccccc000c0ccc0000ccc00000000000000000000000000000000
ccccccc070777077770777070ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000
ccccccc070777077770777070ccccccccccccccccccc00000000cccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000
ccccccc070777077770777070ccccccccccccccccc007777777700cccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000
ccccccc070777077770777070ccccccccccccccc0077777777777700cccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000
ccccccc070777077770777070cccccccccccccc077777000000777770ccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000
ccccccc070777077770777070ccccccccccccc07777770777707777770cccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000
ccccccc070777077770777070ccccccccccccc00777777777777777700cccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000
ccccccc070777077770777070ccccccccccccc07007777777777770070cccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000
ccccccc070777077770777070ccccccccccccc00770077777777007700cccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000
ccccccc070777077770777070cccccccccccccc000770000000077000ccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000
ccccccc077777077770777770cccccccccccccccc00077777777000ccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000
cccccccc0077707777077700cccccccccccccccccccc00000000cccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000
cccccccccc007777777700cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000
cccccccccccc00000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000aaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000aaaaaaaaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000aaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaaaaaaaaaaaaaa7aa7aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aaaaaaaaaaaaaaa7aa77a7aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaaaaaaaaaaa77777aaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000aaaaaaabbaaaaaaaa7a777a7aaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000aaaaaabbbbaaaaaaaa7aa7aaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000aaaaaaaabbaaaaaaaaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa00000000000000000000000000000000000007700007777000000000000000000000000000000000000000000000
000000aaaaaaaaaaaaaaaaaaaa677777777777777777776660000000000000000000000000777777777700000000000000000000000000000000000000000000
00000aaaaaaaaaaaaaaaaaaaa666666666666666666666655600000000000000000000000007777779770000000000000aaaaa6aaaa000000000000000000000
00000aaaaaaaaaaaaaaaaaaaa666666666666666666666555600000000000000000000000077777799970000000000aaaaaa66aaaaaaaa000000000000000000
00000aaaaaaaaaaaaaaaaaaaaa555555566666666666666556000000000000000000000000077779976000000000aaaaaaaaa6aaaaaaaaaa0000000000000000
00000aaaaaaaaaaaaaaaaaaaaaaaaaaaa5555555555555666000000000000000000000000000777796666000000aaaaaaaaa6aaaaaa7aa7aa000000000000000
000005aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa500000000000000000000000000000000000000077779566666000aaaaaaaaaaaaaaa7aa77a7aa00000000000000
00000655aaaaaaaaaaaaaaaaaaaaaaaaaa5560000000000000000000000000000000000000000077705566666aaaaaaaaaaaaaaaaa77777aaaa0000000000000
00000a6655aaaaaaaaaaaaaaaaaaaaaa5566a000000000000000000000000000000000000000000000005566aaaaaaaaaaaaaaaaa7a777a7aaaa000000000000
00000aaa665555aaaaaaaaaaaaaa555566aaa000000000000000000000000000000000000000000000000055aaaaaaaaaaaaaaaaaa7aa7aaaaaa000000000000
00000aaaaa6666555555555555556666aaaaa00000000000000000000000000000000000000000000000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa00000000000
00000aaaaaaaaa66666666666666aaaaaaaaa00000000000000000000000000000000000000000000000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa00000000000
000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa000000000000000000000000000000000000000000000000000aaaaaaaaaaaaaaaaa6a6aaaaaaaaaa00000000000
000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaa600000000000000000000000000000000000000000000000000aaaaaaaaaaaaaaaaaaa6aaaaaaaaaaaa0000000000
000055aaaaaaaaaaaaaaaaaaaaaaaaaaaaa660000000000000000000000000000000000000000000000000aaaaaaaaaaaaaaaaaaaa6aaaaaaaaaaa0000000000
0000555aaaaaaaaaaaaaaaaaaaaaaaaaaaa566055550000000000000000000000000000000000000000000aaaaaaaaaaaa6aaaaaaaa6aaaaaaaaaa0000000000
0005556aaaaaaaaaaaaaaaaaaaaaaaaaaaa056655555000000000000000000000000000000000000000000aaaaaaaa6aa6aaaaaaaa6a6aaaaa66aa0000000000
00055666aaaaaaaaaa666aaaaaaaaaaaaa00066655550000000000000000000000000000000000000000005aaaaaaaa6a6aaaaaaaaaaaaaaaaa6a50000000000
000556666aaaaaaaa6665aaaaaaaaaaaa00005666655500000000000000000000000000000000000000000655aaaaaaa6aaaaaaaaaaaaaaaaaa5560000000000
0005566550aaaaaa6665aaaaaaaaaaaa000005555655500000000000000000000000000000000000000000a6655aaaaa6aaaaaaaaaaaaaaaa5566a0000000000
00055665500aaaa6665aaaaaaaaaaaa0000005566655500000000000000000000000000000000000000000aaa665555aa6aaaaaaaaaaa555566aaa0000000000
000556655000a55556aaaaaaaaaaa500000005566655500000000000000000000000000000000000000000aaaaa6666555555555555556666aaaaa0000000000
000555555000555555aaaaaaaa5555000000055666555000000000000000000000000000000000000055556666aaaaa66666666666666aa6aaaaaa0000000000
000055550000555555000000005555000000055565555000000000000000000000000000000000000555555665aaaaaaa6aaaaaaaaaaaaa6aaaaa60000000000
00005555000555555550000000055000000000555555000000000000000000000000000000000000055555565a6aaaaaa6aaaaaaaaaaaaa6aaaa660000000000
0000000000055655555000000000000000000055555500000000000000000000000000000000000055555555aaa6aaa6aa66aaaaaaaaaa6aaaaa666000000000
0000000000056665555000000000000000000005555000000000000000000000000000000000000055655555aaaa6aaa6aaaaaaaaaaaaa6aaaaa566655550000
0000000000056665555000000000000000000000000000000000000000000000000000000000000056665555aaaaa6aaaaaaaaaaaaaaaaaaaaaa056665555000
00000000000566655550000000000000000000000000000000000000000000000000000000000000566655550aaaaaaaaaa666aaaaaaaaaaaaa0006666555500
000000000005565555500000000000000000000000000000000000000000000000000000000000005666555500aaaaaaaa6665aaaaaaaaaaaa00005666655550
0000000000055555555000000000000000000000000000000000000000000000000000000000000055655555000aaaaaa6665aaaaaaaaaaaa000055555665550
00000000000055555500000000000000000000000000000000000000000000000000000000000000555555550000aaaa6665aaaaaaaaaaaa5000055566665550
000000000000555555000000000000000000000000000000000000000000000000000000000000000555555000000a55556aaaaaaaaaaa555000055566665550
000000000000055550000000000000000000000000000000000000000000000000000000000000000555555000000555555aaaaaaaa555555000055566665550
00000000000000000000000000000000000000000000000000000000000000000000000000000000005555000000055555500000000555550000055566655550
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555555550000000055500000005556655500
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000556655550000000000000000005555555500
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005566665550000000000000000000555555000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005566665550000000000000000000055550000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005566665550000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005566665550000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000556655550000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555555550000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555555500000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555500000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005550000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0103010101010101010000000101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0103030101010100030101010001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101030101020300020300000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010201010102030103000001030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010102000100000001030101030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101030103000003010103000303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101020102020000030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010400003f7703d76038240314402a220230201e410180100c0100a01000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000267105661066610766109661076510365102641026410163101631016210162101611006110061100611006000060000600006000060000600006000060000600006000060000600006000060000600
000400000305104021045010250106300063000630000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01030000325701a5001a5001a5001a5001a5001a5001a500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
010300002b5701a5001a5001a5001a5001a5001a5001a500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
0007000010701107411073110711127000c7000070000700007000070000700007000070000700007000070000700007000200000700007000070000700007000070000700007000070000700007000070000700
000a00001267001645016150120133200012000220003200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200003664232612016000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
011000100c173286030e6031c6031c653286030e6031c6030c103286030c1731c6031c653286030e6031c6030e6000e600106000e6000e6000e6000e600006002460126601286010060000600006000060000600
0006000006151011110c101181010c101181010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101
0006000006151021110c101181010c101181010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101
0006000006151041110c101181010c101181010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101
0006000006151071110c101181010c101181010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101
00060000061510b1110c101181010c101181010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101
0119000024610186102a171171210d15632536265361c516105160650514505015060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 08090a44
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

