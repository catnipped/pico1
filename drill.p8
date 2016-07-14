pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
p = {}
mapx = 16
mapy = 20

cam = {}
camspeed = 0.2
frames = 0
gemtypes = {}
gemtypes[1] = {nr = 1, clr = 3}
gemtypes[2] = {nr = 3, clr = 11}
gemtypes[3] = {nr = 5, clr = 10}
game_screen = "splash"


fntspr=64
fntdefaultcol=0
fntx={}
fnty={}


--call in _init to setup font
function initfont()
 top="abcdefghijklmnopqrstuvwxyz"
 bot="0123456789.,^?()[]:/\\=\"'+-"
 fntsprx=(fntspr%16)*8
 fntspry=flr((fntspr/16))*8
 for i=1,#top do
  x=fntsprx+(i-1)*3
  c=sub(top,i,i)
  fntx[c]=x
  fnty[c]=fntspry
  c=sub(bot,i,i)
  fntx[c]=x
  fnty[c]=fntspry+3
 end
end

--prints text in 3x3 font
function print3(str,x,y,col)
 col=col or fntdefaultcol
 pal(7,col)
 for i=1,#str do
  c=sub(str,i,i)
  if fntx[c] then
   sspr(fntx[c],fnty[c],3,3,x+(i-1)*4,y)
  else
   print(c,x+(i-1)*4,y-2,col)
  end
 end
 pal(7,7)
end

function tablecontains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

function every(a,b) -- a: number of frames true b: 1-30 where 1 is every frame, 30 is once each second.
  return frames % b < a
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

function make_spark(x,y,init_size,col) local s = {}
  s.x=x
  s.y=y
  s.col = col
  s.width = init_size
  s.width_final = init_size + rnd(3)+1
  s.t=0
  s.max_t = rnd(12)
  s.dx = (rnd(.8)-.4)
  s.dy = (rnd(.8)-.4)
  s.ddy = .005
  add(particles,s)
  return s
end

function move_spark(sp)
  if (sp.t > sp.max_t) then
     del(particles,sp)
  end
  if (sp.t < sp.max_t) then
    sp.width += -0.1
    sp.width = min(sp.width,sp.width_final)
  end
  sp.x = sp.x + sp.dx
  sp.y = sp.y + sp.dy
  sp.dy= sp.dy+ sp.ddy
  sp.t = sp.t + 1
end

function draw_spark(s) circfill(s.x, s.y,s.width+1, 0) circfill(s.x, s.y,s.width, s.col) end

function drill(m)
	local x = p[m].x / 8
	local y = p[m].y / 8
	local drilled = false
	if p[m].dir == 0 and mget(x,y-1) == 9 then mset(x,y-1,8) drilled = true y -= 1 end
	if p[m].dir == 2 and mget(x,y+1) == 9 then mset(x,y+1,8) drilled = true y += 1 end
	if p[m].dir == 1 and mget(x+1,y) == 9 then mset(x+1,y,8) drilled = true x += 1 end
	if p[m].dir == 3 and mget(x-1,y) == 9 then mset(x-1,y,8) drilled = true x -= 1 end
	if drilled then
		cam[m].x += rnd(8)
		cam[m].x -= rnd(8)
		cam[m].y += rnd(8)
		cam[m].y -= rnd(8)
    for z = 0,16 do
      make_spark(x*8+rnd(8),y*8+rnd(8),rnd(3),7)
    end
    add(debris,{x = x*8, y = y*8, spr=flr(rnd(3))})
		return true
	else
		return false
	end
end

function push(a,b)
  local ax = p[a].x / 8
	local ay = p[a].y / 8
  local bx = p[b].x / 8
  local by = p[b].y / 8
	local pushed = false
  if bx == ax and by == ay then
  	if p[a].dir == 0 and mget(ax,ay-1) ~= 9 and by >= 0 then p[b].y -= 8 pushed = true end
  	if p[a].dir == 2 and mget(ax,ay+1) ~= 9 and bx <= mapx then p[b].y += 8 pushed = true end
  	if p[a].dir == 1 and mget(ax+1,ay) ~= 9 and bx >= 0 then p[b].x += 8 pushed = true end
  	if p[a].dir == 3 and mget(ax-1,ay) ~= 9 and by <= mapy+2 then p[b].x -= 8 pushed = true end
  end
	if bx == ax and by == ay and pushed == false then
    if p[a].dir == 0 and mget(ax,ay-1) == 9 then p[a].y += 8 end
  	if p[a].dir == 2 and mget(ax,ay+1) == 9 then p[a].y -= 8 end
  	if p[a].dir == 1 and mget(ax+1,ay) == 9 then p[a].x -= 8 end
  	if p[a].dir == 3 and mget(ax-1,ay) == 9 then p[a].x += 8 end
	end
end

function init_actions()
  forward = function (m)
  	if drill(m) == false then
  		add(p[m].past,{x = p[m].x,y = p[m].y})
  		if 			p[m].dir == 0 then p[m].y -= 8
  		elseif  p[m].dir == 1 then p[m].x += 8
  		elseif  p[m].dir == 2 then p[m].y += 8
  		elseif  p[m].dir == 3 then p[m].x -= 8
  		end
  		pickup()
      if m == 1 then push(1,2)
      elseif m == 2 then push(2,1) end
  	end

  end

  backward = function (m)
  	add(p[m].past,{x = p[m].x,y = p[m].y})
    local x = p[m].x / 8
    local y = p[m].y / 8
    local dir = p[m].dir
  	if 			p[m].dir == 0 and mget(x,y+1) ~= 9 then p[m].y += 8 pickup() p[m].dir = 2
  	elseif  p[m].dir == 1 and mget(x-1,y) ~= 9 then p[m].x -= 8 pickup() p[m].dir = 3
  	elseif  p[m].dir == 2 and mget(x,y-1) ~= 9 then p[m].y -= 8 pickup() p[m].dir = 0
  	elseif  p[m].dir == 3 and mget(x+1,y) ~= 9 then p[m].x += 8 pickup() p[m].dir = 1
  	end
    if m == 1 then push(1,2)
    elseif m == 2 then push(2,1) end
    p[m].dir = dir
  end

  turnr = function (m)
  	p[m].dir += 1
  	if p[m].dir > 3 then p[m].dir = 0 end
  end

  turnl = function (m)
  	p[m].dir -= 1
  	if p[m].dir < 0 then p[m].dir = 3 end
  end

  uturn = function (m)
  	p[m].dir += 1
  	if p[m].dir > 3 then p[m].dir = 0 end
  	p[m].dir += 1
  	if p[m].dir > 3 then p[m].dir = 0 end
  end

  fast = function (m)
  	if drill(m) == false then
  		add(p[m].past,{x = p[m].x,y = p[m].y})
  		if 			p[m].dir == 0 then p[m].y -= 8
  		elseif  p[m].dir == 1 then p[m].x += 8
  		elseif  p[m].dir == 2 then p[m].y += 8
  		elseif  p[m].dir == 3 then p[m].x -= 8
  		end
  		pickup()
      if m == 1 then push(1,2)
      elseif m == 2 then push(2,1) end
  	end

  	if drill(m) == false then
  		add(p[m].past,{x = p[m].x,y = p[m].y})
  		if 			p[m].dir == 0 then p[m].y -= 8
  		elseif  p[m].dir == 1 then p[m].x += 8
  		elseif  p[m].dir == 2 then p[m].y += 8
  		elseif  p[m].dir == 3 then p[m].x -= 8
  		end
  		pickup()
      if m == 1 then push(1,2)
      elseif m == 2 then push(2,1) end
  	end
  end

  triple = function (m)
  	if drill(m) == false then
  		add(p[m].past,{x = p[m].x,y = p[m].y})
  		if 			p[m].dir == 0 then p[m].y -= 8
  		elseif  p[m].dir == 1 then p[m].x += 8
  		elseif  p[m].dir == 2 then p[m].y += 8
  		elseif  p[m].dir == 3 then p[m].x -= 8
  		end
  		pickup()
      if m == 1 then push(1,2)
      elseif m == 2 then push(2,1) end
  	end

  	if drill(m) == false then
  		add(p[m].past,{x = p[m].x,y = p[m].y})
  		if 			p[m].dir == 0 then p[m].y -= 8
  		elseif  p[m].dir == 1 then p[m].x += 8
  		elseif  p[m].dir == 2 then p[m].y += 8
  		elseif  p[m].dir == 3 then p[m].x -= 8
  		end
  		pickup()
      if m == 1 then push(1,2)
      elseif m == 2 then push(2,1) end
  	end

  	if drill(m) == false then
  		add(p[m].past,{x = p[m].x,y = p[m].y})
  		if 			p[m].dir == 0 then p[m].y -= 8
  		elseif  p[m].dir == 1 then p[m].x += 8
  		elseif  p[m].dir == 2 then p[m].y += 8
  		elseif  p[m].dir == 3 then p[m].x -= 8
  		end
  		pickup()
      if m == 1 then push(1,2)
      elseif m == 2 then push(2,1) end
  	end
  end

  tele = function (m)
  	local x = p[m].x / 8
  	local y = p[m].y / 8
  	if p[m].dir == 0 and mget(x,y-1) == 9 then
  		y -= 8
  		while mget(x,y) == 9 do y -= 8 end
  	end
  	if p[m].dir == 2 and mget(x,y+1) == 9 then
  		y += 8
  		while mget(x,y) == 9 do y += 8 end
  	end
  	if p[m].dir == 1 and mget(x+1,y) == 9 then
  		x += 8
  		while mget(x,y) == 9 do x += 8 end
  	end
  	if p[m].dir == 3 and mget(x-1,y) == 9 then
  		x -= 8
  		while mget(x,y) == 9 do x -= 8 end
  	end
  	p[m].x = x * 8
  	p[m].y = y * 8
  end
end

function lerp(a,b,t)
  return a + t*(b-a)
end

function initiatedeck()
  cards = {
    { txt = {"for","ward"},
      action = forward,
      clr = 5,
      spr = 80
    },
    { txt = {"rev-","erse"},
      action = backward,
      clr = 5,
      spr = 81
    },
    { txt = {"turn","left"},
      action = turnl,
      clr = 5,
      spr = 83
    },
    {	txt = {"turn","rght"},
      action = turnr,
      clr = 5,
      spr = 82
    },
    {	txt = {"u-","turn"},
      action = uturn,
      clr = 5,
      spr = 84
    },
    {	txt = {"fast","frwd"},
      action = fast,
      clr = 5,
      spr = 85
    },
    {	txt = {"trpl","frwd"},
      action = triple,
      clr = 5,
      spr = 87
    },
    {	txt = {"tele","dig"},
      action = tele,
      clr = 5,
      spr = 86
    }
  }

	deck = {}
	add(deck, cards[1])
	add(deck, cards[1])
	add(deck, cards[1])
  add(deck, cards[1])
	add(deck, cards[2])
	add(deck, cards[3])
  add(deck, cards[3])
  add(deck, cards[4])
	add(deck, cards[4])
	add(deck, cards[5])
	add(deck, cards[6])
end

function resetcards()
  local a = 0
  local cardid = 1
  for a = 0,3 do
    local x = flr(rnd(#deck))+1
    card[a] = {}
		card[a].action = deck[x].action
		card[a].rot = -0.3
		card[a].dir = 0
		card[a].x = 0
		card[a].y = 0
		card[a].txt = {deck[x].txt[1],deck[x].txt[2]}
		card[a].clr = deck[x].clr
		card[a].spr = deck[x].spr
    card[a].id = cardid
    cardid += 1
    a += 1
  end

end

function resettimeline()
	timeline = {}
	timeline_actor = {}
	timeline_counter = 0
end

function activator()
	if timeline_counter > count(timeline) then
		 for m = 1,2 do p[m].load = 0 end
		 resetcards()
		 activate = false
		 turn += 1

     --winner?
     if p[1].score >= 15 or p[2].score >= 15 or turn >= 15 then
       if p[1].score > p[2].score then p[1].win = true
       elseif p[1].score < p[2].score then p[2].win = true end
     end
     if p[1].win or p[2].win then game_screen = "win" return end

		 cardshuffle = false
     p[1].cardinv = {}
     p[2].cardinv = {}
     p[1].shuffle = false
     p[2].shuffle = false
		 for a = 0,3 do card[a].rot = -0.3 end
		return
	elseif timeuntilturn == 30 then
		x = timeline_actor[timeline_counter]

		timeline[timeline_counter](x)
		p[timeline_actor[timeline_counter]].load -= 1
		timeline_counter += 1
		timeuntilturn = 0
    dynamic_rock()
    for m = 1,2 do
      p[m].x = mid(0,p[m].x,8*(mapx))
      p[m].y = mid(0,p[m].y,8*(mapy+2))
    end
	else
		timeuntilturn += 1
	end
end

function pickup()
	for o in all(objects) do
		for n = 1,2 do

			if o.x == p[n].x and o.y == p[n].y and tablecontains(p[n].inv, o.id) == false then
				if o.spr == 33 then
					add(p[n].inv, o.id)
				elseif o.spr == 17 then
					local z = 6 + flr(rnd(#deck-6))
					add(deck,cards[z])
					deck[#deck].clr = p[n].clr
          for z = 0,8 do
            make_spark(o.x+rnd(8),o.y+rnd(8),2,p[n].clr)
          end
					del(objects,o)
				end
			end
      update_invworth(n)
		end
	end
end

function update_invworth(n)
  p[n].invworth = 0
  for g in all(p[n].inv) do
    p[n].invworth += objects[g].worth
  end
  p[n].invworth += #p[n].inv-1
end

function score(n)
  if p[n].y > 8*(mapy) then
    if p[n].invworth < 0 then p[n].invworth = 0 end
    p[n].score += p[n].invworth
    p[n].invworth = 0
  end
  if p[n].score < 0 then p[n].score = 0 end
end

function dynamic_rock()
	for x = 0,mapx do
		for y = 0,mapy do
			if mget(x,y) ~= 9 then
				local z = 0
				local dir = {}
				if mget(x-1,y) == 9 then z += 1 dir.west = true else dir.west = false end
				if mget(x+1,y) == 9 then z += 1 dir.east = true else dir.east = false end
				if mget(x,y-1) == 9 then z += 1 dir.north = true else dir.north = false end
				if mget(x,y+1) == 9 then z += 1 dir.south = true else dir.south = false end
				if z == 4 then mset(x,y,61) end
				if z == 3 then
					if dir.west == false then mset(x,y,60) end
					if dir.east == false then mset(x,y,58) end
					if dir.north == false then mset(x,y,59) end
					if dir.south == false then mset(x,y,57) end
				end

				if z == 2 then
					if dir.west == true and dir.north == true then mset(x,y,42) end
					if dir.east == true and dir.north == true then mset(x,y,41) end
					if dir.west == true and dir.south == true then mset(x,y,43) end
					if dir.east == true and dir.south == true then mset(x,y,44) end
					if dir.north == true and dir.south == true then mset(x,y,45) end
					if dir.west == true and dir.east == true then mset(x,y,46) end
				end

				if z == 1 then
					if dir.west == true then mset(x,y,26) end
					if dir.east == true then mset(x,y,28) end
					if dir.north == true then mset(x,y,25) end
					if dir.south == true then mset(x,y,27) end
				end

				if z == 0 then mset(x,y,8) end
			end
		end
	end
end

function ui()
  --ui bar
  line(cam[2].x+63,cam[2].y,cam[2].x+63,cam[2].y+127,p[1].clr)
	line(cam[2].x+64,cam[2].y,cam[2].x+64,cam[2].y+127,p[2].clr)
	rectfill(cam[2].x,cam[2].y,cam[2].x+128,cam[2].y+6,0)
	line(cam[2].x,cam[2].y+7,cam[2].x+63,cam[2].y+7,p[1].clr)
	line(cam[2].x+64,cam[2].y+7,cam[2].x+128,cam[2].y+7,p[2].clr)

  --vignette
  spr(18,cam[2].x,cam[2].y+8,3,3)
	spr(18,cam[2].x+39,cam[2].y+8,3,3,true,false)
	spr(18,cam[2].x,cam[2].y+104,3,3,false,true)
	spr(18,cam[2].x+39,cam[2].y+104,3,3,true,true)

	spr(18,cam[2].x+65,cam[2].y+8,3,3)
	spr(18,cam[2].x+104,cam[2].y+8,3,3,true,false)
	spr(18,cam[2].x+65,cam[2].y+104,3,3,false,true)
	spr(18,cam[2].x+104,cam[2].y+104,3,3,true,true)

  --ready to shuffle
  if p[1].shuffle and every(10,20) then print3("shuffle please", cam[2].x+7,cam[2].y+125,p[1].clr) end
  if p[2].shuffle and every(10,20) then print3("shuffle please", cam[2].x+66,cam[2].y+125,p[2].clr) end

  --score
  pal(5,p[1].clr)
  spr(32,cam[2].x+22,cam[2].y)
  pal(5,5)
  if flr(p[1].oldscore) < 10 then
    print("0" .. flr(p[1].oldscore),cam[2].x+29,cam[2].y+1,p[1].clr)
  else
    print(flr(p[1].oldscore),cam[2].x+29,cam[2].y+1,p[1].clr)
  end
  if p[1].invworth > 0 then
    print("+" .. p[1].invworth,cam[2].x+38,cam[2].y+1,5)
  end

  --turn wheel
  local x = cam[2].x-1
  local y = cam[2].y+1
  local offset = 13 + p[1].loadspin * 2
  circ(x-1,y,offset,0)
  circ(x+1,y,offset,0)
  circ(x,y,offset,7)
  for a = 1,4 do
    if p[1].load >= a then
      pal(7,p[1].clr)
      if card[a-1].clr == p[2].clr then pal(7,p[2].clr) end
    end
    b = 0.09 * -a
    spr(16,x-3+offset*sin(-0.09+b+(p[1].loadspin*0.09)),y-3+offset*cos(-0.09+b+(p[1].loadspin*0.09)))
    pal(7,7)
  end

  --score
  local l = cam[2].x+90
  if p[2].invworth > 0 then
    l -= 8
    if p[2].invworth >= 10 then l-= 4 end
    print("+" .. p[2].invworth,l+16,cam[2].y+1,5)
  end
  pal(5,p[2].clr)
  spr(32,l,cam[2].y)
  pal(5,5)

  if flr(p[2].oldscore) < 10 then
    print("0" .. flr(p[2].oldscore),l+7,cam[2].y+1,p[2].clr)
  else
    print(flr(p[2].oldscore),l+7,cam[2].y+1,p[2].clr)
  end

  --turn wheel
  local x = cam[2].x+128-1
  local y = cam[2].y+1
  local offset = 13 + p[2].loadspin * 2
  circ(x-1,y,offset,0)
  circ(x+1,y,offset,0)
  circ(x,y,offset,7)
  for a = 1,4 do
    if p[2].load >= a then
      pal(7,p[2].clr)
      if card[a-1].clr == p[1].clr then pal(7,p[2].clr) end
    end
    b = 0.09 * a
    spr(16,x-3+offset*sin(0.09+b-(p[2].loadspin*0.09)),y-3+offset*cos(0.09+b-(p[2].loadspin*0.09)))
    pal(7,7)
  end

  --card row
	if cardshuffle == false then
		cardrow = lerp(cardrow,110,0.15)
	elseif cardshuffle == true then
		cardrow = lerp(cardrow,80,0.3)
	end
	circ(cam[2].x+64,cam[2].y+209,cardrow,0)
	circ(cam[2].x+64,cam[2].y+211,cardrow,0)
	circ(cam[2].x+64,cam[2].y+210,cardrow,7)

  --turn timer
	if activate == true then
		timelinerow = lerp(timelinerow,30,0.15)
	elseif activate == false then
		timelinerow = lerp(timelinerow,0,0.3)
	end
	circ(cam[2].x+64,cam[2].y-17,timelinerow,0)
	circ(cam[2].x+64,cam[2].y-19,timelinerow,0)
	circ(cam[2].x+64,cam[2].y-18,timelinerow,7)
	local timeh = cam[2].y+timelinerow-23
	rect(cam[2].x+55,timeh-1,cam[2].x+73,timeh+11,0)
	rectfill(cam[2].x+56,timeh,cam[2].x+72,timeh+10,7)
	print3("turn",cam[2].x+57,timeh+1,5)
	print(turn .. "/10" ,cam[2].x+57,timeh+5,0)

	for a = 0,3 do --cards
		local offset = 100
		card[a].x = cam[2].x+51+(offset*sin(card[a].rot-0.373))
		card[a].y = cam[2].y+195+(offset*cos(card[a].rot-0.373))
		local x = card[a].x
		local y = card[a].y
		local h = 16
		local w = 16
		if card[a].clr == 5 then
			rectfill(x+7,y-1,x+9+w,y+h+1,0)
			rectfill(x-1,y-1,x+8,y+8,0)
			rectfill(x+8,y,x+8+w,y+h,7)
			rectfill(x,y,x+7,y+7,7)
			spr(card[a].spr, x+9, y+9)
			print3(card[a].txt[1],x+9,y+1,card[a].clr)
			print3(card[a].txt[2],x+9,y+5,card[a].clr)
			spr(3+a+1,x,y)
		else
			rectfill(x+7,y-1,x+9+w,y+h+1,0)
			rectfill(x-1,y-1,x+8,y+8,0)
			rectfill(x+8,y,x+8+w,y+h,card[a].clr)
			rectfill(x,y,x+7,y+7,7)

      spr(card[a].spr, x+9, y+9)
			print3(card[a].txt[1],x+9,y+1,7)
			print3(card[a].txt[2],x+9,y+5,7)
      print("\139", x, y,9)
			spr(3+a+1,x,y)
		end
	end
end

function draw_menu()
  camera()
  local f = frames
  local loop = 578
  if frames > loop then f -= flr(frames / loop) * loop end

  f = f / 2
  pal(7,5)
  map(0,0,-4,-168+f,mapx+1,mapy+1)
  pal(7,7)
  spr(18,0,0,3,3)
  spr(18,64+39,0,3,3,true,false)
  spr(18,0,104,3,3,false,true)
  spr(18,64+39,104,3,3,true,true)
  logo(32,50)
end

function draw_game()

  	for m = 1,2 do
      local color = 0
  		if m == 2 then clip(0,0,64,128) color = p[1].clr end
  		if m == 1 then clip(64,0,128,128) color = p[2].clr end
  		rect(-1,-1,((mapx+1)*8),((mapy+3)*8),7)
      for d in all(debris) do
        spr(12+d.spr,d.x,d.y)
      end
      if btn(5,0) and m == 2 then
        for x = p[1].x-64,p[1].x+64,8 do
          for y = p[1].y-64,p[1].y+64,8 do
            if x > -1 and x < ((mapx+1)*8) and y > -1 and y < ((mapy+3)*8) then
              spr(11,x,y)
            end
          end
        end
      elseif btn(5,1) and m == 1 then
        for x = p[2].x-64,p[2].x+64,8 do
          for y = p[2].y-64,p[2].y+64,8 do
            if x > -1 and x < ((mapx+1)*8) and y > -1 and y < ((mapy+3)*8) then
              spr(11,x,y)
            end
          end
        end
      end

      map(0,0,0,0,mapx+1,mapy+1)
      line(0,(mapy+1)*8-1,(mapx+1)*8,(mapy+1)*8-1,7)
  		map(0,mapy+1,0,(mapy+1)*8,mapx+1,mapy+8)

      rectfill(3*8, ((mapy+1)*8)+4, (mapx-2)*8, ((mapy+2)*8)+2, 0)
      print("delivery area  gem pls", (3*8)+1, ((mapy+1)*8)+5,7)


  		for o in all(objects) do
        if o.x ~= 0 then
          if o.spr == 17 then
            pal(5,color)
            spr(o.spr,o.x,o.y)
          elseif o.spr == 33 then
            if m == 2 and o.clr ~= p[2].clr then
              pal(5,o.clr)
      			  spr(o.spr,o.x,o.y)
            elseif m == 1 and o.clr ~= p[1].clr then
              pal(5,o.clr)
              spr(o.spr,o.x,o.y)
            end
            if btn(5,0) and m == 2 then
              print(o.worth, o.x+7,o.y+7,0)
              print(o.worth, o.x+9,o.y+9,0)
              print(o.worth, o.x+9,o.y+7,0)
              print(o.worth, o.x+9,o.y+7,0)
              print(o.worth, o.x+8,o.y+8,o.clr)
            end
          end
          pal(5,5)
        end
  		end

  		for m = 1,2 do --driller
  			pal(5,p[m].clr)

        --drill
        local drill = 6
        if every(2,4) then drill = 7 end
        local rot = p[m].rot+0.25
        if rot > 1 then rot -= 1 end
        local xflip = false
        local yflip = false
        local sprite = 2

        if rot <= 0.125 or rot > 0.875 then sprite = 2 xflip = false yflip = true
        elseif rot > 0.125 and rot <= 0.375 then sprite = 3 xflip = true yflip = false
        elseif rot > 0.375 and rot <= 0.625 then sprite = 2 xflip = false yflip = false
        elseif rot > 0.625 and rot <= 0.875 then sprite = 3 xflip = false yflip = true
        end

        spr(sprite,p[m].dx+drill*sin(rot),p[m].dy+drill*cos(rot),1,1,xflip,yflip)


  			spr(1,p[m].dx,p[m].dy) --body

  			for l = 0 , p[m].load do --action light
  				if l == 1 then pset(p[m].dx+3,p[m].dy+3,7) end
  				if l == 2 then pset(p[m].dx+4,p[m].dy+3,7) end
  				if l == 3 then pset(p[m].dx+3,p[m].dy+4,7) end
  				if l == 4 then pset(p[m].dx+4,p[m].dy+4,7) end
  			end
  			pal(5,5)

        foreach(particles, draw_spark)

  		end

  		camera(cam[m].x,cam[m].y)
  	end

  	clip()

    ui()
end

function logo(x,y)
  local d = 128
  local r = 129
  local i = 130
  local l = 131
  local e = 132
  local t = 133
  local h = 134
  rectfill(x+1,y-3,x+33,y+1,0)
  print3("codename",x+2,y-2,7)
  x = x + 11
  y = y + 11
  if every(10,30) == false then
    pal(7,p[1].clr)
    spr(t,x-8,y,1,2)
    spr(h,x,y,1,2)
    spr(r,x+8,y,1,2)
    spr(i,x+8*2,y,1,2)
    spr(l,x+8*3,y,1,2)
    spr(l,x+8*4,y,1,2)
    spr(e,x+8*5,y,1,2)
    spr(r,x+8*6,y,1,2)
  end
  if every(10,20) == true then
    y = y-8
    x = x-10
    pal(7,p[2].clr)
    spr(d,x,y,1,2)
    spr(r,x+8,y,1,2)
    spr(i,x+8*2,y,1,2)
    spr(l,x+8*3,y,1,2)
    spr(l,x+8*4,y,1,2)
    spr(e,x+8*5,y,1,2)
    spr(r,x+8*6,y,1,2)
  end
  pal(7,7)
end

function winner(x,y,clr)
  local w = 136
  local r = 129
  local i = 130
  local n = 135
  local e = 132
  x = x+8
  if every(10,20) == true then
    pal(7,clr)
    spr(w,x,y,1,2)
    spr(i,x+8,y,1,2)
    spr(n,x+8*2,y,1,2)
    spr(n,x+8*3,y,1,2)
    spr(e,x+8*4,y,1,2)
    spr(r,x+8*5,y,1,2)
    pal(7,7)
  end
end
function loser(x,y,clr)
  local l = 131
  local o = 137
  local s = 138
  local r = 129
  local e = 132
  x = x+16
  if every(10,30) == false then
    pal(7,clr)
    spr(l,x,y,1,2)
    spr(o,x+8,y,1,2)
    spr(s,x+8*2,y,1,2)
    spr(e,x+8*3,y,1,2)
    spr(r,x+8*4,y,1,2)
    pal(7,7)
  end
end

function spawn(type,sprite,rarity,x,y,c) --c has to be a nr between 1-100
	for a=0,x do
		for b=0,y do
			if flr(rnd(100))+1 > c and mget(a,b) == 9 then
        local isempty = true
        for o in all(objects) do
          if o.x == a*8 and o.y == b*8 then
             isempty = false
          end
        end
        if isempty then
          type = {}
          local z = gemtypes[flr(rnd(rarity)+1)]
  				type.x = a*8
  				type.y = b*8
  				type.spr = sprite
  				type.clr = z.clr
  				type.id = objid
          type.worth = z.nr
  				add(objects,type)
  				objid += 1
        end
			end
		end
	end
end

function generatemap()
  for x=1,mapx-1 do
    for y=1,mapy-1 do
      mset(x,y,flr(rnd(2)+8))
    end
	end

  for x=1,mapx-1 do
    for y=1,mapy-11 do
      if mget(x,y) ~= 9 then mset(x,y,flr(rnd(2)+8)) end
    end
  end

  for x=1,mapx-1 do
    for y=mapy-6,mapy-1 do
      if mget(x,y) ~= 9 then mset(x,y,flr(rnd(2)+8)) end
    end
  end

	for x = 0,mapx do
		for y = mapy, mapy+2 do
			mset(x,y,10)
		end
	end

  spawn(gem,33,2,mapx,mapy-2,90)
  spawn(gem,33,3,mapx,mapy-10,97)
  spawn(gem,33,3,mapx,5,90)
	spawn(crd,17,1,mapx,mapy-2,90)
end

function init_game()
  timeline = {}
  timeline_actor = {}
  timeline_counter = 1
  timeuntilturn = 0
  objects = {}
  objid = 1
  cardshuffle = false
  shuffletime = 0
  cardrow = 0
  timelinerow = 0
  turn = 1
  activate = false
  wait = 0
  particles = {}
  debris = {}

  generatemap()

	p[1] = {}
  p[1].win = false
	p[1].x = 8*6
	p[1].y = 8*(mapy+1)
  p[1].dx = p[1].x
  p[1].dy = p[1].y
	p[1].dir = 0
  p[1].rot = 0
	p[1].load = 0
	p[1].inv = {}
	p[1].past = {}
	p[1].clr = 14
  p[1].score = 0
  p[1].oldscore = 0
  p[1].invworth = 0
  p[1].cardinv = {}
  p[1].shuffle = false
  p[1].loadspin = 0

	p[2] = {}
  p[2].win = false
	p[2].x = 8*10
	p[2].y = 8*(mapy+1)
  p[2].dx = p[2].x
  p[2].dy = p[2].y
	p[2].dir = 0
  p[2].rot = 0
	p[2].load = 0
	p[2].inv = {}
	p[2].past = {}
	p[2].clr = 12
  p[2].score = 0
  p[2].oldscore = 0
  p[2].invworth = 0
  p[2].cardinv = {}
  p[2].shuffle = false
  p[2].loadspin = 0

	cam[1] = {}
	cam[1].x = p[1].x-28
	cam[1].y = p[1].y-64
	cam[2] = {}
	cam[2].x = p[2].x-92
	cam[2].y = p[2].y-64

	palt(12,true)
	palt(0,false)

	initiatedeck()

  card = {}
  local a = 0
  local cardid = 1
  for a = 0,3 do
    local x = flr(rnd(#deck))+1
    card[a] = {}
		card[a].action = deck[x].action
		card[a].rot = -0.3
		card[a].dir = 0
		card[a].x = 0
		card[a].y = 0
		card[a].txt = {deck[x].txt[1],deck[x].txt[2]}
		card[a].clr = deck[x].clr
		card[a].spr = deck[x].spr
    card[a].id = cardid
    cardid += 1
    a += 1
  end

  dynamic_rock()
end

function _init()
  lid = {}
  lid.spr = 228
  lid.x = 48
  lid.y = 48
	initfont()
  init_actions()
  init_game()
end

function splash()
  -- if frames > 45 then lid.y = lerp(lid.y,46,0.08) end
  -- if flr(lid.y) == 46 then lid.spr = 196 end
  -- if frames < 200 then
  --   rectfill(0,0,128,128,10)
  --   spr(192,48,46,4,4)
  --   spr(lid.spr,lid.x,lid.y,4,2)
  -- end
  -- if frames > 75 and frames < 220 then
  --   line(lid.x+13,lid.y+8,lid.x+13,lid.y+9,10)
  --   line(lid.x+11+7,lid.y+8,lid.x+11+7,lid.y+9,10)
  --
  --   local c = 200
  --   local a = 201
  --   local t = 202
  --   local n = 203
  --   local i = 216
  --   local p = 217
  --   local d = 218
  --   local e = 219
  --   local x = 33
  --   local y = 78
  --   spr(c,x,y)
  --   spr(a,x+7,y)
  --   spr(t,x+14,y)
  --   spr(n,x+21,y)
  --   spr(i,x+27,y)
  --   spr(p,x+33,y)
  --   spr(p,x+40,y)
  --   spr(e,x+47,y)
  --   spr(d,x+54,y)
  -- end
  -- if frames > 260 then game_screen = "menu" end
  if frames > 0 then game_screen = "menu" end
end

function update_game()
  foreach(particles, move_spark)
  for m = 1,2 do

    p[m].oldscore = lerp(p[m].oldscore,p[m].score,0.1)

		if btn(5,m-1) then
			if btn(0,m-1) then cam[m].x -= 5 end
			if btn(1,m-1) then cam[m].x += 5 end
			if btn(2,m-1) then cam[m].y -= 5 end
			if btn(3,m-1) then cam[m].y += 5 end
		else
			for c = 0,3 do
				if btnp(c,m-1) and p[m].shuffle == false and p[m].load <= 3 and tablecontains(p[m].cardinv, card[c].id) == false then
					add(timeline,card[c].action)
					add(timeline_actor,m)
          add(p[m].cardinv,card[c].id)
					p[m].load += 1
				end
			end

			if btnp(4,m-1) and #p[m].cardinv >= 1 then
				p[m].shuffle = true
			end

			if #p[m].inv > 0 then
				for z = 1,count(p[m].inv) do
					local id = p[m].inv[z]
					local a = #p[m].past - z +1
          if p[m].y > mapy*8 then
            if abs(objects[id].x - p[m].x) < 1 and abs(objects[id].y - cam[m].y) < 1 then
              objects[id].spr = 0
              del(p[m].inv,id)
            else
              objects[id].clr = p[m].clr
              objects[id].x = lerp(objects[id].x, p[m].x, 0.1*z)
              objects[id].y = lerp(objects[id].y, cam[m].y, 0.1*z)
            end
					elseif a > 0 then
            if objects[id].x - p[m].past[a].x > 1 then
			        objects[id].x = lerp(objects[id].x, p[m].past[a].x, 0.1)
            else objects[id].x = p[m].past[a].x end
            if objects[id].y - p[m].past[a].y > 1 then
			        objects[id].y = lerp(objects[id].y, p[m].past[a].y, 0.1)
            else objects[id].y = p[m].past[a].y end
					end
				end
			end

			if activate == true then
				cardshuffle = true
				activator()
			end
			if p[1].load > 3 and p[2].load > 3 then
				activate = true
			end
      if p[m].load > 3 then p[m].shuffle = true end
		end
    score(m)
    p[m].loadspin = lerp(p[m].loadspin,p[m].load,0.4)
    p[m].dx = lerp(p[m].dx,p[m].x,0.5)
    p[m].dy = lerp(p[m].dy,p[m].y,0.5)
    p[m].rot = rotlerp(p[m].rot,(p[m].dir+1)*0.25,0.4)
    if abs(p[m].dx - p[m].x) < 1 then p[m].dx = p[m].x end
    if abs(p[m].dy - p[m].y) < 1 then p[m].dy = p[m].y end
	end

  if p[1].shuffle and p[2].shuffle then
    if cardshuffle == false then
      cardshuffle = true
    elseif cardshuffle == true and wait == 30 then
      cardshuffle = false
      for a = 0,3 do card[a].rot = -0.3 end
      resetcards()
      p[1].cardinv = {}
      p[2].cardinv = {}
      p[1].shuffle = false
      p[2].shuffle = false
      wait = 0
    elseif cardshuffle == true and wait < 60 then wait += 1 end
  end

	for a = 0,3 do --cards
    if card[a].dir - card[a].rot < 0.003 then card[a].rot = card[a].dir end
		card[a].rot = lerp(card[a].rot,card[a].dir,0.1)

		if cardshuffle == false then
			card[a].dir = (a+1)*-0.05
		elseif cardshuffle == true then
			card[a].dir = 0.1
		end
	end

	if btn(5,0) ~= true then
		cam[1].x = lerp(cam[1].x, p[1].x-28, camspeed)
		cam[1].y = lerp(cam[1].y, p[1].y-64, camspeed)
	end
	if btn(5,1) ~= true then
		cam[2].x = lerp(cam[2].x, p[2].x-92, camspeed)
		cam[2].y = lerp(cam[2].y, p[2].y-64, camspeed)
	end


end

function _update()
	frames += 1
  if frames == 31999 then frames = 0 end

  if game_screen == "game" then
	   update_game()
  end

  if game_screen == "menu" then
    if btnp(4) or btnp(5) then
      init_game()
      game_screen = "game"
    end
  end

  if game_screen == "win" then
    if btnp(4) or btnp(5) then
      game_screen = "menu"
    end
  end

end

function _draw()
	cls()
  if game_screen == "splash" then splash() end
  if game_screen == "menu" then draw_menu() end
  if game_screen == "game" then draw_game() end
  if game_screen == "win" then
    draw_game()
    if p[1].win then
      winner(cam[2].x,cam[2].y+56,p[1].clr)
      loser(cam[2].x+64,cam[2].y+56,p[2].clr)
    elseif p[2].win then
      winner(cam[2].x+64,cam[2].y+56,p[2].clr)
      loser(cam[2].x,cam[2].y+56,p[1].clr)
    end
  end
	-- rectfill(cam[2].x+18,cam[2].y+18,cam[2].x+42,cam[2].y+24,5)
	-- print(stat(1),cam[2].x+19,cam[2].y+19,7)
end


__gfx__
00000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000707007ccc7ccccccccccccccccc7ccccccccccccccccc00000000
00000000c000000ccccccccc0000ccccccc55cccccc55cccccc00cccccc55ccccccccccc00770000ccccc7c7ccccccccc7ccccccccccc7cccc7ccccc00000000
00700700c055550ccc0000cc757000ccccc55cccccc55cccccc00cccccc55ccccccccccc00000077cc7ccc7cccccccccccccccccc7cccccccccccccc00000000
00077000c050050ccc0750cc757570ccc005555cc555500cc555555cc555555ccccccccc70070700c7c7ccccccc55ccc7ccccccccccccccccccc7ccc00000000
00077000c050050cc005000c505050ccc005555cc555500cc555555cc555555ccccccccc700000007ccc7cccccc55ccccccc7c7ccccccccccccccccc00000000
00700700c055550cc077550c505000ccccc55cccccc55cccccc55cccccc00ccccccccccc00770000ccccc7c7ccccccccccccccccccccccc7cccccccc00000000
00000000c000000cc055000c0000ccccccc55cccccc55cccccc55cccccc00ccccccccccc07007077cc7ccc7ccccccccccc7cccccccccccccccc7cccc00000000
00000000ccccccccc077550ccccccccccccccccccccccccccccccccccccccccccccccccc00000070c7c7ccccccccccccccccccc7cc7ccccccccccccc00000000
cccccccccccccccc000000000000000000cc000c00000000000000000000000000000000777c77c77cccccccccccccccccccccc7000000000000000000000000
c000000ccc0000cc000000000000000ccc0c00cc00000000000000000000000000000000ccccccccccccccccccccccccccccccc7000000000000000000000000
c077770cc075550c0000000000ccc000000ccccc00000000000000000000000000000000cccccccc7cccccccccccccccccccccc7000000000000000000000000
c077770cc075550c0000000c000000ccccccc0c000000000000000000000000000000000cccccccc7ccccccccccccccccccccccc000000000000000000000000
c007770ccc05550c0000000000ccccc00ccccccc00000000000000000000000000000000ccccccccccccccccccccccccccccccc7000000000000000000000000
cc07770ccc05550c000c00c0ccc0000ccccccccc00000000000000000000000000000000cccccccc7cccccccccccccccccccccc7000000000000000000000000
cc00000cccc000cc00cccc0c000c0cccc0cccccc00000000000000000000000000000000cccccccc7ccccccccccccccccccccccc000000000000000000000000
cccccccccccccccc0c0c0cccccccc000cccccccc00000000000000000000000000000000cccccccc7ccccccc7c77c777ccccccc7000000000000000000000000
cccccccccccccccc0c0ccccccccccccccccccccc00000000000000000000000000000000c77c7cccccc777c77ccccccccccccccc777c77c77cccccc700000000
ccccccccccc00ccccccc000cccc0ccccccc00ccc00000000000000000000000000000000ccccc7cccc7cccccccccccccccccccc7ccccccccccccccc700000000
ccc75ccccc0750cccc00cc0ccccccccc0c0ccccc00000000000000000000000000000000cccccc7cc7cccccc7cccccccccccccc7cccccccc7cccccc700000000
cc7755ccc077550cccccc0cccccc00ccccc0cccc00000000000000000000000000000000ccccccc77ccccccc7ccccccccccccccccccccccc7cccccc700000000
cc5500ccc055550ccccccccc0ccccccccccccccc00000000000000000000000000000000ccccccc7cccccccc7cccccccccccccc7cccccccccccccccc00000000
ccc50ccccc0550cccc0ccccccccccccccccccccc00000000000000000000000000000000ccccccc77cccccccc7cccccccccccc7ccccccccc7cccccc700000000
ccccccccccc00ccccccccccc0ccccccc0ccccccc00000000000000000000000000000000cccccccc7ccccccccc7cccccccccc7cccccccccc7cccccc700000000
ccccccccccccccccccccccc0cccccccccccccccc00000000000000000000000000000000ccccccc7ccccccccccc7c77c7c777ccc777c77777cccccc700000000
0000000000000000ccc0cccccccccccccccccccc00000000000000000000000000000000ccccccc77c77cc777cccccc77c777c7cc77c77cc0000000000000000
0000000000000000ccccccccc0cccccccccccccc000000000000000000000000000000007c7c77cccccccccc7cccccccccccc7ccc7cccc7c0000000000000000
0000000000000000cccccccccccccccccccccccc00000000000000000000000000000000c7ccccc7c7ccccccccccccc7cccccc7c7ccccccc0000000000000000
0000000000000000cccccccccccccccccccccccc000000000000000000000000000000007cccccc7c7ccccccccccccc7cccccccc7cccccc70000000000000000
0000000000000000cccccccccccccc0ccccccccc000000000000000000000000000000007ccccccccccccccc7cccccc7cccccc7c7cccccc70000000000000000
0000000000000000cc0ccccccccccccccccccccc000000000000000000000000000000007cccccccc7cccccc7ccccc7ccccccc7cccccccc70000000000000000
0000000000000000cccccccccccccccccccccccc00000000000000000000000000000000ccccccc7cc7ccccccc77c7c7cccccccc77cccc7c0000000000000000
0000000000000000cccccccccccccccccccccccc000000000000000000000000000000007cccccc7c7c777c77ccccccc77cc77c7c77777cc0000000000000000
c7c77c77777c77777777c7c7777cc77c77cc777777777777777777c777777c77c77c77c77c777ccc000000000000000000000000000000000000000000000000
7777777cc7c777c77c7c7777c7c7c777c7cc7777c77c77777777ccc7cc7c7c77c7777c7c777c7ccc000000000000000000000000000000000000000000000000
7c777777777c7777cc7777c77777777c77777c77c77777cccc77cc77cc7c777c7c7777c7c7cc77cc000000000000000000000000000000000000000000000000
77777c77c7777c7c777cc777c77777ccccccc7c777c7cc7c77cc77c7ccc77cc7777c7c7cc7cccccc000000000000000000000000000000000000000000000000
7c7c7cc7cc77777c7c777cc7777777cccc7c7c7c777cccc77cccc7cccc7cc7cccc7c7c7c777777cc000000000000000000000000000000000000000000000000
777777c77777cc777c777cc7777cc7c7c7cccccc7cc7cc7c77cc77c7c7cccc7777ccccccc7cccccc000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000000000000000000000000000
cc0cccccc000cccccccc0ccccc0cccccc0000ccccc0ccccccccccccccc0ccccc0000000000000000000000000000000000000000000000000000000000000000
c000ccccc000cccccc0000ccc0000ccc000000ccc000cccccccccc0cc000cccc0000000000000000000000000000000000000000000000000000000000000000
00000cccc000ccccc000000c000000cc00cc00cc00000ccc00cc000000000ccc0000000000000000000000000000000000000000000000000000000000000000
c000ccccc000cccc000000ccc000000c00cc00cccccccccc00cc0000cc0ccccc0000000000000000000000000000000000000000000000000000000000000000
c000cccc00000ccc000c0ccccc0c000c00cc00ccc000ccccc0cc0c0cc0c0cccc0000000000000000000000000000000000000000000000000000000000000000
c000ccccc000cccc000ccccccccc000c00c0000cccccccccc0000ccccc0ccccc0000000000000000000000000000000000000000000000000000000000000000
c000cccccc0ccccc000ccccccccc000c00cc00ccc000ccccc0000cccc0c0cccc0000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000ccc000000cc0000000c000ccccc0000000c0000000c000c000c000c000c000c000cc00000ccc00000cc0000000000000000000000000000000000000000
077700cc0777700c0777770c070ccccc0777770c0777770c070c070c070c070c070c070c0077700c0077700c0000000000000000000000000000000000000000
0700700c0700070c0007000c070ccccc0700000c0007000c070c070c0700070c070c070c0700070c0700070c0000000000000000000000000000000000000000
070c070c070c070ccc070ccc070ccccc070ccccccc070ccc070c070c0770070c070c070c070c070c070c070c0000000000000000000000000000000000000000
070c070c070c070ccc070ccc070ccccc070ccccccc070ccc070c070c0770070c070c070c070c070c070c000c0000000000000000000000000000000000000000
070c070c070c070ccc070ccc070ccccc070ccccccc070ccc070c070c0770070c070c070c070c070c0070cccc0000000000000000000000000000000000000000
070c070c070c070ccc070ccc070ccccc070ccccccc070ccc070c070c0707070c0700070c070c070cc070cccc0000000000000000000000000000000000000000
070c070c0700070ccc070ccc070ccccc070000cccc070ccc0700070c0707070c0707070c070c070ccc070ccc0000000000000000000000000000000000000000
070c070c0777700ccc070ccc070ccccc077770cccc070ccc0777770c0707070c0707070c070c070ccc070ccc0000000000000000000000000000000000000000
070c070c0700070ccc070ccc070ccccc070000cccc070ccc0700070c0707070c0707070c070c070cccc070cc0000000000000000000000000000000000000000
070c070c070c070ccc070ccc070ccccc070ccccccc070ccc070c070c0700770c0777770c070c070cccc0700c0000000000000000000000000000000000000000
070c070c070c070ccc070ccc070ccccc070ccccccc070ccc070c070c0700770c0770770c070c070c000c070c0000000000000000000000000000000000000000
070c070c070c070ccc070ccc070ccccc070ccccccc070ccc070c070c0700770c0770770c070c070c070c070c0000000000000000000000000000000000000000
0700700c070c070c0007000c0700000c0700000ccc070ccc070c070c0700070c0700070c0700070c0700070c0000000000000000000000000000000000000000
077700cc070c070c0777770c0077770c0077770ccc070ccc070c070c070c070c070c070c0077700c0077700c0000000000000000000000000000000000000000
00000ccc000c000c0000000cc000000cc000000ccc000ccc000c000c000c000c000c000cc00000ccc00000cc0000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000ccccc000ccccc0ccccc0c000cccaaaaa000000aaaaa0000000000000000
ccccccccccccccccccccccccccccccccccccccccccccc000000ccccccccccccc0cccc0ccc0ccc0cc000000cc00ccc0ccaa000000000000aa0000000000000000
ccccccccccccccccccccccccccccccccccccccccccccc0cccc0ccccccccccccc0cccccccccccc0cccc0ccccc0cccc0cca07777777777770a0000000000000000
ccccccccccccccccccccccccccccccccccccccc000000000000000000ccccccc0ccccccccc0000cccc0ccccc0cccc0cca00000000000000a0000000000000000
cccccccccccccccccccccccccccccccccccccc07777777777777777770cccccc0cccccccc0ccc0cccc0ccccc0cccc0ccaaa000a00a000aaa0000000000000000
cccccccccccc00000000cccccccccccccccccc07777777777777777770cccccc0cccc0cc0ccc00cccc0ccccc0cccc0ccaa077000000770aa0000000000000000
cccccccccc000000000000cccccccccccccccc00000000000000000000ccccccc0000cccc000c0ccccc000cc0cccc0ccaa077777777770aa0000000000000000
cccccccc0000000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccaa070707707070aa0000000000000000
ccccccc000000000000000000ccccccccccccccccccccccccccccccccccccccccc0ccccc0c000cccccccc0ccc0000cccaa070707707070aa0000000000000000
ccccccc000000000000000000ccccccccccccccccccccccccccccccccccccccccc0ccccc00ccc0ccc000c0cc0cccc0ccaa070707707070aa0000000000000000
ccccccc077000000000000770ccccccccccccccccccccccccccccccccccccccccc0ccccc0cccc0cc0ccc00cc0cccc0ccaa070707707070aa0000000000000000
ccccccc077770000000077770ccccccccccccccccccccccccccccccccccccccccc0ccccc0cccc0cc0cccc0cc000000ccaa070707707070aa0000000000000000
ccccccc070777777777777070ccccccccccccccccccccccccccccccccccccccccc0ccccc00ccc0cc0cccc0cc0cccccccaa070707707070aa0000000000000000
ccccccc070777777777777070ccccccccccccccccccccccccccccccccccccccccc0ccccc0c000ccc0ccc00cc0cccc0ccaa077707707770aa0000000000000000
ccccccc070777077770777070ccccccccccccccccccccccccccccccccccccccccc0ccccc0cccccccc000c0ccc0000cccaaa0077777700aaa0000000000000000
ccccccc070777077770777070cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccaaaaa000000aaaaa0000000000000000
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
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0101010101010101010101010c0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c01080a0a0a0a0a0a0a0a0b010c0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0108080808080808080808010c0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c010e08080808080808080808010c0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c010108080808080808090909010c0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c010101010101010101012101010c0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0c0a0a0a0a0a0a0a0a0e0a0a0c0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00 41424344
