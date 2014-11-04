local floor,ceil,min,max = math.floor, math.ceil, math.min, math.max
local abs = math.abs
local random = math.random

local recycle_one = function(player)
  if #player.grave > 0 then
    player:grave_to_bottom_deck(#player.grave)
  end
end

local ex2_recycle = function(player, char)
  if #player.grave >= 5 and
      #player:hand_idxs_with_preds(pred.neg(pred[char.faction])) == 0 and
      #player:field_idxs_with_preds(pred.neg(pred[char.faction])) == 0 then
    local target = uniformly(player:grave_idxs_with_preds(pred.follower))
    if target then
      player:grave_to_bottom_deck(target)
    end
  end
end

local ep7_recycle = function(player)
  if player.game.turn % 2 == 0 then
    local target = uniformly(player:grave_idxs_with_preds())
    if target then
      player:grave_to_exile(target)
    end
    target = uniformly(player:grave_idxs_with_preds(pred.follower))
    if target then
      player:grave_to_bottom_deck(target)
    end
  end
end

local wedding_shuffles = function(player)
  if (not player.opponent:is_npc()) and player.shuffles == 0 then
    player.shuffles = 1
  end
end

local sita_vilosa = function(player)
  local target_idxs = player.opponent:get_follower_idxs()
  local buff = OnePlayerBuff(player.opponent)
  for _,idx in ipairs(target_idxs) do
    if idx < 4 and player.opponent.field[idx] then
      buff[idx] = {sta={"-",1}}
    end
  end
  buff:apply()
  if player.opponent:is_npc() then
    OneBuff(player.opponent,0,{life={"-",1}}):apply()
  end
end

local cinia_pacifica = function(player)
  local target_idxs = player.opponent:get_follower_idxs()
  if #target_idxs > 0 then
    local target_idx = uniformly(target_idxs)
    OneBuff(player.opponent,target_idx,{atk={"-",1},sta={"-",1}}):apply()
  end
  if player.opponent:is_npc() then
    OneBuff(player.opponent,0,{life={"-",1}}):apply()
  end
end

local luthica_preventer = function(player)
  local target_idxs = player:field_idxs_with_preds(pred[player.character.faction], pred.follower)
  if #target_idxs > 0 then
    local target_idx = uniformly(target_idxs)
    OneBuff(player,target_idx,{atk={"+",1},sta={"+",1}}):apply()
  end
  if player.opponent:is_npc() then
    OneBuff(player.opponent,0,{life={"-",1}}):apply()
  end
end

local iri_flina = function(player)
  if player:field_size() > player.opponent:field_size() then
    OneBuff(player.opponent,0,{life={"-",1}}):apply()
  end
  if player.opponent:is_npc() then
    OneBuff(player.opponent,0,{life={"-",1}}):apply()
  end
end

local curious_vernika = function(player)
  local idx = player.opponent:field_idxs_with_most_and_preds(pred.def, pred.follower)[1]
  if idx then
    OneBuff(player.opponent,idx,{def={"=",0}}):apply()
  end
end

local thorn_witch_rose = function(player)
  local nme_followers = player.opponent:get_follower_idxs()
  if #nme_followers == 0 then
    return
  end
  local target_idx = uniformly(nme_followers)
  local buff_size = ceil(math.abs(player.opponent.field[target_idx].size - player.opponent.field[target_idx].def)/2)
  OneBuff(player.opponent,target_idx,{atk={"-",buff_size},def={"-",1},sta={"-",buff_size}}):apply()
end

local head_knight_jaina = function(player)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    if player.game.turn % 2 == 0 then
      OneBuff(player, target, {atk={"+",2},sta={"+",1}}):apply()
    else
      OneBuff(player, target, {atk={"+",2}}):apply()
    end
  end
end

local clarice = function(stats, skill)
  return function(player)
    local to_kill = player:field_idxs_with_preds(function(card) return card.id == 300201 end)
    for _,idx in ipairs(to_kill) do
      player:field_to_grave(idx)
    end
    local slot = player:last_empty_field_slot()
    if slot then
      if stats == "turn" then
        local amt = 10 - (player.game.turn % 10)
        if amt ~= 10 then
          player.field[slot] = Card(300201)
          OneBuff(player, slot, {atk={"=",amt},def={"=",1},sta={"=",amt}}):apply()
        end
      else
        player.field[slot] = Card(300201)
        OneBuff(player, slot, {atk={"=",stats[1]},def={"=",stats[2]},sta={"=",stats[3]}}):apply()
        if skill then
          player.field[slot].skills[1] = 1075
        end
      end
    end
  end
end

local rihanna = function(top, bottom)
  return function(player)
    local target = uniformly(player:field_idxs_with_preds(pred.follower))
    local slot = uniformly(player:empty_field_slots())
    if target and slot then
      local card = player.field[target]
      player.field[target] = nil
      player.field[slot] = card
      if slot <= 3 then
        OneBuff(player, slot, top):apply()
      end
      if slot >= 3 then
        OneBuff(player, slot, bottom):apply()
      end
    end
  end
end

local council_vp_tieria = function(group_pred, faction_pred)
  return function(player)
    local target = uniformly(player:field_idxs_with_preds(group_pred, pred.follower))
    local faction_count = #player:field_idxs_with_preds(faction_pred, pred.follower)
    if target then
      if faction_count == 1 then
        OneBuff(player, target, {atk={"+",1},sta={"+",2}}):apply()
      elseif faction_count >= 2 then
        OneBuff(player, target, {size={"-",1},atk={"+",1},sta={"+",2}}):apply()
      end
    end
  end
end

local hanbok_sita = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  local the_buff = {atk={"+",1},sta={"+",2}}
  if target then
    if #opponent:field_idxs_with_preds() > #player:field_idxs_with_preds() then
      the_buff.atk[2] = the_buff.atk[2] + 1
    end
    if #player.hand >= #opponent.hand then
      the_buff.sta[2] = the_buff.sta[2] + 1
    end
    OneBuff(player, target, the_buff):apply()
  end
end

local hanbok_cinia = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  local buff = GlobalBuff(player)
  if target then
    buff.field[opponent][target] = {def={"-",1},sta={"-",2}}
  end
  target = opponent:hand_idxs_with_preds(pred.follower)[1]
  if target then
    buff.hand[opponent][target] = {}
    if #opponent:field_idxs_with_preds() > #player:field_idxs_with_preds() then
      buff.hand[opponent][target].def = {"-",1}
    end
    if #player.hand >= #opponent.hand then
      local amt = min(2,opponent.hand[target].sta-1)
      buff.hand[opponent][target].sta={"-",amt}
    end
  end
  buff:apply()
end

local hanbok_luthica = function(player, opponent, my_card)
  local n = 1
  if #opponent:field_idxs_with_preds() > #player:field_idxs_with_preds() then
    n = n + 1
  end
  if #player.hand >= #opponent.hand then
    n = n + 1
  end
  for i=1,n do
    local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(opponent, target, {sta={"-",2}}):apply()
    end
  end
end

local hanbok_iri = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  local the_buff = {atk={"-",1},sta={"-",2}}
  if target then
    if #opponent:field_idxs_with_preds() > #player:field_idxs_with_preds() then
      the_buff.atk[2] = the_buff.atk[2] + 1
    end
    if #player.hand >= #opponent.hand then
      the_buff.sta[2] = the_buff.sta[2] + 1
    end
    OneBuff(opponent, target, the_buff):apply()
  end
end

local buff_random = function(player, opponent, my_card, my_buff)
  local target_idxs = player:field_idxs_with_preds(pred.follower)
  if #target_idxs == 0 then
    return
  end
  local target_idx = uniformly(target_idxs)
  OneBuff(player,target_idx,my_buff):apply()
end

local buff_all = function(player, opponent, my_card, my_buff)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
    buff[idx] = my_buff
  end
  buff:apply()
end

local wind_forestier = function(stats)
  return function(player)
    local target_idxs = player.opponent:field_idxs_with_preds(pred.follower)
    if #target_idxs == 0 then
      return
    end
    local buff = {}
    for _,stat in ipairs(stats) do
      buff[stat] = {"-",floor(player.game.turn/2)}
    end
    OneBuff(player.opponent, uniformly(target_idxs), buff):apply()
  end
end

characters_func = {

--Mysterious Girl Sita Vilosa
[100001] = sita_vilosa,

--Beautiful and Smart Cinia Pacifica
[100002] = cinia_pacifica,

--Crux Knight Luthica
[100003] = luthica_preventer,

--Runaway Iri Flina
[100004] = iri_flina,

--Nold
[100005] = function(player)
  if #player.hand == 0 then
    return
  end
  local hand_idx = math.random(#player.hand)
  local buff = GlobalBuff(player) --stolen from Tower of Books
  buff.hand[player][hand_idx] = {size={"+",1}}
  buff:apply()
  local my_cards = player:field_idxs_with_preds(function(card) return card.size >= 2 end)
  if #my_cards == 0 then
    return
  end
  local target_idx = uniformly(my_cards)
  OneBuff(player,target_idx,{size={"-",1}}):apply()
end,

--Ginger
[100006] = function(player)
  local ncards = #player:field_idxs_with_preds()
  local target_idxs = player:field_idxs_with_preds(pred.follower, function(card) return card.size >= ncards end)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {atk={"+",1}, sta={"+",2}}
  end
  buff:apply()
end,

--Curious Girl Vernika
[100007] = curious_vernika,

--Cannelle
[100008] = function(player)
  if player.opponent:field_size() == 0 or #player:get_follower_idxs() == 0 then
    return
  end
  local max_size = player.opponent.field[player.opponent:field_idxs_with_most_and_preds(pred.size)[1]].size
  local min_size = player.field[player:field_idxs_with_least_and_preds(pred.size)[1]].size
  local buff_size = abs(max_size - min_size)
  local target_idxs = player:field_idxs_with_least_and_preds(pred.size, pred.follower)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {atk={"+",buff_size}, sta={"+",buff_size}}
  end
  buff:apply()
end,

--Gart
[100009] = function(player)
  local num_follower = #player.opponent:get_follower_idxs()
  if num_follower == 0 then
    return
  end
  local num_vita = #player.opponent:field_idxs_with_preds({pred.follower, pred.V})
  local buff = OnePlayerBuff(player.opponent)
  if num_follower==num_vita then
    local target_idxs = shuffle(player.opponent:get_follower_idxs())
    for i=1,2 do
      if target_idxs[i] then
        buff[target_idxs[i]] = {sta={"-",1}}
      end
    end
  else
    local target_idx = uniformly(player.opponent:field_idxs_with_preds(pred.follower, pred.neg(pred.faction.V)))
    if target_idx then
      buff[target_idx] = {atk={"-",2},sta={"-",2}}
    end
  end
  buff:apply()
end,

-- Dress Sita
[100010] = function(player)
  local nme_cards = player.opponent:ncards_in_field()
  if nme_cards == 0 then
    return
  end
  if nme_cards > 1 then
    local nme_followers = player.opponent:get_follower_idxs()
    if #nme_followers == 0 then
      return
    end
    local buff = OnePlayerBuff(player.opponent)
    local target_idx = player.opponent:field_idxs_with_most_and_preds(pred.size, pred.follower)[1]
    buff[target_idx] = {atk={"-",2},def={"-",1},sta={"-",2}}
    buff:apply()
  elseif nme_cards == 1 then
    local target = player:deck_idxs_with_preds(pred.follower)[1]
    if target then
      local buff = GlobalBuff(player)
      buff.deck[player][target] = {atk={"+",1},sta={"+",2}}
      buff:apply()
    end
  end
end,

--Dress Cinia
[100011] = function(player)
  local target_idxs = player.opponent:get_follower_idxs()
  if #target_idxs == 0 then
    return
  end
  local max_size
  if #player.hand == 0 then
    max_size = 0
  elseif #player.hand == 1 then
    max_size = math.ceil(player.hand[1].size/2)
  else
    max_size = math.ceil((player.hand[1].size + player.hand[2].size)/2)
  end
  local target_idx = player.opponent:field_idxs_with_preds(pred.follower, function(card) return card.size <= max_size end)[1]
  if target_idx then
    OneBuff(player.opponent,target_idx,{atk={"-",2},def={"-",2},sta={"-",2}}):apply()
  end
end,

--Dress Luthica
[100012] = function(player)
  local buff = OnePlayerBuff(player)
  local size1 = 0
  local size2 = 0
  if player.hand[1] then
    size1 = player.hand[1].size
  end
  if player.hand[2] then
    size2 = player.hand[2].size
  end
  local target_idxs = player:get_follower_idxs()
  if math.abs(size1 - size2)%2 == 1 then
    for _,idx in ipairs(target_idxs) do
      buff[idx] = {sta={"+",2}}
    end
  else
    for _,idx in ipairs(target_idxs) do
      buff[idx] = {atk={"+",2}}
    end
  end
  buff:apply()
end,

--Dress Iri
[100013] = function(player)
  if #player.hand == 0 then
    return
  end
  if (player.character.life + player.hand[1].size)%2 == 0 then
    OneBuff(player,0,{life={"+",3}}):apply()
  else
    local buff = GlobalBuff(player)
    buff.hand[player][1] = {size={"-",1}}
    buff:apply()
  end
end,

--Dress Vernika
[100014] = function(player)
  local target_idxs = player:field_idxs_with_preds(pred.follower, function(card) return card.size > 1 end)
  if #target_idxs == 0 then
    return
  end
  local size1 = 0
  local size2 = 0
  if player.hand[1] then
    size1 = player.hand[1].size
  end
  if player.hand[2] then
    size2 = player.hand[2].size
  end
  local size_diff = math.abs(size1 - size2)
  OneBuff(player,uniformly(target_idxs),{size={"-",min(size_diff,3)}}):apply()
end,

--Kendo Sita
[100015] = function(player)
  if #player.opponent:get_follower_idxs() == 0 then
    return
  end
  if not player.opponent.field[3] then
    local old_card_idx = uniformly(player.opponent:get_follower_idxs())
    local card = player.opponent.field[old_card_idx]
    player.opponent.field[3] = card
    player.opponent.field[old_card_idx] = nil
  end
  if pred.follower(player.opponent.field[3]) then
    OneBuff(player.opponent,3,{sta={"-",3}}):apply()
  end
end,

--Chess Cinia
[100016] = function(player)
  local target_idx = player.opponent:field_idxs_with_most_and_preds(pred.size, pred.follower)[1]
  local followers = player:get_follower_idxs()
  if not target_idx or #followers == 0 then
    return
  end
  local buff_size = 0
  if player.field[4] then
    buff_size = math.ceil((player.field[followers[1]].size + player.field[4].size)/2)
  else
    buff_size = math.ceil(player.field[followers[1]].size/2)
  end
  OneBuff(player.opponent,target_idx,{atk={"-",buff_size},sta={"-",buff_size}}):apply()
end,

--Sports Luthica
[100017] = function(player)
  if #player:get_follower_idxs() == 0 then
    return
  end
  if player.field[1] and pred.follower(player.field[1]) and not player.field[5] then
    local card = player.field[1]
    player.field[5] = card
    player.field[1] = nil
  end
  if player.field[5] and pred.follower(player.field[5]) then
    OneBuff(player,5,{sta={"+",5}}):apply()
  end
end,

--Cheerleader Iri
[100018] = function(player, opponent, my_card)
  local hand_idx = uniformly(player:hand_idxs_with_preds(function(card) return card.size >= 2 end))
  if hand_idx then
    local buff = GlobalBuff(player) --stolen from Tower of Books
    buff.hand[player][hand_idx] = {size={"-",1}}
    buff:apply()
    if pred.D(player.hand[hand_idx]) then
      buff_random(player, opponent, my_card, {atk={"+",1},sta={"+",1}})
    end
  end
end,

--Team Manager Vernika
[100019] = function(player)
  local hand_size = #player.hand
  local buff_size = math.ceil(hand_size/2)
  if hand_size < 4 then
    local buff = GlobalBuff(player)
    for i=1,hand_size do
      if pred.follower(player.hand[i]) then
        buff.hand[player][i] = {atk={"+",buff_size},sta={"+",buff_size}}
      end
    end
    buff:apply()
    for i=1,hand_size do
      player:hand_to_bottom_deck(1)
    end
  else
    return
  end
  local targets = player:field_idxs_with_preds(pred.follower, pred.V)
  if #targets > 0 then
    OneBuff(player,uniformly(targets),{atk={"+",buff_size},sta={"+",buff_size}}):apply()
  end
end,

--Swimwear Sita
[100020] = function(player)
  local hand_idx = player:hand_idxs_with_least_and_preds(pred.size, pred.follower)[1]
  local nme_followers = player.opponent:get_follower_idxs()
  if (not hand_idx) or #nme_followers == 0 then
    return
  end
  local def_lose = math.floor(player.hand[hand_idx].atk/2)
  OneBuff(player.opponent,uniformly(nme_followers),{def={"-",def_lose}}):apply()
end,

--Swimwear Cinia
[100021] = function(player)
  local my_followers = player:get_follower_idxs()
  local nme_followers = player.opponent:get_follower_idxs()
  if #my_followers == 0 or #nme_followers == 0 then
    return
  end
  local my_size = player.field[my_followers[1]].size
  local target_idxs = player.opponent:field_idxs_with_preds(pred.follower, function(card) return card.size < my_size end)
  local buff = OnePlayerBuff(player.opponent)
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {atk={"-",1},sta={"-",2}}
  end
  buff:apply()
end,

--Swimwear Luthica
[100022] = function(player)
  local my_followers = player:get_follower_idxs()
  if #player.hand == 0 or #my_followers == 0 then
    return
  end
  if pred.C(player.hand[1]) and #player:field_idxs_with_preds(pred.neg(pred.C)) == 0 then
    OneBuff(player,uniformly(my_followers),{atk={"+",2},sta={"+",2}}):apply()
  end
end,

--Swimwear Iri
[100023] = function(player)
  local target = player.opponent.field[5]
  if target then
    if pred.follower(target) then
      OneBuff(player.opponent,5,{atk={"-",1}}):apply()
    end
    player.opponent:field_to_bottom_deck(5)
  end
  local target_idx = uniformly(player.opponent:field_idxs_with_preds())
  if not target_idx then
    return
  end
  local card = player.opponent.field[target_idx]
  for i=target_idx,4 do
    if not player.opponent.field[i+1] then
      player.opponent.field[i+1] = card
      player.opponent.field[target_idx] = nil
      break
    end
  end
  if player.opponent.field[5] then
    player.opponent:destroy(5)
  end
end,

--Swimwear Vernika
[100024] = function(player)
  if #player.opponent.hand < 2 or #player:get_follower_idxs() == 0 then
    return
  end
  local new_size = math.abs(player.opponent.hand[1].size - player.opponent.hand[2].size)
  local target_idx = player:field_idxs_with_most_and_preds(pred.size, pred.follower)[1]
  if target_idx then
    OneBuff(player,target_idx,{size={"=",new_size}}):apply()
  end
end,

--Lightseeker Sita
[100025] = function(player)
  local nme_followers = player.opponent:get_follower_idxs()
  local target_idxs = player:field_idxs_with_preds(pred.D, pred.follower, function(card) return card.size < 10 end)
  if #target_idxs == 0 then
    return
  end
  local target_idx = uniformly(target_idxs)
  local buff_size = floor(1.5*player.field[target_idx].size)
  player:field_to_grave(target_idx)
  if #nme_followers > 0 then
    OneBuff(player.opponent,uniformly(nme_followers),{sta={"-",buff_size}}):apply()
  end
end,

--Foreign Student Cinia
[100026] = function(player)
  local my_followers = player:get_follower_idxs()
  if #my_followers == 0 or #player.hand == 0 then
    return
  end
  local target_idx = uniformly(my_followers)
  if pred.V(player.hand[1]) then
    OneBuff(player,target_idx,{atk={"+",1},sta={"+",2}}):apply()
  elseif pred.A(player.hand[1]) then
    OneBuff(player,target_idx,{sta={"+",3}}):apply()
  elseif pred.C(player.hand[1]) then
    OneBuff(player,target_idx,{def={"+",1}}):apply()
  elseif pred.D(player.hand[1]) then
    OneBuff(player,target_idx,{size={"-",2}}):apply()
  end
end,

--Blue Reaper Luthica
[100027] = function(player)
  local target_idxs = player:field_idxs_with_preds(pred.follower, pred.C)
  if #target_idxs == 0 then
    return
  end
  local crux_cards = #player.opponent:field_idxs_with_preds(pred.C) + #player.opponent:hand_idxs_with_preds(pred.C)
  local non_crux_cards = #player.opponent:field_idxs_with_preds() + #player.opponent.hand - crux_cards
  OneBuff(player,uniformly(target_idxs),{sta={"+",math.max(crux_cards, non_crux_cards)}}):apply()
end,

--Lovestruck Iri
[100028] = function(player)
  local factions = {}
  for i=1,5 do
    if player.opponent.hand[i] and factions[1] ~= player.opponent.hand[i].faction then
      factions[#factions+1] = player.opponent.hand[i].faction
    end
    if player.opponent.field[i] and factions[1] ~= player.opponent.field[i].faction then
      factions[#factions+1] = player.opponent.field[i].faction
    end
  end
  if #factions > 1 and #player.hand > 0 then
    local hand_idx = math.random(#player.hand)
    local buff = GlobalBuff(player)
    buff.hand[player][hand_idx] = {size={"-",2}}
    buff:apply()
  end
end,

--Night Denizen Vernika
[100029] = function(player)
  local nme_followers = player.opponent:get_follower_idxs()
  if #nme_followers > 0 then
    local target_idx = uniformly(nme_followers)
    OneBuff(player.opponent,target_idx,{sta={"-",3}}):apply()
    OneBuff(player, 0, {life={"+",1}}):apply()
  end
  local target = uniformly(player:field_idxs_with_preds(pred.follower, pred.D))
  if target then
    OneBuff(player, target, {sta={"+",2}}):apply()
  end
end,

--Thorn Witch Rose
[100030] = thorn_witch_rose,

-- rose pacifica
[100031] = function(player)
  local hand_idx = player:hand_idxs_with_preds(pred.D)[1]
  if hand_idx then
    local sz = player.hand[hand_idx].size
    player:hand_to_grave(hand_idx)
    local target = uniformly(player.opponent:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(player.opponent, target, {atk={"-",sz},sta={"-",sz}}):apply()
    end
  end
end,

-- blood witch rose
[100032] = function(player)
  if player.game.turn % 1 == 1 then
    local idx = uniformly(player.opponent:hand_idxs_with_preds(pred.spell))
    if idx then
      player.opponent:hand_to_exile(idx)
    end
  else
    local idx = uniformly(player.opponent:grave_idxs_with_preds(pred.spell))
    if idx then
      player.opponent:grave_to_exile(idx)
    end
  end
end,

-- outcast rose
[100033] = function(player)
  if #player:field_idxs_with_preds(pred.follower) >= 2 then
    local target = uniformly(player:field_idxs_with_preds(pred.follower))
    local buff = OnePlayerBuff(player)
    buff[0] = {life={"-",1}}
    if target then
      buff[target] = {atk={"+",2},def={"+",1},sta={"+",2}}
    end
    buff:apply()
  end
end,

-- picnic rose
[100034] = function(player)
  local targets = shuffle(player:field_idxs_with_preds(pred.follower))
  if #targets >= 2 then
    local amt = abs(player.field[targets[1]].size - player.field[targets[2]].size)
    local buff = OnePlayerBuff(player)
    for i=1,2 do
      buff[targets[i]] = {sta={"+",amt}}
    end
    buff:apply()
  end
end,

-- wedding dress rose
[100035] = function(player)
  thorn_witch_rose(player)
end,

-- wedding dress sita
[100036] = function(player)
  sita_vilosa(player)
  wedding_shuffles(player)
end,

-- wedding dress cinia
[100037] = function(player)
  cinia_pacifica(player)
  wedding_shuffles(player)
end,

-- wedding dress luthica
[100038] = function(player)
  luthica_preventer(player)
  wedding_shuffles(player)
end,

-- wedding dress iri
[100039] = function(player)
  iri_flina(player)
  wedding_shuffles(player)
end,

-- wedding dress vernika
[100040] = curious_vernika,

-- laevateinn
[100041] = function(player)
  local size_to_n = {}
  for i=1,#player.hand do
    local sz = player.hand[i].size
    size_to_n[sz] = (size_to_n[sz] or 0) + 1
  end
  local size = -1
  for k,v in pairs(size_to_n) do
    if v >= 2 and k > size then
      size = k
    end
  end
  if size > 0 then
    OneBuff(player, 0, {life={"+",ceil(size/2)}}):apply()
  end
end,

-- sisters sion & rion
[100042] = function(player)
  local field_idxs = player:field_idxs_with_preds(pred.follower)
  local hand_idxs = player:hand_idxs_with_preds(pred.follower)
  local target = uniformly(field_idxs)
  if target then
    OneBuff(player, target, {atk={"+",#hand_idxs},sta={"+",#field_idxs}}):apply()
  end
end,

-- head knight jaina
[100043] = head_knight_jaina,

-- resting jaina
[100044] = function(player, opponent, my_card)
  if player.game.turn % 3 == 0 then
    local targets = shuffle(player:field_idxs_with_preds(pred.follower, pred.C))
    local buff = OnePlayerBuff(player)
    for i=1,min(2,#targets) do
      buff[targets[i]] = {atk={"+",3},sta={"+",3}}
    end
    buff[0] = {life={"+",2}}
    buff:apply()
  end
end,

-- adept jaina
[100045] = function(player, opponent, my_card)
  local amt = min(4, 6-#player.hand)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, {atk={"+",amt}}):apply()
  end
end,

-- swimwear jaina
[100046] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target and player:first_empty_field_slot() then
    for i=target+1,5 do
      if not player.field[i] then
        local card = player.field[target]
        player.field[target] = nil
        player.field[i] = card
        OneBuff(player, i, {atk={"+",i}}):apply()
        return
      end
    end
    local slot = player:first_empty_field_slot()
    local card = player.field[target]
    player.field[target] = nil
    player.field[slot] = card
    OneBuff(player, slot, {atk={"+",slot}}):apply()
  end
end,

-- sword planter jaina
[100047] = function(player, opponent, my_card)
  local amt = 0
  local sizes = {}
  for i=1,#player.hand do
    if not sizes[player.hand[i].size] then
      sizes[player.hand[i].size] = true
      amt = amt + 1
    end
  end
  local targets = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i=1,min(2,#targets) do
    buff[targets[i]] = {atk={"+",amt}}
  end
  buff:apply()
end,

-- wedding dress jaina
[100048] = head_knight_jaina,

-- sigma
[100049] = function(player, opponent, my_card)
  local buff = GlobalBuff(player)
  local hand_targets = shuffle(player:hand_idxs_with_preds(pred.follower))
  local targets = shuffle(player:field_idxs_with_preds(pred.follower))
  for i=1,min(2,#hand_targets) do
    buff.hand[player][hand_targets[i]] = {atk={"+",1},sta={"+",1}}
  end
  for i=1,min(2,#targets) do
    buff.field[player][targets[i]] = {sta={"+",1}}
  end
  buff:apply()
end,

-- child sita
[100050] = function(player, opponent, my_card)
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs({1,2,5}) do
    if opponent.field[idx] and pred.follower(opponent.field[idx]) then
      buff[idx] = {sta={"-",2}}
    end
  end
  buff:apply()
end,

-- child cinia
[100051] = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    if opponent.field[target].size >= 3 then
      OneBuff(opponent, target, {atk={"-",2}}):apply()
    else
      OneBuff(opponent, target, {sta={"-",3}}):apply()
    end
  end
end,

-- child luthica
[100052] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower, pred.C))
  if target then
    if player.field[target].size >= 3 then
      OneBuff(player, target, {atk={"+",2}}):apply()
    else
      OneBuff(player, target, {sta={"+",3}}):apply()
    end
  end
end,

-- child iri
[100053] = function(player, opponent, my_card)
  if #player.hand % 2 == 0 then
    local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(opponent, target, {atk={"-",1},def={"-",1},sta={"-",1}}):apply()
    end
  end
end,

-- onsen sita
[100054] = function(player, opponent, my_card)
  local buff = OnePlayerBuff(opponent)
  for i=2,4 do
    if opponent.field[i] and pred.follower(opponent.field[i]) then
      buff[i] = {sta={"-",2}}
    end
  end
  buff:apply()
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(opponent, target, {sta={"-",1}}):apply()
  end
end,

-- onsen cinia
[100055] = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    if opponent.field[target].def >= 1 then
      OneBuff(opponent, target, {atk={"-",2},def={"-",1},sta={"-",2}}):apply()
    else
      OneBuff(opponent, target, {atk={"-",1},sta={"-",1}}):apply()
    end
  end
end,

-- onsen luthica
[100056] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    if player.field[target].def <= 2 then
      OneBuff(player, target, {atk={"+",2},def={"+",1},sta={"+",2}}):apply()
    else
      OneBuff(player, target, {atk={"+",2},sta={"+",2}}):apply()
    end
  end
end,

-- onsen iri
[100057] = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    if opponent.field[target].sta >= 12 then
      OneBuff(opponent, target, {atk={"-",2},def={"-",1},sta={"-",2}}):apply()
    else
      OneBuff(opponent, target, {atk={"-",1},def={"-",1}}):apply()
    end
  end
end,

-- miracle panda panica
[100058] = function(player, opponent, my_card)
  if player.game.turn % 2 ==1 then
    local buff = OnePlayerBuff(player)
    local targets = shuffle(player:field_idxs_with_preds(pred.follower))
    for i=1,min(2,#targets) do
      buff[targets[i]] = {atk={"+",1}}
    end
    buff:apply()
  else
    local target = uniformly(player:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(player, target, {sta={"+",2}}):apply()
    end
  end
end,

-- child vernika
[100059] = function(player, opponent, my_card)
  local idx = player:hand_idxs_with_preds(pred.V)[1]
  if idx then
    local amt = min(3,ceil(player.hand[idx].size/2))
    player:hand_to_bottom_deck(idx)
    local target = opponent:field_idxs_with_most_and_preds(pred.sta,pred.follower)[1]
    if target then
      OneBuff(opponent, target, {def={"-",amt},sta={"-",amt}}):apply()
    end
  end
end,

-- child rose
[100060] = function(player, opponent, my_card)
  local hand_idx = player:hand_idxs_with_preds(pred.spell, pred.A,
      function(card) return card.size <= (9-player:field_size()) end)[1]
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  local slot = player:first_empty_field_slot()
  if hand_idx and slot then
    local amt = player.hand[hand_idx].size
    player:hand_to_field(hand_idx)
    if target then
      OneBuff(opponent, target, {atk={"-",amt},sta={"-",amt}}):apply()
    end
  end
end,

-- child jaina
[100061] = function(player, opponent, my_card)
  local buff = GlobalBuff(player)
  local my_guy = uniformly(player:field_idxs_with_preds(pred.follower))
  local op_guy = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if my_guy then
    buff.field[player][my_guy] = {atk={"+",2}}
  end
  if op_guy then
    buff.field[opponent][op_guy] = {atk={"-",1}}
  end
  buff:apply()
end,

-- child ginger
[100062] = function(player, opponent, my_card)
  local followers = player:field_idxs_with_preds(pred.follower)
  local do_buff = #followers > 1
  local target = uniformly(followers)
  if target then
    if do_buff then
      OneBuff(player, target, {atk={"+",2}}):apply()
    end
    player:field_to_top_deck(target)
  end
  target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, {atk={"+",2}}):apply()
  end
end,

-- child laevateinn
[100063] = function(player)
  local size_to_n = {}
  for i=1,#player.hand do
    local sz = player.hand[i].size
    size_to_n[sz] = (size_to_n[sz] or 0) + 1
  end
  local size = -1
  for k,v in pairs(size_to_n) do
    if v >= 2 and k > size then
      size = k
    end
  end
  if size > 0 then
    for i=5,1,-1 do
      if player.hand[i] and player.hand[i].size == size then
        player:hand_to_bottom_deck(i)
      end
    end
    OneBuff(player, 0, {life={"+",min(4,ceil(size/2))}}):apply()
  end
end,

-- child sigma
[100064] = function(player, opponent, my_card)
  if player.hand[1] then
    local amt = min(4,floor(player.hand[1].size/2))
    player:hand_to_bottom_deck(1)
    local target = uniformly(player:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(player, target, {atk={"+",amt},sta={"+",amt}}):apply()
    end
  end
end,

-- layna scentriver
[100065] = luthica_preventer,

-- chief maid
[100066] = iri_flina,

-- new knight
[100067] = sita_vilosa,

-- nytitch
[100068] = cinia_pacifica,

-- alchemist clarice
[100069] = clarice({5,0,5}),

-- street idol clarice
[100070] = clarice("turn"),

-- assistant clarice
[100071] = clarice({1,0,9}),

-- swimwear clarice
[100072] = clarice({7,0,2}),

-- dress clarice
[100073] = clarice({3,0,3}, true),

-- wedding dress clarice
[100074] = clarice({5,0,5}),

-- lig nijes
[100075] = function(player, opponent)
  local life = opponent.character.life
  if 26 <= life then
    OneBuff(opponent, 0, {life={"-",1}}):apply()
  elseif 15 <= life and life <= 20 then
    OneBuff(opponent, 0, {life={"-",2}}):apply()
  elseif life <= 9 then
    OneBuff(player, 0, {life={"+",1}}):apply()
  end
end,

-- child nold
[100076] = function(player, opponent, my_card)
  if (player.game.turn + #player.hand) % 2 == 0 then
    local target = uniformly(player:field_idxs_with_preds(pred.follower,
        function(card) return card.size >= 2 end))
    if target then
      OneBuff(player, target, {size={"-",2}}):apply()
    end
  end
end,

-- child cannelle
[100077] = function(player, opponent, my_card)
  local target = uniformly(opponent:hand_idxs_with_preds(pred.follower))
  if target then
    local buff = GlobalBuff(player)
    buff.hand[opponent][target] = {size={"=",1},atk={"=",5},def={"=",0},sta={"=",7}}
    buff:apply()
  end
end,

-- child gart
[100078] = function(player, opponent, my_card)
  if #player:field_idxs_with_preds(pred.A) + #player:hand_idxs_with_preds(pred.A) == 0 then
    local target = uniformly(player:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(player, target, {atk={"+",2},sta={"+",1}}):apply()
    end
  end
end,

-- child panica
[100079] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    if player.game.turn % 2 == 0 then
      OneBuff(player, target, {atk={"+",2},sta={"+",3}}):apply()
    else
      OneBuff(player, target, {sta={"+",3}}):apply()
    end
  end
end,

-- No character ID 100080

-- bedroom nold
[100081] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower, pred.A))
  if target then
    OneBuff(player, target, {size={"-",1},sta={"+",2}}):apply()
  end
end,

-- No character ID 100082

-- bunny girl cannelle
[100083] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower,
      function(card) return card.size <= 5 end))
  if target then
    OneBuff(player, target, {size={"+",1},atk={"+",2},def={"+",1},sta={"+",2}}):apply()
  end
end,

-- rain-soaked gart
[100084] = function(player, opponent, my_card)
  local amt = #player:hand_idxs_with_preds(pred.follower)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(opponent, target, {def={"-",amt},sta={"-",amt}}):apply()
  end
end,

-- No character ID 100085

-- No character ID 100086

-- hammered sigma
[100087] = function(player, opponent, my_card)
  if #player.hand > 0 then
    local n = player.hand[1].size
    local targets = player:hand_idxs_with_preds(pred.follower)
    local buff = GlobalBuff(player)
    for i=1,min(n,#targets) do
      buff.hand[player][targets[i]] = {atk={"+",1},sta={"+",1}}
    end
    buff:apply()
  end
end,

-- anj inyghem
[100088] = function(player)
  local life = player.opponent.character.life
  if 31 <= life then
    OneBuff(player.opponent, 0, {life={"-",2}}):apply()
  elseif 20 <= life and life <= 25 then
    local target = uniformly(player:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(player, target, {atk={"+",1},sta={"+",2}}):apply()
    end
  elseif 10 <= life and life <= 15 then
    local target = uniformly(player.opponent:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(player.opponent, target, {atk={"-",1},sta={"-",2}}):apply()
    end
  elseif life <= 6 then
    OneBuff(player.opponent, 0, {life={"=",1}}):apply()
  end
end,

-- newbie guide rico
[100089] = function() end,

-- swimsuit sita
[100090] = function(player, opponent, my_card)
  local do_second = player.character.life < opponent.character.life
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(opponent, target, {sta={"-",3}}):apply()
  end
  if do_second then
    target = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(opponent, target, {sta={"-",2}}):apply()
    end
  end
end,

-- swimsuit cinia
[100091] = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    if player.character.life < opponent.character.life then
      OneBuff(opponent, target, {atk={"-",2},sta={"-",3}}):apply()
    else
      OneBuff(opponent, target, {atk={"-",1},sta={"-",2}}):apply()
    end
  end
end,

-- swimsuit luthica
[100092] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower, pred.C))
  if target then
    if player.character.life < opponent.character.life then
      OneBuff(player, target, {atk={"+",2},sta={"+",3}}):apply()
    else
      OneBuff(player, target, {atk={"+",1},sta={"+",2}}):apply()
    end
  end
end,

-- swimsuit iri
[100093] = function(player)
  if player.character.life < player.opponent.character.life then
    OneBuff(player.opponent, 0, {life={"-",2}}):apply()
  else
    OneBuff(player, 0, {life={"+",1}}):apply()
  end
end,

-- Connecting Shaman Nexia
[100094] = function(player)
  local mag = #player.hand
  if mag == 1 then
    player.shuffles = player.shuffles + 1
  elseif mag == 2 then
    local idx = uniformly(player:field_idxs_with_preds(pred.follower))
    if idx then
      OneBuff(player, idx, {atk={"+", 3}, sta={"+", 3}}):apply()
    end
  elseif mag == 3 then
    local idx = uniformly(player:field_idxs_with_preds(pred.follower))
    if idx then
      OneBuff(player, idx, {def={"+", 1}, sta={"+", 1}}):apply()
    end
  elseif mag == 4 then
    local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
    local buff= OnePlayerBuff(player)
    for i=1,min(2,#idxs) do
      buff[idxs[i]] = {atk={"+", 1}, sta={"+", 1}}
    end
    buff:apply()
  elseif mag == 5 then
    OneBuff(player, 0, {life={"-", 1}}):apply()
  end
end,

-- vita principal treanna
[100095] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    if pred.skill(player.field[target]) then
      player.field[target].skills = {}
      OneBuff(player, target, {size={"-",1},atk={"+",2},sta={"+",2}}):apply()
    else
      OneBuff(player, target, {atk={"+",2},sta={"+",2}}):apply()
    end
  end
end,

-- dean rihanna
[100096] = rihanna({sta={"+",3}},{atk={"+",2}}),

-- dress rihanna
[100097] = rihanna({atk={"+",1},sta={"+",2}},{atk={"+",2},sta={"+",1}}),

-- swimwear rihanna
[100098] = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  local slot = uniformly(opponent:empty_field_slots())
  if target and slot then
    local card = opponent.field[target]
    opponent.field[target] = nil
    opponent.field[slot] = card
    if slot <= 3 then
      OneBuff(opponent, slot, {atk={"-",1},sta={"-",2}}):apply()
    end
    if slot >= 3 and opponent.field[slot] then
      OneBuff(opponent, slot, {atk={"-",2},sta={"-",1}}):apply()
    end
  end
end,

-- waitress rihanna
[100099] = rihanna({sta={"+",4}},{size={"-",1},atk={"+",1}}),

-- persuasive rihanna
[100100] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  local slot = uniformly(player:empty_field_slots())
  if target and slot then
    local card = player.field[target]
    player.field[target] = nil
    player.field[slot] = card
  end
  target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  slot = uniformly(opponent:empty_field_slots())
  if target and slot then
    local card = opponent.field[target]
    opponent.field[target] = nil
    opponent.field[slot] = card
  end
  local do_steal = false
  for i=5,1,-1 do
    if player.field[i] and opponent.field[i] then
      do_steal = true
    end
  end
  slot = player:first_empty_field_slot()
  target = uniformly(opponent:field_idxs_with_preds())
  if do_steal and slot and target then
    local card = opponent.field[target]
    opponent.field[target] = nil
    player.field[slot] = card
  end
end,

-- wedding dress rihanna
[100101] = rihanna({sta={"+",3}},{atk={"+",2}}),

-- hanbok sita
[100102] = hanbok_sita,

-- hanbok cinia
[100103] = hanbok_cinia,

-- hanbok luthica
[100104] = hanbok_luthica,

-- hanbok iri
[100105] = hanbok_iri,

-- Confession Iri
[100106] = function(player, opponent)
  local buff = GlobalBuff(player)
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    buff.field[opponent][idx] = {atk={"-", 1}, sta={"-", 1}}
  end
  idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    buff.field[player][idx] = {atk={"+", 1}, sta={"+", 1}}
  end
  buff:apply()
end,

-- vernika answer
[100107] = function(player, opponent, my_card)
  for i=1,5 do
    while opponent.hand[i] and pred.spell(opponent.hand[i]) do
      opponent:hand_to_bottom_deck(i)
    end
  end
end,

-- waiting sita
[100108] = function(player, _, char)
  ex2_recycle(player, char)
  local buff = {atk={"+",2},sta={"+",2}}
  if #player.deck <= #player.opponent.deck then
    buff.def = {"+",1}
    buff.sta[2]=3
  end
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, buff):apply()
  end
end,

-- council president cinia
[100109] = function(player, _, char)
  ex2_recycle(player, char)
  if #player.deck <= #player.opponent.deck then
    local target = uniformly(player.opponent:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(player.opponent, target, {def={"-",1},sta={"-",2}}):apply()
    end
  end
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, {atk={"+",2},sta={"+",2}}):apply()
  end
end,

-- wanderer luthica
[100110] = function(player, _, char)
  ex2_recycle(player, char)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, {atk={"+",2},sta={"+",2}}):apply()
  end
  if #player.deck <= #player.opponent.deck then
    OneBuff(player.opponent, 0, {life={"-",1}}):apply()
    target = uniformly(player:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(player, target, {sta={"+",1}}):apply()
    end
  end
end,

-- conflicted iri
[100111] = function(player, _, char)
  ex2_recycle(player, char)
  if #player.deck <= #player.opponent.deck then
    local targets = shuffle(player.opponent:field_idxs_with_preds(pred.follower))
    if targets[1] then
      OneBuff(player.opponent, targets[1], {sta={"-",3}}):apply()
    end
    if targets[2] then
      OneBuff(player.opponent, targets[2], {sta={"-",1}}):apply()
    end
  end
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, {atk={"+",2},sta={"+",2}}):apply()
  end
end,

-- office chief esprit
[100112] = function(player, opponent, my_card)
  local nskills = 0
  local followers = player:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(followers) do
    nskills = nskills + #player.field[idx]:squished_skills()
  end
  if nskills <= 2 then
    local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if target then
      opponent.field[target].skills = {}
    end
  else
    local target = uniformly(followers)
    OneBuff(player, target, {atk={"+",nskills},sta={"+",nskills}}):apply()
  end
end,

-- council vp tieria
[100113] = council_vp_tieria(pred.student_council, pred.V),

-- maid lesnoa
[100114] = council_vp_tieria(pred.maid, pred.A),

-- seeker odien
[100115] = council_vp_tieria(pred.seeker, pred.C),

-- lightning palomporom
[100116] = council_vp_tieria(pred.witch, pred.D),

-- Ereshkigal
[100117] = function(player, opponent, my_card)
  local turn = player.game.turn
  if turn % 2 == 1 then
    local buff = GlobalBuff(player)
    local idx = uniformly(player:field_idxs_with_preds(pred.follower))
    if idx then
      buff.field[player][idx] = {atk={"+", 1}, sta={"+", 1}}
    end
    idx = uniformly(player:hand_idxs_with_preds(pred.follower))
    if idx then
      buff.hand[player][idx] = {atk={"+", 1}, sta={"+", 1}}
    end
    idx = player:deck_idxs_with_preds(pred.follower)[1]
    if idx then
      buff.deck[player][idx] = {atk={"+", 1}, sta={"+", 1}}
    end
    buff.field[player][0] = {life={"+", 1}}
    buff:apply()
  else
    local buff = GlobalBuff(player)
    local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if idx then
      buff.field[opponent][idx] = {atk={"-", 1}, sta={"-", 1}}
    end
    idx = uniformly(opponent:hand_idxs_with_preds(pred.follower))
    if idx then
      buff.hand[opponent][idx] = {atk={"-", 1}, sta={"-", 1}}
    end
    idx = opponent:deck_idxs_with_preds(pred.follower)[1]
    if idx then
      buff.deck[opponent][idx] = {atk={"-", 1}, sta={"-", 1}}
    end
    buff.field[opponent][0] = {life={"-", 1}}
    buff:apply()
  end
end,

-- apostle l red sun
[100118] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    if #player.deck > 0 and pred.follower(player.deck[#player.deck]) then
      OneBuff(player, target, {atk={"+",1},sta={"+",3}}):apply()
    else
      OneBuff(player, target, {atk={"+",1},sta={"+",1}}):apply()
    end
  end
end,

-- crux knight rosa
[100119] = function(player, opponent, my_card)
  if #player.hand == 5 then
    player:hand_to_top_deck(1)
  end
  local amt = min(2,5-#player.hand)
  local target = uniformly(player:deck_idxs_with_preds(pred.follower))
  if target then
    local buff = GlobalBuff(player)
    buff.deck[player][target] = {atk={"+",amt},sta={"+",amt}}
    buff:apply()
  end
  ep7_recycle(player)
end,

-- shaman helena k sync
[100120] = function(player, opponent, my_card)
  local buff = GlobalBuff(player)
  local amt = 1
  for _,idx in ipairs(opponent:field_idxs_with_preds(pred.follower)) do
    buff.field[opponent][idx] = {atk={"-",1}}
    amt = amt + 1
  end
  for _,idx in ipairs(opponent:hand_idxs_with_preds(pred.follower)) do
    buff.hand[opponent][idx] = {atk={"-",1}}
    amt = amt + 1
  end
  amt = min(3, amt)
  local target = player:deck_idxs_with_preds(pred.follower)[1]
  if target then
    buff.deck[player][target] = {atk={"+",amt}}
  end
  buff:apply()
  ep7_recycle(player)
end,

-- detective asmis
[100121] = function(player, opponent, my_card)
  local buff = GlobalBuff(player)
  if #opponent.deck > 0 and pred.spell(opponent.deck[#opponent.deck]) then
    buff.deck[opponent][#opponent.deck] = {size={"+",1}}
  elseif #player.deck > 0 then
    if pred.follower(player.deck[#player.deck]) then
      buff.deck[player][#player.deck] = {size={"-",1},atk={"+",1},sta={"+",1}}
    else
      buff.deck[player][#player.deck] = {size={"-",1}}
    end
  end
  buff:apply()
  ep7_recycle(player)
end,

-- witch cadet linus falco
[100122] = function(player, opponent, my_card)
  for i=1,2 do
    local buff = GlobalBuff(player)
    local target = uniformly(opponent:deck_idxs_with_preds(pred.follower))
    if target then
      buff.deck[opponent][target] = {atk={"-",1},sta={"-",1}}
    end
    buff:apply()
  end
  ep7_recycle(player)
end,

-- Knight Captain Eisenwane
[100123] = function(player, opponent)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(player, idx, {atk={"+", 1}, sta={"+", 2}}):apply()
  else
    OneBuff(opponent, 0, {life={"-", 1}}):apply()
  end
end,

-- GS 3rd Star
[100133] = function(player, opponent, my_card)
  player:to_bottom_deck(Card(300193))
  if player.character.life < opponent.character.life then
    OneBuff(player, 0, {life={"+",1}}):apply()
  end
end,

-- Kar Vistas
[100134] = function(player)
  if player:field_size() < 5 then
    return
  end
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    local mag = pred.dress_up(player.field[idx]) and 2 or 0
    OneBuff(player, idx, {size={"-", 1}, atk={"+", mag}, sta={"+", mag}}):apply()
  end
end,

-- Pocketball Queen Layna
[100135] = function(player, opponent)
  local mag = #player:field_idxs_with_preds(pred.follower)
  if mag == 0 then
    return
  end
  local buff = GlobalBuff(player)
  local my_idx = uniformly(player:field_idxs_with_preds(pred.follower))
  buff.field[player][my_idx] = {sta={"+", mag}}
  local op_idx = uniformly(opponent:hand_idxs_with_preds(pred.follower))
  if op_idx then
    buff.hand[opponent][op_idx] = {sta={"-", mag}}
  end
  buff:apply()
end,

-- Chaos Destroyer Seven
[100136] = function(player, opponent)
  if player.game.turn % 2 == 1 then
    for i=1,2 do
      player:to_grave(Card(300072))
    end
  else
    local idx = player:grave_idxs_with_preds(pred.D)
    idx = idx[#idx]
    if not idx then
      return
    end
    player:grave_to_exile(idx)
    local idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
    local buff = OnePlayerBuff(opponent)
    for i=1,2 do
      if idxs[i] then
        buff[idxs[i]] = {atk={"-", 1}, def={"-", 1}, sta={"-", 2}}
      end
    end
    buff:apply()
  end
end,

-- Rosie's Sister Lucy
[100137] = function(player)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(player, idx, {atk={"+", 1}, sta={"+", 1}}):apply()
  end
  if player.character.life > 10 then
    return
  end
  idx = uniformly(player:hand_idxs_with_preds(pred.follower))
  if idx then
    local buff = GlobalBuff(player)
    buff.hand[player][idx] = {atk={"+", 2}, sta={"+", 2}}
    buff:apply()
  end
end,

-- Cox of the Flame
[100138] = function(player, opponent)
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    for i=1,3 do
      opponent.field[idx]:remove_skill_until_refresh(i)
    end
    OneBuff(opponent, idx, {}):apply()
  end
  idx = uniformly(opponent:deck_idxs_with_preds(pred.follower))
  if idx then
    for i=1,3 do
      opponent.deck[idx]:remove_skill_until_refresh(i)
    end
  end
end,

-- Glacier of the Ice
[100139] = function(player)
  local check = false
  local idxs = {}
  while not player.hand[4] do
    local idx = player:deck_idxs_with_preds(pred.C)[1]
    if not idx then
      break
    end
    if pred.follower(player.deck[idx]) then
      table.insert(idxs, player:first_empty_hand_slot())
    end
    player:deck_to_hand(idx)
    check = true
  end
  if check then
    local buff = GlobalBuff(player)
    for _, idx in ipairs(idxs) do
      buff.hand[player][idx] = {size={"-", 1}, atk={"-", 1}, sta={"-", 1}}
    end
    buff:apply()
  else
    local idx = uniformly(player:field_idxs_with_preds(pred.follower))
    if idx then
      OneBuff(player, idx, {atk={"+", 1}, sta={"+", 1}}):apply()
    end
  end
end,

-- Sita Vilosa
[100140] = sita_vilosa,

-- Cinia Pacifica
[100141] = cinia_pacifica,

-- Luthica Preventer
[100142] = luthica_preventer,

-- Iri Flina
[100143] = iri_flina,

-- Henlifei
[100144] = function(player, opponent)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(player, idx, {atk={"+", 1}, sta={"+", 2}}):apply()
    return
  end
  idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(opponent, idx, {atk={"-", 1}, sta={"-", 2}}):apply()
  end
end,

-- Chairman Linia
[100145] = function(player)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    local buff = {}
    local orig = Card(player.field[idx].id, player.field[idx].upgrade_lvl)
    for _, stat in ipairs({"def", "sta"}) do
      if player.field[idx][stat] < orig[stat] then
        buff[stat] = {"=", orig[stat]}
      end
    end
    OneBuff(player, idx, buff):apply()
  end
end,

-- Swimwear Rose
[100146] = function(player)
  local idx = player:deck_idxs_with_preds(pred.follower)[1]
  if idx then
    local atk_mag = math.random(0, 4)
    local sta_mag = math.random(0, 4)
    local buff = GlobalBuff(player)
    buff.deck[player][idx] = {atk={"+", atk_mag}, sta={"+", sta_mag}}
    buff:apply()
  end
  ep7_recycle(player)
end,

-- Dress Asmis
[100169] = function(player, opponent, my_card)
  if #opponent.deck > 0 then
    local buff = GlobalBuff(opponent)
    local target = opponent.deck[#opponent.deck]
    buff.deck[opponent][#opponent.deck] = {size={"+",1}}
    if pred.follower(target) then
      target = uniformly(opponent:hand_idxs_with_preds(pred.follower))
      if target then
        buff.hand[opponent][target] = {atk={"-",1},sta={"-",1}}
      end
    elseif pred.spell(target) then
      target = uniformly(player:field_idxs_with_preds(pred.follower))
      if target then
        OneBuff(player, target, {atk={"+",1},sta={"+",1}}):apply()
      end
    end
    buff:apply()
  end
  ep7_recycle(player)
end,

-- Dress Linus
[100170] = function(player, opponent, my_card)
  local idxs = opponent:deck_idxs_with_preds(pred.follower)
  local buff = GlobalBuff(player)
  for i=1,min(2,#idxs) do
    buff.deck[opponent][idxs[i]] = {atk={"-",1},sta={"-",1}}
  end
  if #opponent.deck > 0 and opponent.deck[#opponent.deck].size <= 2 then
    local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if idx then
      buff.field[opponent][idx] = {atk={"-",1},sta={"-",1}}
    end
  end
  buff:apply()
  ep7_recycle(player)
end,

-- wafuku sita
[100171] = hanbok_sita,

-- wafuku cinia
[100172] = hanbok_cinia,

-- wafuku luthica
[100173] = hanbok_luthica,

-- wafuku iri
[100174] = hanbok_iri,

-- hero sita
[100182] = hanbok_sita,

-- hero cinia
[100183] = hanbok_cinia,

-- hero luthica
[100184] = hanbok_luthica,

-- hero iri
[100185] = hanbok_iri,

-- Dress Rose
[100193] = function(player, opponent, my_card)
  local idx = player:deck_idxs_with_preds(pred.follower)[1]
  if idx then
    local def = player.deck[idx].def
    local buff = GlobalBuff(player)
    buff.deck[player][idx] = {atk={"+",ceil(def/2)},sta={"+",def}}
    buff:apply()
  end
  ep7_recycle(player)
end,

-- Dress Helena
[100194] = function(player, opponent, my_card)
  local idx = opponent:deck_idxs_with_preds(pred.follower)[1]
  local amt = min(3, #player:field_idxs_with_preds(pred.follower))
  if idx then
    local buff = GlobalBuff(player)
    buff.deck[opponent][idx] = {atk={"-",amt}}
    local my_idx = uniformly(player:field_idxs_with_preds(pred.follower))
    if my_idx then
      buff.field[player][my_idx] = {atk={"+",amt}}
    end
    buff:apply()
  end
  ep7_recycle(player)
end,

-- Rinshan Kaihou Asmis
[100198] = function(player, opponent, my_card)
  local idx = uniformly(player:deck_idxs_with_preds(pred.follower))
  if idx and #player.hand < 5 then
    player:deck_to_hand(idx)
    local hidx = #player.hand
    if player.hand[1].size == player.hand[hidx].size then
      local buff = GlobalBuff(player)
      buff.hand[player][hidx] = {atk={"+",2},sta={"+",3}}
      buff:apply()
    end
  end
  ep7_recycle(player)
end,

-- Baker Linus
[100199] = function(player, opponent, my_card)
  if player.game.turn % 2 == 1 then
    local idx = player:grave_idxs_with_preds(pred.follower)[1]
    local fidx = player:first_empty_field_slot()
    if idx and fidx then
      player:grave_to_field(idx)
      OneBuff(player, fidx, {atk={"+",2},sta={"+",2}}):apply()
    end
  end
  ep7_recycle(player)
end,

-- Horseback Rose
[100200] = function(player, opponent, my_card)
  if #player.hand <= 2 then
    local idx = player:deck_idxs_with_preds(pred.follower)[1]
    if idx then
      local buff = GlobalBuff(player)
      buff.deck[player][idx] = {atk={"+",2},def={"+",1},sta={"+",2}}
      buff:apply()
    end
  elseif #player.hand >= 4 then
    local idx = player:field_idxs_with_preds(pred.follower)[1]
    if idx then
      OneBuff(player, idx, {atk={"+",2},sta={"+",2}}):apply()
    end
  end
  ep7_recycle(player)
end,

-- Flower Arrangement Helena
[100201] = function(player, opponent, my_card)
  local amt = 0
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  for i=#player.grave-3,#player.grave do
    if player.grave[i] and pred.follower(player.grave[i]) then
      amt = amt + 1
    end
  end
  amt = min(3, amt)
  if idx then
    OneBuff(player, idx, {atk={"+",amt}}):apply()
    local my_card = player.grave[#player.grave-3]
    local hidx = uniformly(opponent:hand_idxs_with_preds(pred.follower))
    if my_card and hidx and player.field[idx].atk >= 10 then
      local buff = GlobalBuff(player)
      buff.hand[opponent][hidx] = {atk={"-",my_card.size}}
      buff:apply()
    end
  end
  ep7_recycle(player)
end,

-- Pajama Asmis
[100213] = function(player, opponent, my_card)
  local idx = player:field_idxs_with_most_and_preds(pred.size, pred.follower)[1]
  if idx then
    player.field[idx].active = false
    OneBuff(player, idx, {size={"-",2}}):apply()
  else
    idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if idx then
      OneBuff(opponent, idx, {size={"+",1}}):apply()
    end
  end
end,

-- Pajama Linus
[100214] = function(player, opponent, my_card)
  local idx = opponent:field_idxs_with_most_and_preds(pred.atk, pred.follower)[1]
  if idx then
    opponent.field[idx].active = false
    OneBuff(opponent, idx, {atk={"-",2}}):apply()
  else
    idx = uniformly(player:field_idxs_with_preds(pred.follower))
    if idx then
      OneBuff(player, idx, {size={"+",1}}):apply()
    end
  end
end,

-- Pajama Rose
[100215] = function(player, opponent, my_card)
  local atk_pred = function(card) return card.atk <= 7 end
  local idx = uniformly(player:field_idxs_with_preds(pred.follower, atk_pred))
  if idx then
    player.field[idx].active = false
    OneBuff(player, idx, {atk={"+",player.field[idx].atk}}):apply()
  else
    idx = uniformly(player:field_idxs_with_preds(pred.follower))
    if idx then
      OneBuff(player, idx, {atk={"+",2}}):apply()
    end
  end
end,

-- Pajama Helena
[100216] = function(player, opponent, my_card)
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    local buff = GlobalBuff(player)
    local amt = 0
    for i=idx-1,idx+1 do
      if opponent.field[i] and pred.follower(opponent.field[i]) then
        buff.field[opponent][i] = {atk={"-",1}}
        amt = amt + 1
      end
    end
    opponent.field[idx].active = false
    local my_idx = uniformly(player:field_idxs_with_preds(pred.follower))
    if my_idx then
      buff.field[player][my_idx] = {sta={"+",amt}}
    end
    buff:apply()
  end
end,

-- Aspiring Detective Asmis
[100218] = function(player, opponent, my_card)
  if #player.grave < 3 then
    return
  end
  local sz = player.grave[#player.grave-2]
  player:grave_to_exile(#player.grave-2)
  local cards = {}
  local sz_pred = function(card) return card.size == sz end
  for _,idx in ipairs(opponent:field_idxs_with_preds(sz_pred)) do
    cards[#cards+1] = {"field",idx}
  end
  for _,idx in ipairs(opponent:hand_idxs_with_preds(sz_pred)) do
    cards[#cards+1] = {"hand",idx}
  end
  local card = uniformly(cards)
  if card then
    if card[1] == "hand" then
      opponent:hand_to_grave(card[2])
    else
      opponent:field_to_grave(card[2])
    end
  end
end,

-- Singer Songwriter Linus
[100219] = function(player, opponent, my_card)
  local idx = uniformly(player:grave_idxs_with_preds())
  if idx then
    local sz = player.grave[idx].size
    local acad = pred.A(player.grave[idx])
    player:grave_to_exile(idx)
    idx = uniformly(player:field_idxs_with_preds(pred.follower))
    if idx then
      local buff = GlobalBuff(player)
      local first_amt = ceil(sz/2)
      buff.field[player][idx] = {sta={"+",first_amt}}
      if acad then
        local opp_idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
        if opp_idx then
          buff.field[opponent][opp_idx] = {sta={"-",floor(first_amt/2)}}
        end
      end
      buff:apply()
    end
  end
end,

-- Gambler Rose
[100220] = function(player, opponent, my_card)
  if opponent.shuffles >= 3 then
    opponent.shuffles = opponent.shuffles - 1
  end
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    local amt = opponent.shuffles + 1
    OneBuff(player, idx, {atk={"+",amt},sta={"+",amt}}):apply()
  end
end,

-- Nurse Helena
[100221] = function(player, opponent, my_card)
  local size_to_n = {}
  for i=1,#player.hand do
    local sz = player.hand[i].size
    size_to_n[sz] = (size_to_n[sz] or 0) + 1
  end
  local size = -1
  for k,v in pairs(size_to_n) do
    if v >= 2 and k > size then
      size = k
    end
  end
  if size > 0 then
    for i=5,1,-1 do
      if player.hand[i] and player.hand[i].size == size then
        player:hand_to_bottom_deck(i)
      end
    end
    local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if idx then
      local amt = 1 + floor(size/2)
      OneBuff(opponent, idx, {atk={"-",amt},sta={"-",amt}}):apply()
    end
  end
end,

-- Wedding Dress Asmis
[100228] = function(player, opponent, my_card)
  local buff = GlobalBuff(player)
  if #opponent.deck > 0 and pred.spell(opponent.deck[#opponent.deck]) then
    buff.deck[opponent][#opponent.deck] = {size={"+",1}}
  elseif #player.deck > 0 then
    if pred.follower(player.deck[#player.deck]) then
      buff.deck[player][#player.deck] = {size={"-",1},atk={"+",1},sta={"+",1}}
    else
      buff.deck[player][#player.deck] = {size={"-",1}}
    end
  end
  buff:apply()
  ep7_recycle(player)
end,

-- Wedding Dress Linus
[100229] = function(player, opponent, my_card)
  for i=1,2 do
    local buff = GlobalBuff(player)
    local target = uniformly(opponent:deck_idxs_with_preds(pred.follower))
    if target then
      buff.deck[opponent][target] = {atk={"-",1},sta={"-",1}}
    end
    buff:apply()
  end
  ep7_recycle(player)
end,

-- Wedding Dress Rose
[100230] = function(player, opponent, my_card)
  if #player.hand == 5 then
    player:hand_to_top_deck(1)
  end
  local amt = min(2,5-#player.hand)
  local target = uniformly(player:deck_idxs_with_preds(pred.follower))
  if target then
    local buff = GlobalBuff(player)
    buff.deck[player][target] = {atk={"+",amt},sta={"+",amt}}
    buff:apply()
  end
  ep7_recycle(player)
end,

-- Wedding Dress Helena
[100231] = function(player, opponent, my_card)
  local buff = GlobalBuff(player)
  local amt = 1
  for _,idx in ipairs(opponent:field_idxs_with_preds(pred.follower)) do
    buff.field[opponent][idx] = {atk={"-",1}}
    amt = amt + 1
  end
  for _,idx in ipairs(opponent:hand_idxs_with_preds(pred.follower)) do
    buff.hand[opponent][idx] = {atk={"-",1}}
    amt = amt + 1
  end
  amt = min(3, amt)
  local target = player:deck_idxs_with_preds(pred.follower)[1]
  if target then
    buff.deck[player][target] = {atk={"+",amt}}
  end
  buff:apply()
  ep7_recycle(player)
end,

-- Halloween Sita
[100232] = function(player, opponent)
	if player.game.turn == 1 then
		local idxs = player:deck_idxs_with_preds(pred.follower, pred.sita)
		local buff = GlobalBuff(player)
		for _, idx in ipairs(idxs) do
			buff.deck[player][idx] = {sta={"+", 1}}
		end
		buff:apply()
	end
	if player.character.life < 12 then
		player.shuffles = 0
		return
	elseif player.character.life == 12 then
		return
	end
	local buff = OnePlayerBuff(opponent)
	for i = 1, 3 do
		if opponent.field[i] then
			buff[i] = {atk={"-", 1}, sta={"-", 2}}
		end
	end
	buff:apply()
end,

-- Halloween Cinia
[100233] = function(player, opponent)
	if player.game.turn == 1 then
		local idxs = player:deck_idxs_with_preds(pred.follower, pred.cinia)
		local buff = GlobalBuff(player)
		for _, idx in ipairs(idxs) do
			buff.deck[player][idx] = {sta={"+", 1}}
		end
		buff:apply()
	end
	if player.character.life < 12 then
		player.shuffles = 0
		return
	elseif player.character.life == 12 then
		return
	end
	local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
	if idx then
		OneBuff(opponent, idx, {atk={"-", 2}, sta={"-", 3}}):apply()
	end
end,

-- Halloween Luthica
[100234] = function(player)
	if player.game.turn == 1 then
		local idxs = player:deck_idxs_with_preds(pred.follower, pred.luthica)
		local buff = GlobalBuff(player)
		for _, idx in ipairs(idxs) do
			buff.deck[player][idx] = {sta={"+", 1}}
		end
		buff:apply()
	end
	if player.character.life < 12 then
		player.shuffles = 0
		return
	elseif player.character.life == 12 then
		return
	end
	local idx = uniformly(player:field_idxs_with_preds(pred.follower))
	if idx then
		OneBuff(opponent, idx, {atk={"+", 2}, sta={"+", 3}}):apply()
	end
end,
	
-- Halloween Iri
[100235] = function(player, opponent)
	if player.game.turn == 1 then
		local idxs = player:deck_idxs_with_preds(pred.follower, pred.iri)
		local buff = GlobalBuff(player)
		for _, idx in ipairs(idxs) do
			buff.deck[player][idx] = {sta={"+", 1}}
		end
		buff:apply()
	end
	if player.character.life < 12 then
		player.shuffles = 0
		return
	elseif player.character.life == 12 then
		return
	end
	local buff = OnePlayerBuff(opponent)
	buff[0] = {life={"-", 1}}
	local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
	if idx then
		buff[idx] = {atk={"-", 1}, sta={"-", 1}}
	end
	buff:apply()
end,

-- Halloween Asmis
[100236] = function(player)
	if player.game.turn == 1 then
		local idxs = player:deck_idxs_with_preds(pred.follower, pred.asmis)
		local buff = GlobalBuff(player)
		for _, idx in ipairs(idxs) do
			buff.deck[player][idx] = {sta={"+", 1}}
		end
		buff:apply()
	end
	if player.character.life < 12 then
		player.shuffles = 0
		return
	elseif player.character.life == 12 then
		return
	end
	local buff = GlobalBuff(player)
	if player.deck[1] then
		buff.deck[player][1] = {size={"-", 1}}
		if player.deck[3] then
			buff.deck[player][3] = {size={"-", 1}}
		end
	end
	buff:apply()
end,

-- Halloween Linus
[100237] = function(player, opponent)
	if player.game.turn == 1 then
		local idxs = player:deck_idxs_with_preds(pred.follower, pred.linus)
		local buff = GlobalBuff(player)
		for _, idx in ipairs(idxs) do
			buff.deck[player][idx] = {sta={"+", 1}}
		end
		buff:apply()
	end
	if player.character.life < 12 then
		player.shuffles = 0
		return
	elseif player.character.life == 12 then
		return
	end
	local buff = GlobalBuff(player)
	local idxs = opponent:deck_idxs_with_preds(pred.follower)
	for i = 1, 2 do
		if idxs[i] then
			buff.deck[opponent][idxs[i]] = {atk={"-", 1}, sta={"-", 1}}
		end
	end
	buff:apply()
end,

-- Halloween Rose
[100238] = function(player)
	if player.game.turn == 1 then
		local idxs = player:deck_idxs_with_preds(pred.follower, pred.rose)
		local buff = GlobalBuff(player)
		for _, idx in ipairs(idxs) do
			buff.deck[player][idx] = {sta={"+", 1}}
		end
		buff:apply()
	end
	if player.character.life < 12 then
		player.shuffles = 0
		return
	elseif player.character.life == 12 then
		return
	end
	local buff = GlobalBuff(player)
	local idxs = player:deck_idxs_with_preds(pred.follower)
	for i = 1, 2 do
		if idxs[i] then
			buff.deck[player][idxs[i]] = {atk={"+", 1}, sta={"+", 1}}
		end
	end
	buff:apply()
end,

-- Halloween Helena
[100239] = function(player, opponent)
	if player.game.turn == 1 then
		local idxs = player:deck_idxs_with_preds(pred.follower, pred.helena)
		local buff = GlobalBuff(player)
		for _, idx in ipairs(idxs) do
			buff.deck[player][idx] = {sta={"+", 1}}
		end
		buff:apply()
	end
	if player.character.life < 12 then
		player.shuffles = 0
		return
	elseif player.character.life == 12 then
		return
	end
	local buff = GlobalBuff(player)
	local idxs = opponent:field_idxs_with_preds(pred.follower)
	for _, idx in ipairs(idxs) do
		buff.field[opponent][idx] = {atk={"-", 1}}
	end
	local idx = player:hand_idxs_with_preds(pred.follower)[1]
	if idx then
		buff.hand[player][idx] = {atk={"+", 2}}
	end
	buff:apply()
end,

-- Bunny Lady
[110001] = function(player, opponent, my_card)
  buff_random(player, opponent, my_card, {sta={"+",1}})
end,

-- Wind Shear
[110002] = function(player, opponent, my_card)
  buff_random(player, opponent, my_card, {sta={"+",1}})
end,

-- Winged Seeker
[110003] = function(player, opponent)
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(opponent:field_idxs_with_preds(pred.follower)) do
    if (opponent.field[idx].size + idx) % 2 == 0 then
      buff[idx] = {atk={"-",1},sta={"-",1}}
    end
  end
  buff:apply()
end,

-- Enchantress
[110004] = function(player, opponent, my_card)
  buff_random(player, opponent, my_card, {atk={"+",1}})
end,

-- Trickster
[110005] = function(player, opponent, my_card)
  buff_random(player, opponent, my_card, {atk={"+",1}})
end,

-- Myo Observer
[110006] = function(player, opponent, my_card)
  buff_random(player, opponent, my_card, {atk={"+",1}})
end,

-- True Bunny Lady 
[110007] = function(player, opponent, my_card)
  buff_all(player, opponent, my_card, {sta={"+",1}})
end,

-- True Wind Shear
[110008] = function(player, opponent, my_card)
  buff_all(player, opponent, my_card, {sta={"+",1}})
end,

-- Wind Breaker  
[110009] = function(player)
  local target_idxs = player.opponent:field_idxs_with_preds(pred.follower)
  if #target_idxs == 0 then
    return
  end
  OneBuff(player.opponent, uniformly(target_idxs), {sta={"-",2}}):apply()
end,

-- Wind Sneaker
[110010] = function(player)
  if #player.hand == 0 then
    return
  end
  local buff = GlobalBuff(player)
  buff.hand[player][math.random(#player.hand)] = {size={"-",1}}
  buff:apply()
end,

-- Wind Forestier  
[110011] = wind_forestier({"sta"}),

-- True Enchantress
[110012] = function(player, opponent, my_card)
  buff_all(player, opponent, my_card, {atk={"+",1}})
end,

-- True Trickster
[110013] = function(player, opponent, my_card)
  buff_random(player, opponent, my_card, {size={"-",2}})
end,

-- True Myo Observer
[110014] = function(player, opponent, my_card)
  buff_all(player, opponent, my_card, {atk={"+",1}})
end,

-- True Wind Breaker
[110015] = function(player, opponent)
  local target_idxs = shuffle(opponent:field_idxs_with_preds({pred.follower}))
  if target_idxs[1] then
    OneBuff(opponent, target_idxs[1], {sta={"-",2}}):apply()
  end
  local target_idxs2 = shuffle(opponent:field_idxs_with_preds({pred.follower}))
  if target_idxs2[1] then
    OneBuff(opponent, target_idxs2[1], {sta={"-",1}}):apply()
  end
end,

-- True Wind Sneaker
[110016] = function(player)
  if #player.hand == 1 then
    local buff = GlobalBuff(player)
    buff.hand[player][math.random(#player.hand)] = {size={"-",1}}
    buff:apply()
  elseif #player.hand > 1 then
    local buff = GlobalBuff(player)
    local idxs = {}
    for i=1,#player.hand do
      idxs[i] = i
    end
    local target_idxs = shuffle(idxs)
    buff.hand[player][target_idxs[1]] = {size={"-",1}}
    buff.hand[player][target_idxs[2]] = {size={"-",1}}
    buff:apply()
  end
end,

-- True Wind Forestier
[110017] = wind_forestier({"atk", "sta"}),

-- Doppelganger Sita
[110018] = function(player)
  local target_idxs = player.opponent:get_follower_idxs()
  local buff = OnePlayerBuff(player.opponent)
  for _,idx in ipairs(target_idxs) do
    if idx < 4 and player.opponent.field[idx] then
      buff[idx] = {sta={"-",1}}
    end
  end
  buff:apply()
end,

-- Doppelganger Cinia
[110019] = function(player)
  local target_idxs = player.opponent:get_follower_idxs()
  if #target_idxs == 0 then
    return
  end
  local target_idx = uniformly(target_idxs)
  OneBuff(player.opponent,target_idx,{atk={"-",1},sta={"-",1}}):apply()
end,

-- Doppelganger Luthica
[110020] = function(player)
  local target_idxs = player:field_idxs_with_preds(pred[player.character.faction], pred.follower)
  if #target_idxs == 0 then
    return
  end
  local target_idx = uniformly(target_idxs)
  OneBuff(player,target_idx,{atk={"+",1},sta={"+",1}}):apply()
end,

-- Doppelganger Iri
[110021] = function(player)
  if player:field_size() > player.opponent:field_size() then
    OneBuff(player.opponent,0,{life={"-",1}}):apply()
  end
end,

--Wind Gambler
[110022] = function(player)
  if player.character.life % 2 == 1 then
    OneBuff(player, 0, {life={"-",1}}):apply()
  else
    OneBuff(player, 0, {life={"+",2}}):apply()
  end
end,

--Wind Girl
[110023] = function(player)
  OneBuff(player, 0, {life={"+",1}}):apply()
end,

--Night Witch Nytitch
[110024] = function(player, opponent, my_card)
  local buff = GlobalBuff(player)
  buff.field[opponent][0] = {life={"-",2}}
  buff.field[player][0] = {life={"-",1}}
  buff:apply()
end,

--Night Witch Laetitia Ful
[110025] = function(player, opponent, my_card)
  local idx = uniformly(opponent:hand_idxs_with_preds(pred.spell))
  if idx then
    local buff = GlobalBuff(player)
    buff.hand[opponent][idx] = {size={"+",2}}
    buff:apply()
  end
end,

--Night Witch Magy Shen
[110026] = function(player, opponent, my_card)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower, pred.D))
  local buff = OnePlayerBuff(player)
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = {atk={"+",1},sta={"+",1}}
  end
  buff:apply()
end,

--Night Witch Seriot
[110027] = function(player, opponent, my_card)
  local idx = uniformly(opponent:hand_idxs_with_preds(pred.spell))
  if idx then
    opponent:hand_to_grave(idx)
  end
end,

--Succubus Cantabile
[110028] = function(player, opponent, my_card)
  local idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(opponent)
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = {def={"-",1}}
  end
  buff:apply()
end,

--True Nytitch
[110029] = function(player, opponent, my_card)
  local buff = GlobalBuff(player)
  buff.field[opponent][0] = {life={"-",1}}
  buff.field[player][0] = {life={"+",1}}
  buff:apply()
end,

--True Laetitia Ful
[110030] = function(player, opponent, my_card)
  local idx = uniformly(opponent:hand_idxs_with_preds(pred.spell))
  local field_idx = opponent:first_empty_field_slot()
  if idx and field_idx then
    opponent:hand_to_field(idx)
    opponent.field[field_idx].active = false
  end
end,

--True Magy Shen
[110031] = function(player, opponent, my_card)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower, pred.D))
  local buff = OnePlayerBuff(player)
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = {atk={"+",1},def={"+",1},sta={"+",1}}
  end
  buff:apply()
end,

--True Seriot
[110032] = function(player, opponent, my_card)
  for i=1,5 do
    while opponent.hand[i] and pred.spell(opponent.hand[i]) do
      opponent:hand_to_grave(i)
    end
  end
end,

--R. Cantabile
[110033] = function(player, opponent, my_card)
  local idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(opponent)
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = {def={"-",2}}
  end
  buff:apply()
end,

--Shadow Trickster Shion
[110034] = function(player, opponent, my_card)
  local idx = uniformly(player:grave_idxs_with_preds(pred.spell))
  if idx then
    player:grave_to_bottom_deck(idx)
  end
  local slot = player:first_empty_field_slot()
  if slot then
    player.field[slot] = Card(300057)
    OneBuff(player, slot, {size={"-",2}}):apply()
  end
end,

--Shadow Trickster Rion
[110035] = function(player, opponent, my_card)
  local idx = uniformly(player:grave_idxs_with_preds(pred.spell))
  if idx then
    player:grave_to_bottom_deck(idx)
  end
  local slot = player:first_empty_field_slot()
  if slot then
    player.field[slot] = Card(300058)
    OneBuff(player, slot, {size={"-",2}}):apply()
  end
end,

--Doppelganger Vernika
[110036] = function(player, opponent, my_card)
  local idx = opponent:field_idxs_with_most_and_preds(pred.def, pred.follower)[1]
  if idx then
    OneBuff(opponent,idx,{def={"=",0}}):apply()
  end
end,

--Doppelganger Rose
[110037] = function(player, opponent, my_card)
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    local buff_amt = ceil(math.abs(opponent.field[idx].size - opponent.field[idx].def)/2)
    OneBuff(opponent,idx,{atk={"-",buff_amt},sta={"-",buff_amt}}):apply()
  end
end,

--Shadow Nold
[110038] = function(player, opponent, my_card)
  local idx = uniformly(player:field_idxs_with_preds())
  if idx then
    OneBuff(player, idx, {size={"-",1}}):apply()
  end
end,

--Shadow Cannelle
[110039] = function(player, opponent, my_card)
  if player.opponent:field_size() == 0 or #player:get_follower_idxs() == 0 then
    return
  end
  local max_size = player.opponent.field[player.opponent:field_idxs_with_most_and_preds(pred.size)[1]].size
  local min_size = player.field[player:field_idxs_with_least_and_preds(pred.size)[1]].size
  local buff_size = abs(max_size - min_size)
  local target_idxs = player:field_idxs_with_least_and_preds(pred.size, pred.follower)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {atk={"+",buff_size}, sta={"+",buff_size}}
  end
  buff:apply()
end,

--Shadow Gart
[110040] = function(player, opponent, my_card)
  local faction_pred = function(card) return card.faction ~= my_card.faction end
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower, faction_pred))
  if idx then
    OneBuff(opponent, idx, {atk={"-",2},def={"-",2},sta={"-",2}}):apply()
  end
end,

--Shadow Ginger
[110041] = function(player, opponent, my_card)
  local ncards = #player:field_idxs_with_preds()
  local target_idxs = player:field_idxs_with_preds(pred.follower, function(card) return card.size >= ncards end)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {atk={"+",1}, sta={"+",1}}
  end
  buff:apply()
end,

--Shadow Laevateinn
[110042] = function(player, opponent, my_card)
  local size_to_n = {}
  for i=1,#player.hand do
    local sz = player.hand[i].size
    size_to_n[sz] = (size_to_n[sz] or 0) + 1
  end
  local size = -1
  for k,v in pairs(size_to_n) do
    if v >= 2 and k > size then
      size = k
    end
  end
  if size > 0 then
    OneBuff(player, 0, {life={"+",ceil(size/2)}}):apply()
  end
end,

--True Wind Gambler
[110043] = function(player, opponent, my_card)
  if player.character.life % 2 == 1 then
    OneBuff(player, 0, {life={"-",1}}):apply()
  else
    OneBuff(player, 0, {life={"+",3}}):apply()
  end
end,

--True Wind Girl
[110044] = function(player, opponent, my_card)
  OneBuff(player, 0, {life={"+",2}}):apply()
end,

--New Paramedic Lina
[110047] = function(player, opponent, my_card)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  local amt = 5-#opponent.hand
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = {sta={"+",amt}}
  end
  buff:apply()
end,

--Scribe Cecilia
[110048] = function(player, opponent, my_card)
  local idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(opponent)
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = {atk={"-",1}}
  end
  buff:apply()
end,

--Swordswoman Karen
[110049] = function(player, opponent, my_card)
  local my_idx = player:field_idxs_with_preds(pred.follower)[1]
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if my_idx and target then
    OneBuff(opponent, target, {sta={"-",player.field[my_idx].size}}):apply()
  end
end,

--Tactician Ellie
[110050] = function(player, opponent, my_card)
  local target = uniformly(opponent:hand_idxs_with_preds(pred.follower))
  if target then
    local card = opponent:remove_from_hand(target)
    player:to_bottom_deck(card)
  end
end,

--Superior Officer Marianne
[110051] = function(player, opponent, my_card)
  local function wrong_faction(card)
    return card.faction ~= opponent.character.faction
  end
  local amt = ceil(#opponent:hand_idxs_with_preds(wrong_faction)/2)
  for i=1,amt do
    local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if target then
      opponent:field_to_grave(target)
    end
  end
end,

--Instructor Pipin
[110052] = function(player, opponent, my_card)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = {atk={"+",2},sta={"+",1}}
  end
  buff:apply()
end,

--Instructor Rena
[110053] = function(player, opponent, my_card)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = {atk={"+",1},sta={"+",2}}
  end
  buff:apply()
end,

--Paramedic Lina
[110054] = function(player, opponent, my_card)
  buff_all(player, opponent, my_card, {sta={"+",#player.hand}})
end,

--Top Scribe Cecilia
[110055] = function(player, opponent, my_card)
  local idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(opponent)
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = {size={"+",1},atk={"-",1}}
  end
  buff:apply()
end,

--Swordmaster Karen
[110056] = function(player, opponent, my_card)
  local my_idx = player:field_idxs_with_preds(pred.follower)[1]
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if my_idx and target then
    OneBuff(opponent, target, {sta={"-",player.field[my_idx].atk}}):apply()
  end
end,

--Expert Tactician Ellie
[110057] = function(player, opponent, my_card)
  local target = uniformly(opponent:hand_idxs_with_preds(pred.follower))
  local slot = opponent:first_empty_field_slot()
  if target and slot then
    opponent:hand_to_field(target)
    opponent.field[slot].active = false
    OneBuff(opponent, slot, {atk={"-",1},sta={"-",1}}):apply()
  end
end,

--General Marianne
[110058] = function(player, opponent, my_card)
  local target = uniformly(player:deck_idxs_with_preds(pred.follower))
  local slot = player:first_empty_field_slot()
  if target and slot then
    player:deck_to_field(target, slot)
    OneBuff(player, slot, {atk={"+",1},def={"+",1},sta={"+",1}}):apply()
  end
end,

-- New Knight
[110059] = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(opponent, target, {atk={"-",1},sta={"-",1}}):apply()
  end
end,

-- Chief Maid
[110060] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, {atk={"+",2}}):apply()
  end
end,

-- Frett
[110061] = function(player, opponent, my_card)
  local function size_3(card) return card.size == 3 end
  local targets = player:field_idxs_with_preds(pred.follower, size_3)
  local buff = OnePlayerBuff(player)
  for i=1,#targets do
    buff[targets[i]] = {atk={"+",1},sta={"+",1}}
  end
  buff:apply()
end,

-- Mop Maid
[110062] = function(player, opponent, my_card)
  local buff = OnePlayerBuff(player)
  for i=1,5 do
    if player.field[i] and pred.follower(player.field[i]) and
        ((player.field[i-1] and pred.follower(player.field[i-1])) or
        (player.field[i+1] and pred.follower(player.field[i+1]))) then
      buff[i] = {atk={"+",2}}
    end
  end
  buff:apply()
end,

-- Layna Scentriver
[110063] = function(player, opponent, my_card)
  buff_all(player, opponent, my_card, {sta={"+",#player.hand}})
end,

-- Disaster Maid
[110069] = function(player, opponent, my_card)
  local p = uniformly({player, opponent})
  local idx = p:field_idxs_with_preds(pred.follower)[1]
  if idx then
    OneBuff(p, idx, {sta={"-",5}}):apply()
  end
end,

-- Master Kitchen Maid
[110070] = function(player, opponent, my_card)
  buff_random(player, opponent, my_card, {atk={"+",1},def={"+",1},sta={"+",2}})
end,

-- Master Cleaning Maid
[110071] = function(player, opponent, my_card)
  local p = uniformly({player, opponent})
  for i=1,2 do
    local slot = p:first_empty_field_slot()
    if #opponent.hand > 0 and slot then
      p.field[slot] = opponent:remove_from_hand(1)
    end
  end
end,

-- Tea Maid
[110072] = function(player, opponent, my_card)
  local p = uniformly({player, opponent})
  local buff = {life={"-",1}}
  if p == opponent then
    buff = {life={"-",3}}
  end
  OneBuff(p, 0, buff):apply()
end,

-- Head Maid Rise
[110073] = function(player, opponent, my_card)
  local p = uniformly({player, opponent})
  local idx = uniformly(p:field_idxs_with_preds())
  if idx then
    p:destroy(idx)
  end
end,

-- R. Chief Maid
[110074] = function(player, opponent, my_card)
  buff_random(player, opponent, my_card, {atk={"+",3}})
end,

-- R. Mop Maid
[110075] = function(player, opponent, my_card)
  buff_random(player, opponent, my_card, {atk={"+",2},sta={"+",2}})
end,

-- Moonlight Vampire
[110082] = function(player, opponent, my_card)
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    local buff_amt = ceil(math.abs(opponent.field[idx].size - opponent.field[idx].def)/2)
    OneBuff(opponent,idx,{atk={"-",buff_amt},sta={"-",buff_amt}}):apply()
  end
end,

-- R. Scardel Merlot
[110083] = function(player, opponent, my_card)
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(opponent, idx, {sta={"-",2}}):apply()
  end
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(opponent, idx, {sta={"-",1}}):apply()
  end
end,

-- R. Scardel Chardonnay
[110084] = function(player, opponent, my_card)
  local buff = GlobalBuff(player)
  buff.field[player][0] = {life={"+",1}}
  buff.field[opponent][0] = {life={"-",1}}
  buff:apply()
end,

-- R. Scardel Sangiovese
[110085] = function(player, opponent, my_card)
  local idxs = shuffle(player:hand_idxs_with_preds())
  local buff = GlobalBuff(player)
  for i=1,min(2,#idxs) do
    buff.hand[player][idxs[i]] = {size={"-",1}}
  end
  buff:apply()
end,

-- R. Scardel Viognier
[110086] = function(player, opponent, my_card)
  local idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(opponent)
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = {size={"+",1},atk={"-",1}}
  end
  buff:apply()
end,

-- R. Scardel Shiraz
[110087] = function(player, opponent, my_card)
  local target = uniformly(opponent:hand_idxs_with_preds(pred.follower))
  if target then
    local card = opponent:remove_from_hand(target)
    player:to_bottom_deck(card)
  end
end,

-- R. Scardel Pinot Noir
[110088] = function(player, opponent, my_card)
  local my_guy = player:field_idxs_with_preds(pred.follower)[1]
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if my_guy and target then
    OneBuff(opponent, target, {sta={"-",player.field[my_guy].atk}}):apply()
  end
end,

-- R. Moonlight Vampire
[110089] = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    local amt = floor(player.game.turn / 2)
    OneBuff(opponent, target, {atk={"-",amt},sta={"-",amt}}):apply()
  end
end,

-- Child Panica
[110090] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    if player.game.turn % 2 == 0 then
      OneBuff(player, target, {atk={"+",1},sta={"+",3}}):apply()
    else
      OneBuff(player, target, {sta={"+",3}}):apply()
    end
  end
end,

-- Child Ginger
[110091] = function(player, opponent, my_card)
  local followers = player:field_idxs_with_preds(pred.follower)
  local target = uniformly(followers)
  if target then
    OneBuff(player, target, {atk={"+",2}}):apply()
    player:field_to_top_deck(target)
  end
  target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, {atk={"+",2}}):apply()
  end
end,

-- Child Nold
[110092] = function(player, opponent, my_card)
  if (player.game.turn + #player.hand) % 2 == 0 then
    local target = uniformly(player:field_idxs_with_preds(pred.follower,
        function(card) return card.size >= 2 end))
    if target then
      OneBuff(player, target, {size={"-",2}}):apply()
    end
  end
end,

-- Child Cannelle
[110093] = function(player, opponent, my_card)
  local target = uniformly(opponent:hand_idxs_with_preds(pred.follower))
  if target then
    local buff = GlobalBuff(player)
    buff.hand[opponent][target] = {size={"=",1},atk={"=",5},def={"=",0},sta={"=",5}}
    buff:apply()
  end
end,

-- Child Vernika
[110094] = function(player, opponent, my_card)
  local idx = player:hand_idxs_with_preds()[1]
  if idx then
    local amt = min(3,ceil(player.hand[idx].size/2))
    player:hand_to_bottom_deck(idx)
    local target = opponent:field_idxs_with_most_and_preds(pred.sta,pred.follower)[1]
    if target then
      OneBuff(opponent, target, {def={"-",amt}}):apply()
    end
  end
end,

-- Child Jaina
[110095] = function(player, opponent, my_card)
  local buff = GlobalBuff(player)
  local my_guy = uniformly(player:field_idxs_with_preds(pred.follower))
  local op_guy = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if my_guy then
    buff.field[player][my_guy] = {atk={"+",2}}
  end
  if op_guy then
    buff.field[opponent][op_guy] = {atk={"-",1}}
  end
  buff:apply()
end,

-- Child Rose
[110096] = function(player, opponent, my_card)
  local hand_idx = player:hand_idxs_with_preds(pred.spell, pred.A,
      function(card) return card.size <= (9-player:field_size()) end)[1]
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  local slot = player:first_empty_field_slot()
  if hand_idx and slot then
    local amt = player.hand[hand_idx].size
    player:hand_to_field(hand_idx)
    if target then
      OneBuff(opponent, target, {atk={"-",amt},sta={"-",amt}}):apply()
    end
  end
end,

-- Defender
[110097] = function(player, opponent, my_card)
  OneBuff(player, 0, {life={"-",1}}):apply()
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, {atk={"+",2},def={"+",2},sta={"+",2}}):apply()
  end
end,

-- Child Gart
[110098] = function(player, opponent, my_card)
  if #player:field_idxs_with_preds(pred.A) + #player:hand_idxs_with_preds(pred.A) == 0 then
    local target = uniformly(player:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(player, target, {atk={"+",2},sta={"+",1}}):apply()
    end
  end
end,

-- Child Laevateinn
[110099] = function(player, opponent, my_card)
  local size_to_n = {}
  for i=1,#player.hand do
    local sz = player.hand[i].size
    size_to_n[sz] = (size_to_n[sz] or 0) + 1
  end
  local size = -1
  for k,v in pairs(size_to_n) do
    if v >= 2 and k > size then
      size = k
    end
  end
  if size > 0 then
    for i=5,1,-1 do
      if player.hand[i] and player.hand[i].size == size then
        player:hand_to_bottom_deck(i)
      end
    end
    OneBuff(player, 0, {life={"+",min(4,ceil(size/2))}}):apply()
  end
end,

-- Child Sigma
[110100] = function(player, opponent, my_card)
  if player.hand[1] then
    local amt = min(4,floor(player.hand[1].size/2))
    player:hand_to_bottom_deck(1)
    local target = uniformly(player:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(player, target, {atk={"+",amt},sta={"+",amt}}):apply()
    end
  end
end,

-- Embracing Shaman
[110101] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, {atk={"+",2},def={"+",2},sta={"+",2}}):apply()
  end
end,

-- Sleep Club Advisor
[110102] = function(player)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(player, idx, {atk={"+", 1}, sta={"+", 1}}):apply()
    player.field[idx].active = false
  end
end,

-- Angry Lady
[110103] = function(player, opponent)
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if not idx then
    return
  end
  local mag = opponent.field[idx].def
  OneBuff(opponent, idx, {atk={"-", mag}, sta={"-", mag}}):apply()
end,

-- Geography Teacher
[110104] = function(player, opponent)
  if opponent.field[3] then
    opponent:field_to_grave(3)
  end
end,

-- Cook Club Advisor
[110105] = function(player)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(player, idx, {size={"+", 1}, atk={"+", 1}, def={"+", 1}, sta={"+", 2}}):apply()
  end
end,

-- Health Teacher
[110106] = function(player)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(player, idx, {sta={"+", 4}}):apply()
  end
end,

-- Night Teacher
[110107] = function(player, opponent)
  local idx1 = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if not idx1 then
    return
  end
  local idx2 = nil
  for i=1,5 do
    if not opponent.field[(idx1 - 1 + i) % 5 + 1] then
      idx2 = (idx1 - 1 + i) % 5 + 1
      break
    end
  end
  if not idx2 then
    return
  end
  opponent.field[idx1], opponent.field[idx2] = nil, opponent.field[idx1]
  OneBuff(opponent, idx2, {sta={"-", idx2}}):apply()
end,

-- Lady Philia
[110108] = function(player, opponent)
  for i=1,2 do
    local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if not idx then
      return
    end
    local mag = opponent.field[idx].def
    OneBuff(opponent, idx, {atk={"-", mag}, sta={"-", mag}}):apply()
  end
end,

-- Hannah Pathfinder
[110109] = function(player, opponent)
  if opponent.field[2] then
    opponent:field_to_grave(2)
  end
end,

-- Anyte Annus
[110110] = function(player)
  local targets = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i=1,min(2,#targets) do
    buff[targets[i]] = {size={"+", 1}, atk={"+", 1}, def={"+", 1}, sta={"+", 2}}
  end
  buff:apply()
end,

-- Dispatched Teacher Riano
[110111] = function(player)
  for i=1,2 do
    local idx = uniformly(player:field_idxs_with_preds(pred.follower))
    if idx then
      OneBuff(player, idx, {sta={"+", 4}}):apply()
    end
  end
end,

-- Rui Flett
[110112] = function(player)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(player, idx, {atk={"+", 3}, sta={"+", 3}}):apply()
    player.field[idx].active = false
  end
end,

-- Night Teacher Rui
[110113] = function(player, opponent)
  local idx1 = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if not idx1 then
    return
  end
  local idx2 = nil
  for i=idx1+1,5 do
    if not opponent.field[i] then
      idx2 = i
      break
    end
  end
  if not idx2 then
    return
  end
  opponent.field[idx1], opponent.field[idx2] = nil, opponent.field[idx1]
  OneBuff(opponent, idx2, {atk={"-", idx2}, sta={"-", idx2}}):apply()
end,

-- Sita Vilosa
[110114] = function(player, opponent)
  local buff = OnePlayerBuff(opponent)
  for i=2,4 do
    if opponent.field[i] and pred.follower(opponent.field[i]) then
      buff[i] = {sta={"-", 2}}
    end
  end
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    if idx > 1 and idx < 5 then
      buff[idx] = {sta={"-", 4}}
    else
      buff[idx] = {sta={"-", 2}}
    end
  end
  buff:apply()
end,

-- Cinia Pacifica
[110115] = function(player, opponent)
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if not idx then
    return
  end
  if opponent.field[idx].def <= 0 then
    OneBuff(opponent, idx, {atk={"-", 2}, sta={"-", 2}}):apply()
  else
    OneBuff(opponent, idx, {def={"-", 1}, sta={"-", 2}}):apply()
  end
end,

-- Luthica Preventer
[110116] = function(player)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if not idx then
    return
  end
  if player.field[idx].def >= 1 then
    OneBuff(player, idx, {atk={"+", 2}, sta={"+", 2}}):apply()
  else
    OneBuff(player, idx, {def={"+", 1}, sta={"+", 2}}):apply()
  end
end,

-- Iri Flina
[110117] = function(player, opponent)
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if not idx then
    return
  end
  if opponent.field[idx].sta >= 10 then
    OneBuff(opponent, idx, {sta={"-", 5}}):apply()
  else
    OneBuff(opponent, idx, {atk={"-", 1}, def={"-", 1}, sta={"-", 2}}):apply()
  end
end,

-- Treanna
[110118] = function(player, opponent)
  local idxs = opponent:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(idxs) do
    for i=1,3 do
      opponent.field[idx]:remove_skill(i)
    end
  end
end,

-- Panica
[110119] = function(player, opponent)
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if not idx then
    return
  end
  local card = opponent.field[idx]
  OneBuff(opponent, idx, {atk={"=", ceil(card.atk / 2)}, sta={"=", ceil(card.sta / 2)}}):apply()
end,

-- Sigma
[110120] = function(player)
  if not player.hand[1] then
    return
  end
  local mag = min(player.hand[1].size, 5)
  player:hand_to_bottom_deck(1)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(player, idx, {atk={"+", mag}, sta={"+", mag}}):apply()
  end
end,

-- Aka Flina
[110121] = function(player, opponent)
  local mag = min(ceil(abs(player.character.life - opponent.character.life)), 5)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(player, idx, {atk={"+", mag}, sta={"+", mag}}):apply()
  end
end,

-- 3rd Witness DTD
[110122] = function(player, opponent)
  local idxs = opponent:field_idxs_with_preds()
  for _,idx in ipairs(idxs) do
    opponent:field_to_bottom_deck(idx)
  end
end,

-- World Destroyer DTD
[110123] = function(player, opponent)
  local mag = #opponent.hand
  for i=1,#opponent.hand do
    opponent:hand_to_bottom_deck(1)
  end
  local idxs = opponent:field_idxs_with_preds()
  mag = mag + #idxs
  for _,idx in ipairs(idxs) do
    opponent:field_to_bottom_deck(idx)
  end
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(player, idx, {atk={"+", mag}, sta={"+", mag}}):apply()
  end
end,

-- Winged Seeker
[110124] = function(player, opponent)
  local buff = OnePlayerBuff(opponent)
  for i=1,5 do
    local card = opponent.field[i]
    if card and pred.follower(card) and card.size % 2 == i % 2 then
      buff[i] = {atk={"-", 1}, sta={"-", 1}}
    end
  end
  buff:apply()
end,

-- Nytitch
[110125] = function(player, opponent)
  local buff = GlobalBuff(player)
  buff.field[opponent][0] = {life={"-", 2}}
  buff.field[player][0] = {life={"-", 1}}
  buff:apply()
end,

-- Tactician Ellie
[110126] = function(player, opponent)
  local idx = uniformly(opponent:hand_idxs_with_preds(pred.follower))
  if not idx then
    return
  end
  local card = opponent:remove_from_hand(idx)
  player:to_bottom_deck(card)
end,

-- Master Cleaning Maid
[110127] = function(player, opponent)
  local cards = {}
  local roll = math.random(1, 2)
  local targ = roll == 1 and player or opponent
  for i=1,2 do
    if opponent.hand[1] and targ:first_empty_field_slot() then
      local card = opponent:remove_from_hand(1)
      targ.field[targ:first_empty_field_slot()] = card
    end
  end
end,

-- Scardel Pinot Noir
[110128] = function(player, opponent)
  local idx = player:field_idxs_with_preds(pred.follower)[1]
  if not idx then
    return
  end
  local mag = player.field[idx].size
  idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(opponent, idx, {sta={"-", mag}}):apply()
  end
end,

-- Night Teacher
[110129] = function(player, opponent)
  local idx1 = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if not idx1 then
    return
  end
  local idx2 = nil
  for i=1,5 do
    if not opponent.field[(idx1 - 1 + i) % 5 + 1] then
      idx2 = (idx1 - 1 + i) % 5 + 1
      break
    end
  end
  if not idx2 then
    return
  end
  opponent.field[idx1], opponent.field[idx2] = nil, opponent.field[idx1]
  OneBuff(opponent, idx2, {sta={"-", idx2}}):apply()
end,

-- Kana. DTD
[110130] = function(player, opponent)
  local idxs = opponent:field_idxs_with_preds()
  for _,idx in ipairs(idxs) do
    opponent:field_to_bottom_deck(idx)
  end
end,

-- Mop Maid
[110131] = function(player)
  local buff = OnePlayerBuff(player)
  for i=1,5 do
    local card = player.field[i]
    local card1 = player.field[i - 1]
    local card2 = player.field[i + 1]
    if card and pred.follower(card) then
      if (card1 and pred.follower(card1)) or (card2 and pred.follower(card2)) then
        buff[i] = {atk={"+", 2}}
      end
    end
  end
  buff:apply()
end,

-- Embracing Shaman
[110132] = function(player)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(player, idx, {atk={"+", 2}, def={"+", 2}, sta={"+", 2}}):apply()
  end
end,

-- rio
[110133] = function(player, opponent, my_card)
  buff_all(player, opponent, my_card, {atk={"+",3},sta={"+",3}})
  recycle_one(player)
end,

-- nanai
[110134] = function(player)
  local amt, opponent = 0, player.opponent
  for i=1,5 do
    while opponent.hand[i] and pred.spell(opponent.hand[i]) do
      opponent:hand_to_grave(i)
      amt = amt + 2
    end
  end
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(opponent:field_idxs_with_preds(pred.follower)) do
    buff[idx] = {atk={"-",amt},sta={"-",amt}}
  end
  buff:apply()
  recycle_one(player)
end,

-- seven
[110135] = function(player)
  local buff = OnePlayerBuff(player.opponent)
  for _,idx in ipairs(player.opponent:field_idxs_with_preds(pred.follower)) do
    local card = player.opponent.field[idx]
    buff[idx] = {atk={"+",card.sta-1},sta={"=",1}}
  end
  buff:apply()
  recycle_one(player)
end,

-- new knight
[110136] = function(player)
  local buff = GlobalBuff(player)
  for _,idx in ipairs(player.opponent:field_idxs_with_preds(pred.follower)) do
    buff.field[player.opponent][idx] = {def={"-",2}}
  end
  for _,idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
    buff.field[player][idx] = {def={"+",2}}
  end
  for _,idx in ipairs(player:hand_idxs_with_preds(pred.follower)) do
    buff.hand[player][idx] = {def={"+",2}}
  end
  buff:apply()
  recycle_one(player)
end,

-- origin disciple
[110137] = function(player)
  OneBuff(player, 0, {life={"+",8}}):apply()
end,

-- sion flina
[110138] = function(player)
  if #player.opponent:field_idxs_with_preds(pred.rion) > 0 then
    OneBuff(player, 0, {life={"-",7}}):apply()
  end
  recycle_one(player)
end,

-- rion flina
[110139] = function(player)
  local targets = player.opponent:field_idxs_with_preds(pred.follower, pred.neg(pred.shion))
  local buff = OnePlayerBuff(player.opponent)
  for _,idx in ipairs(targets) do
    buff[idx] = {atk={"-",2},def={"-",2},sta={"-",2}}
  end
  buff:apply()
  if #player.opponent:field_idxs_with_preds(pred.shion) > 0 then
    OneBuff(player, 0, {life={"-",7}}):apply()
  end
  recycle_one(player)
  recycle_one(player)
end,

-- frett
[110140] = function(player)
  local idxs = player.opponent:field_idxs_with_preds(function(card) return card.size ~= 3 end)
  for _,idx in ipairs(idxs) do
    player.opponent:destroy(idx)
  end
  recycle_one(player)
end,

-- odien
[110141] = function(player)
  local idxs = player.opponent:field_idxs_with_preds(pred.follower, pred.skill)
  for _,idx in ipairs(idxs) do
    player.opponent:destroy(idx)
  end
  recycle_one(player)
end,

-- lyrica
[110142] = function(player)
  local idxs = player.opponent:field_idxs_with_preds(pred.follower, pred.neg(pred.skill))
  for _,idx in ipairs(idxs) do
    player.opponent:destroy(idx)
  end
  recycle_one(player)
end,

-- Apostle Six
[110143] = function(player)
  local idx = player:grave_idxs_with_preds(pred.aletheian)[1]
  if idx and player:first_empty_field_slot() then
    player:grave_to_field(idx)
  end
end,

-- Apostle Isena
[110144] = function(player, opponent)
  local p_idx = player:first_empty_field_slot()
  if not p_idx then
    return
  end
  local o_idx = uniformly(opponent:field_idxs_with_preds(pred.follower,
    function(card) return card.size <= 3 end))
  if not o_idx then
    return
  end
  player.field[p_idx], opponent.field[o_idx] = opponent.field[o_idx], nil
  player.field[p_idx]:gain_skill(1235)
  player.field[p_idx].active = false
end,

-- Apostle Yula
[110145] = function(player, opponent)
  local idxs = opponent:field_idxs_with_preds(pred.follower)
  local idx = uniformly(idxs)
  local mag = #idxs
  if not idx then
    return
  end
  OneBuff(opponent, idx, {sta={"-", mag}}):apply()
end,

-- Informant Six
[110146] = function(player)
  local idx1 = player:grave_idxs_with_preds(pred.follower, pred.aletheian)[1]
  local idx2 = player:first_empty_field_slot()
  if idx1 and idx2 then
    player:grave_to_field(idx1)
    OneBuff(player, idx2, {atk={"+", 3}, sta={"+", 3}}):apply()
  end
end,

-- Obsessed Isena
[110147] = function(player, opponent)
  local p_idx = player:first_empty_field_slot()
  if p_idx then
    local o_idx = uniformly(opponent:field_idxs_with_preds(pred.follower,
      function(card) return card.size <= 3 end))
    if o_idx then
      player.field[p_idx], opponent.field[o_idx] = opponent.field[o_idx], nil
      player.field[p_idx]:gain_skill(1235)
      player.field[p_idx].active = false
    end
  end
  local o_idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if o_idx then
    OneBuff(opponent, o_idx, {atk={"-", 2}, sta={"-", 2}}):apply()
  end
end,

-- Wealthy Yula
[110148] = function(player, opponent)
  for i=1,3 do
    local idxs = opponent:field_idxs_with_preds(pred.follower)
    local idx = uniformly(idxs)
    local mag = #idxs
    if not idx then
      return
    end
    OneBuff(opponent, idx, {sta={"-", mag}}):apply()
  end
end,

-- sarah
[110149] = function(player, opponent, my_card)
  local targets = {}
  for i=1,5 do
    if opponent.field[i] and pred.follower(opponent.field[i]) and
        ((opponent.field[i-1] and pred.follower(opponent.field[i-1])) or
          (opponent.field[i+1] and pred.follower(opponent.field[i+1])) or
          opponent.field[i].sta == 1) then
      targets[#targets+1] = i
    end
  end
  for _,idx in ipairs(targets) do
    opponent:destroy(idx)
  end
  recycle_one(player)
end,

-- gart
[110150] = function(player, opponent, my_card)
  if player.game.turn == 14 then
    OneBuff(opponent, 0, {life={"=",0}}):apply()
  end
  recycle_one(player)
end,

-- knight messenger
[110151] = function(player, opponent, my_card)
  while #player.grave > 0 do
    recycle_one(player)
  end
end,

-- gs 1st star
[110152] = function(player, opponent, my_card)
  local targets = opponent:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(targets) do
    buff[idx] = {sta={"-",1}}
  end
  buff:apply()
  targets = opponent:field_idxs_with_preds(pred.follower, pred.skill)
  for _,idx in ipairs(targets) do
    opponent.field[idx].skills = {1237}
  end
  recycle_one(player)
end,

-- kana dtd
[110153] = function(player, opponent, my_card)
  OneBuff(player, 0, {life={"+",4}}):apply()
  while #player.grave > 0 do
    recycle_one(player)
  end
  while #player.hand > 0 do
    player:hand_to_top_deck(#player.hand)
  end
end,

-- lotte
[110154] = function(player, opponent, my_card)
  if player.game.turn > 1 then
    if #player:field_idxs_with_preds() == 0 then
      OneBuff(opponent, 0, {life={"-",10}}):apply()
    end
  end
end,

-- conundrum
[110155] = function(player, opponent, my_card)
  if player.character.life <= 7 then
    OneBuff(opponent, 0, {life={"=",0}}):apply()
  end
end,

-- knight vanguard
[110156] = function(player, opponent, my_card)
  if player.game.turn > 1 then
    local amt = 5-#opponent.hand
    OneBuff(opponent, 0, {life={"-",3*amt}}):apply()
  end
end,

-- serie
[110157] = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    opponent.field[target].active = false
  end
  local buff = OnePlayerBuff(player)
  local targets = player:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(targets) do
    local amt = 2*abs(player.field[idx].def)
    buff[idx] = {atk={"+",amt},def={"+",amt},sta={"+",amt}}
  end
  buff:apply()
  recycle_one(player)
end,

-- envy lady
[110158] = function(player, opponent, my_card)
  local buff = GlobalBuff(player)
  local targets = opponent:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(targets) do
    local card = opponent.field[idx]
    buff.field[opponent][idx] = {}
    for _,stat in ipairs({"atk","def","sta"}) do
      if card[stat] > id_to_canonical_card[card.id][stat] then
        buff.field[opponent][idx][stat] = {"=",id_to_canonical_card[card.id][stat]}
      end
    end
  end
  targets = player:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(targets) do
    local card = player.field[idx]
    buff.field[player][idx] = {}
    for _,stat in ipairs({"atk","def","sta"}) do
      if card[stat] < id_to_canonical_card[card.id][stat] then
        buff.field[player][idx][stat] = {"=",id_to_canonical_card[card.id][stat]}
      end
    end
  end
  buff:apply()
  recycle_one(player)
end,

-- sleeping club president
[110159] = function(player, opponent, my_card)
  if #player.hand > 0 and #opponent.hand > 0 then
    player.hand[1], opponent.hand[1] = opponent.hand[1], player.hand[1]
  end
end,

-- fourteen
[110160] = function(player, opponent, my_card)
  for i=1,3 do
    if #opponent.deck > 0 then
      opponent:deck_to_grave(#opponent.deck)
    end
  end
  recycle_one(player)
end,

-- maid luna
[110161] = function(player, opponent, my_card)
  local my_idx = uniformly(player:field_idxs_with_preds(pred.follower))
  local op_idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  local buff = GlobalBuff(player)
  if my_idx then
    local amt = #player.grave
    buff.field[player][my_idx] = {atk={"+",amt},sta={"+",amt}}
  end
  if op_idx then
    local amt = #opponent.grave
    buff.field[opponent][op_idx] = {atk={"-",amt},sta={"-",amt}}
  end
  buff:apply()
end,

-- youngest knight
[110162] = function(player, opponent, my_card)
  local targets = opponent:field_idxs_with_preds(
      function(card) return card.size <= 5 end)
  for _,idx in ipairs(targets) do
    opponent:field_to_grave(idx)
  end
end,

-- chirushi
[110163] = function(player, opponent, my_card)
  local func = function(card) return card.id == 200035 end
  for i=1,3 do
    if player:first_empty_field_slot() then
      local hand_idx = player:hand_idxs_with_preds(func)[1]
      if hand_idx then
        player:hand_to_field(hand_idx)
      else
        local deck_idx = player:deck_idxs_with_preds(func)[1]
        if deck_idx then
          player:deck_to_field(deck_idx)
        end
      end
    end
  end
end,

-- ragafelt
[110164] = function(player, opponent, my_card)
  local buff = GlobalBuff(player)
  local targets = opponent:deck_idxs_with_preds(pred.follower)
  for _,idx in ipairs(targets) do
    buff.deck[opponent][idx] = {atk={"-",2},def={"-",2},sta={"-",2}}
  end
  buff:apply()
  local to_top = {}
  for i=1,5 do
    local idx = uniformly(opponent:deck_idxs_with_preds(pred.follower))
    if idx then
      to_top[i] = table.remove(opponent.deck, idx)
    end
  end
  for i=1,#to_top do
    opponent.deck[#opponent.deck + 1] = to_top[i]
  end
end,

-- winfield
[110165] = function(player, opponent, my_card)
  local op_cards = opponent:field_idxs_with_preds()
  for _,idx in ipairs(op_cards) do
    opponent.field[idx].active = false
  end
  local buff = OnePlayerBuff(player)
  local targets = player:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(targets) do
    local amt = 5*player.field[idx].def
    buff[idx] = {atk={"+",amt},sta={"+",amt}}
  end
  buff:apply()
  for i=1,3 do
    local target = opponent:hand_idxs_with_preds(pred.spell)[i]
    if target then
      opponent:hand_to_grave(target)
    end
  end
end,

-- kris flina
[110166] = function(player, opponent, my_card)
  local my_slot = player:first_empty_field_slot()
  local op_slot = opponent:first_empty_field_slot()
  local buff = GlobalBuff(player)
  if my_slot then
    player.field[my_slot] = Card(300055)
    buff.field[player][my_slot] = {atk={"=",13},def={"=",2},sta={"=",13}}
  end
  if op_slot then
    opponent.field[op_slot] = Card(300055)
    buff.field[opponent][op_slot] = {size={"=",9},atk={"=",4},def={"=",2},sta={"=",4}}
    opponent.field[op_slot]:gain_skill(1272)
  end
  buff:apply()
end,

-- Natura
[110167] = function(player, opponent)
  local idx = uniformly(opponent:hand_idxs_with_preds(pred.follower))
  if idx then
    local buff = GlobalBuff(opponent)
    buff.hand[opponent][idx] = {atk={"-", 2}, sta={"-", 2}}
    buff:apply()
  end
end,

-- Ignis
[110168] = function(player, opponent)
  if player.game.turn % 2 == 0 then
    OneBuff(player, 0, {life={"+", 2}}):apply()
  else
    local buff = GlobalBuff(player)
    buff.field[player][0] = {life={"-", 2}}
    buff.field[opponent][0] = {life={"-", 2}}
    buff:apply()
  end
end,

-- Cherum
[110169] = function(player, opponent)
  local idxs = opponent:field_idxs_with_preds(pred.follower)
  local mag = #opponent:empty_field_slots() - 1
  if mag <= 0 then return end
  local buff = OnePlayerBuff(opponent)
  for i=1,#idxs do
    buff[idxs[i]] = {sta={"-", mag}}
  end
  buff:apply()
end,

-- Axis Wing Natura
[110170] = function(player, opponent)
  for i=1,2 do
    local idx = uniformly(opponent:hand_idxs_with_preds(pred.follower))
    if idx then
      local buff = GlobalBuff(opponent)
      buff.hand[opponent][idx] = {atk={"-", 2}, sta={"-", 2}}
      buff:apply()
    end
  end
end,

-- Axis Wing Ignis
[110171] = function(player, opponent)
  if player.game.turn % 2 == 0 then
    OneBuff(player, 0, {life={"+", 2}}):apply()
  else
    OneBuff(opponent, 0, {life={"-", 2}}):apply()
  end
end,

-- Axis Wing Cherum
[110172] = function(player, opponent)
  local idxs = opponent:field_idxs_with_preds(pred.follower)
  if not idxs then
    return
  end
  local mag = #opponent:empty_field_slots() - 1
  if mag <= 0 then return end
  local buff = OnePlayerBuff(opponent)
  for i=1,#idxs do
    buff[idxs[i]] = {atk={"-", mag}, sta={"-", mag}}
  end
  buff:apply()
end,

-- amethystar
[110173] = function(player, opponent, my_card)
  local which = random(1,5)
  if which == 1 then
    local targets = opponent:field_idxs_with_preds(pred.follower)
    local buff = OnePlayerBuff(opponent)
    for _,idx in ipairs(targets) do
      buff[idx] = {atk={"-",3},sta={"-",3}}
    end
    buff:apply()
  elseif which == 2 then
    local targets = player:field_idxs_with_preds(pred.follower)
    local buff = OnePlayerBuff(player)
    for _,idx in ipairs(targets) do
      buff[idx] = {atk={"+",3},sta={"+",3}}
    end
    buff:apply()
  elseif which == 3 then
    OneBuff(opponent, 0, {life={"-",2}}):apply()
  elseif which == 4 then
    OneBuff(player, 0, {life={"+",2}}):apply()
  else
    while #player.grave > 0 do
      recycle_one(player)
    end
  end
end,

-- zislana
[110174] = function(player, opponent, my_card)
  while #player.grave > 0 do
    recycle_one(player)
  end
end,

-- magician
[110175] = function(player, opponent, my_card)
  if opponent.field[player.game.turn] then
    OneBuff(opponent, 0, {life={"-",8}}):apply()
  end
  if player.game.turn == 5 then
    player.game.turn = 1
  end
  while #player.grave > 0 do
    recycle_one(player)
  end
end,

-- jaina preventer
[110176] = function(player, opponent, my_card)
  local func = function(card)
    local base = Card(card.id)
    return card.atk > base.atk or card.def > base.def or card.sta > base.sta
  end
  local targets = opponent:field_idxs_with_preds(pred.follower, func)
  for _,idx in ipairs(targets) do
    opponent:destroy(idx)
  end
  while #player.grave > 0 do
    recycle_one(player)
  end
end,

-- disciple johana
[110177] = function(player, opponent, my_card)
  local amt = #opponent.hand
  while #opponent.hand > 0 do
    opponent:hand_to_grave(1)
  end
  local buff = GlobalBuff(player)
  buff.field[player][0] = {life={"+",amt}}
  buff.field[opponent][0] = {life={"-",amt}}
  buff:apply()
  while #player.grave > 0 do
    recycle_one(player)
  end
end,

-- disciple josefina
[110178] = function(player, opponent, my_card)
  local my_guys = player:field_idxs_with_preds(pred.follower)
  local op_guys = opponent:field_idxs_with_preds(pred.follower)
  if #op_guys > #my_guys then
    for _,idx in ipairs(op_guys) do
      local slot = player:first_empty_field_slot()
      if slot then
        player.field[slot] = opponent.field[idx]
        opponent.field[idx] = nil
        player.field[slot].size = 1
      end
    end
  end
  if player:field_size() >= 2 then
    local to_send = player:field_idxs_with_preds(pred.follower,
        function(card) return card.size > 1 end)
    for _,idx in ipairs(to_send) do
      local slot = opponent:first_empty_field_slot()
      if slot then
        opponent.field[slot] = player.field[idx]
        player.field[idx] = nil
        opponent.field[slot].size = 5
      end
    end
  end
  while #player.grave > 0 do
    recycle_one(player)
  end
end,

-- fool
[110179] = function(player, opponent, my_card)
  local to_steal = uniformly(opponent:field_idxs_with_preds(pred.neg(pred.knight)))
  if to_steal and player:first_empty_field_slot() then
    local card = opponent.field[to_steal]
    card.size = 1
    opponent.field[to_steal] = nil
    player.field[player:first_empty_field_slot()] = card
  end
  local to_grave = opponent:field_idxs_with_preds(pred.neg(pred.knight))
  for _,idx in ipairs(to_grave) do
    opponent:field_to_grave(idx)
  end
  while #player.grave > 0 do
    recycle_one(player)
  end
end,

-- chenin blanc
[110180] = function(player, opponent, my_card)
  OneBuff(opponent, 0, {life={"=",10}}):apply()
  for _,p in ipairs({player, opponent}) do
    for i=1,5 do
      p.field[i] = Card(200035)
    end
  end
end,

-- famed disciple
[110182] = function(player, opponent, my_card)
  local even = opponent:field_idxs_with_preds(
      function(card) return card.size % 2 == 0 end)
  for _,idx in ipairs(even) do
    opponent:destroy(idx)
  end
  local targets = opponent:field_idxs_with_preds()
  for _,idx in ipairs(targets) do
    opponent.field[idx].size = 4
  end
  for i=1,#opponent.hand do
    opponent.hand[i].size = 4
  end
end,

-- disciple shuru
[110183] = function(player, opponent, my_card)
  if player.game.turn == 1 then
    local decks = {V="http://swogitools.com/index.php?deck=100001D2P300007C3P300005C2P300006C3P300004C2P300008C3P300003C3P300002C3P300001C2P200003C2P200002C2P200005C1P200001C2P200004C&compression=false",
        A="http://swogitools.com/index.php?deck=100002D2P300025C3P300023C2P300024C3P300022C2P300026C3P300021C3P300020C3P300019C2P200012C2P200011C2P200015C1P200014C2P200013C&compression=false",
        C="http://swogitools.com/index.php?deck=100003D2P300043C3P300041C2P300042C3P300040C2P300044C3P300039C3P300038C3P300037C2P200022C1P200021C2P200025C2P200023C2P200024C&compression=false",
        D="http://swogitools.com/index.php?deck=100004D3P300061C3P300059C2P300060C2P300058C3P300062C2P300057C3P300056C3P300055C1P200035C2P200033C2P200032C2P200034C2P200031C&compression=false"}
    local deck_str = decks[opponent.character.faction]
    if deck_str then
      local deck = str_to_deck(deck_str)
      table.remove(deck, 1)
      deck = map(Card, deck)
      opponent.deck = shuffle(deck)
    else
      opponent.deck = {}
    end
  end
end,

-- SS Clerk
[110184] = function(player, opponent)
  if player.game.turn ~= 1 then
    return
  end
  local buff = GlobalBuff(player)
  player.deck = {}
  for idx = 1, #opponent.deck do
    player.deck[idx] = deepcpy(opponent.deck[idx])
    if pred.follower(player.deck[idx]) then
      buff.deck[player][idx] = {atk={"-", 1}, sta={"-", 1}}
    end
  end
  buff:apply()
end,

-- SS Intimidator
[110185] = function(player, opponent)
  local my_count = 0
  local op_count = 0
  for idx = 1, 5 do
    if player.hand[idx] then
      my_count = my_count + player.hand[idx].size
    end
    if opponent.hand[idx] then
      op_count = op_count + opponent.hand[idx].size
    end
  end
  local check = my_count % 2 == op_count % 2
  if check then
    OneBuff(player, 0, {life={"+", 1}}):apply()
  else
    OneBuff(opponent, 0, {life={"-", 2}}):apply()
  end
end,

-- SS Twenty
[110186] = function(player, opponent)
  if not (player.character.life > opponent.character.life) then
    return
  end
  local buff = GlobalBuff(player)
  buff.field[player][0] = {life={"=", opponent.character.life}}
  buff.field[opponent][0] = {life={"=", player.character.life}}
  buff:apply()
end,

-- SS Spy
[110187] = function(player, opponent)
  while opponent.hand[4] do
    opponent:hand_to_grave(4)
  end
end,

-- SS Agent
[110188] = function()
end,

-- SS Clerk Jasmine
[110189] = function(player, opponent)
  if player.game.turn ~= 1 then
    return
  end
  player.deck = {}
  for idx = 1, #opponent.deck do
    player.deck[idx] = deepcpy(opponent.deck[idx])
  end
end,

-- SS Casey
[110190] = function(player, opponent)
  local my_count = 0
  local op_count = 0
  for idx = 1, 5 do
    if player.hand[idx] then
      my_count = my_count + player.hand[idx].size
    end
    if opponent.hand[idx] then
      op_count = op_count + opponent.hand[idx].size
    end
  end
  local check = my_count % 2 == op_count % 2
  if check then
    OneBuff(player, 0, {life={"+", 2}}):apply()
  else
    OneBuff(opponent, 0, {life={"-", 3}}):apply()
  end
end,

-- SS Infiltrator Twenty
[110191] = function(player, opponent)
  local buff = GlobalBuff(player)
  buff.field[player][0] = {life={"=", opponent.character.life}}
  buff.field[opponent][0] = {life={"=", player.character.life}}
  buff:apply()
end,

-- SS Spy Forty
[110192] = function(player, opponent)
  while opponent.hand[3] do
    opponent:hand_to_grave(3)
  end
end,

-- SS Agent Ice
[110193] = function()
end,

-- Examiner Margaret
[110194] = function(player)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(player, idx, {atk={"+", 1}}):apply()
  end
end,

-- Examiner Coy
[110195] = function(player, opponent)
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(opponent, idx, {sta={"-", 1}}):apply()
  end
end,

-- Examiner Iris
[110196] = function(player)
  OneBuff(player, 0, {life={"+", 1}}):apply()
end,

-- Examiner R. Margaret
[110197] = function(player)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i = 1, 2 do
    if idxs[i] then
      buff[idxs[i]] = {atk={"+", 1}}
    end
  end
  buff:apply()
end,    

-- Examiner P. Coy
[110198] = function(player, opponent)
  local idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(opponent)
  for i = 1, 2 do
    if idxs[i] then
      buff[idxs[i]] = {atk={"-", 1}}
    end
  end
  buff:apply()
end,

-- Examiner G. Iris
[110199] = function(player, opponent)
  local buff = GlobalBuff(player)
  buff.field[player][0] = {life={"+", 1}}
  buff.field[opponent][0] = {life={"-", 1}}
  buff:apply()
end,

-- Henlifei
[110200] = function(player, opponent)
  local my_idx = uniformly(player:field_idxs_with_preds(pred.follower))
  local op_idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  local buff = GlobalBuff(player)
  if my_idx then
    buff.field[player][my_idx] = {atk={"+", 1}, sta={"+", 1}}
  end
  if op_idx then
    buff.field[opponent][op_idx] = {atk={"+", 1}, sta={"+", 1}}
  end
  buff:apply()
end,

-- Gold Lion Nold
[120001] = function(player, opponent, my_card)
  buff_all(player, opponent, my_card, {size={"-",1}})
end,

-- Breeze Queen Cannelle
[120002] = function(player)
  local target_idxs = player:field_idxs_with_preds(pred.follower, function(card) return card.size <= 3 end)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {atk={"+",2},sta={"+",2}}
  end
  buff:apply()
end,

-- Star Bird Gart
[120003] = function(player, opponent)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    opponent.field[target].active = false
  end
end,

-- Twilight Wolf Ginger
[120004] = function(player, opponent, my_card)
  buff_all(player, opponent, my_card, {atk={"+",3}})
end,

-- Twin Flame Laevateinn
[120005] = function(player, opponent, my_card)
  if player.character.life <= 9 then
    OneBuff(player, 0, {life={"+",5}}):apply()
  end
end,

-- Tricksters Shion and Rion
[120006] = function(player, opponent, my_card)
  local idx = uniformly(player:grave_idxs_with_preds(pred.spell))
  if idx then
    player:grave_to_bottom_deck(idx)
  end
  local slots = player:empty_field_slots()
  local buff = OnePlayerBuff(player)
  if slots[1] then
    player.field[slots[1]] = Card(300057)
    buff[slots[1]] = {size={"-",1}}
  end
  if slots[2] then
    player.field[slots[2]] = Card(300058)
    buff[slots[2]] = {size={"-",1}}
  end
  buff:apply()
end,

-- Pegasus Sigma
[120007] = function(player, opponent, my_card)
  local hand_sz = #opponent.hand
  local targets = {}
  for i=1,5 do
    if opponent.field[i] and (i+hand_sz)%2==0 then
      targets[#targets+1] = i
    end
  end
  local target = uniformly(targets)
  if target then
    opponent:field_to_grave(target)
  end
  buff_all(player, opponent, my_card, {atk={"+",1},sta={"+",1}})
end,

-- Cinia's Pet Panica
[120008] = function(player, opponent, my_card)
  local stat = "atk"
  if player.game.turn % 2 == 0 then
    stat = "sta"
  end
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    local new_value = ceil(opponent.field[target][stat] / 2)
    OneBuff(opponent, target, {[stat]={"=",new_value}}):apply()
  end
end,

-- Artificial Vampire God
[120009] = function(player, opponent, my_card)
  recycle_one(player)
  if opponent.character.life <= 10 then
    OneBuff(opponent, 0, {life={"-",10}}):apply()
  end
end,

-- true vampire god
[120010] = function(player, opponent)
  recycle_one(player)
  if opponent.character.life >= 15 then
    OneBuff(opponent, 0, {life={"-",1}}):apply()
  elseif opponent.character.life <= 8 then
    OneBuff(opponent, 0, {life={"-",8}}):apply()
  end
end,

-- Nexia Shining Form
[120011] = function(player, opponent, my_card)
  recycle_one(player)
  buff_all(player, opponent, my_card, {atk={"+",3},sta={"+",3}})
end,

-- Vita Principal
[120012] = function(player, opponent)
  if player.grave[1] then
    player:grave_to_bottom_deck(#player.grave)
  end
  local idxs = opponent:field_idxs_with_preds(pred.follower)
  local mag = 0
  for _,idx in ipairs(idxs) do
    local card = opponent.field[idx]
    if card.skills[1] or card.skills[2] or card.skills[3] then
      mag = mag + 1
    end
    card.skills = {}
  end
  OneBuff(player, 0, {life={"+", mag}}):apply()
end,

-- The Melancholy of Vernika
[120013] = function(player, opponent)
  local idx = opponent:hand_idxs_with_preds(pred.spell)[1]
  while idx do
    opponent:hand_to_bottom_deck(idx)
    idx = opponent:hand_idxs_with_preds(pred.spell)[1]
  end
  -- bug is here
  if #player.grave > 0 then
    player:grave_to_bottom_deck(math.random(#player.grave))
  end
  -- bug is here
  if player.character.life > 5 then
    return
  end
  local buff = GlobalBuff(player)
  local mag = ceil((player.character.life + opponent.character.life) / 2)
  buff.field[player][0] = {life={"=", mag}}
  buff.field[opponent][0] = {life={"=", mag}}
  buff:apply()
  for i=1,5 do
    if player.field[i] then
      player:field_to_grave(i)
    end
    if opponent.field[i] then
      opponent:field_to_grave(i)
    end
  end
end,

-- Rio
[120014] = function(player, opponent)
  local buff = GlobalBuff(player)
  local idxs = player:hand_idxs_with_preds(pred.follower)
  for _,idx in ipairs(idxs) do
    buff.hand[player][idx] = {atk={"+", 2}, sta={"+", 2}}
  end
  buff:apply()
end,

-- ereshkigal
[120015] = function(player, opponent, my_card)
  if player.game.turn ~= 1 then
    local amt = 2*(5-#opponent.hand)
    OneBuff(opponent, 0, {life={"-",amt}}):apply()
  end

  local func = function(card)
    local base = Card(card.id)
    return card.atk > base.atk or card.def > base.def or card.sta > base.sta
  end
  local targets = opponent:field_idxs_with_preds(pred.follower, func)
  for _,idx in ipairs(targets) do
    opponent:field_to_bottom_deck(idx)
  end
end,

-- Apostle L Red Sun
[120016] = function(player)
  local idx1 = uniformly(player:grave_idxs_with_preds(pred.follower))
  local idx2 = player:first_empty_field_slot()
  if idx1 and idx2 then
    player:grave_to_field(idx1)
    OneBuff(player, idx2, {size={"=", 1}, atk={"+", 3}, sta={"+", 3}}):apply()
  end
  if #player.grave > 0 then
    idx1 = random(#player.grave)
    player:grave_to_bottom_deck(idx1)
  end
end,

-- Knight Captain Eisenwane
[120017] = function(player)
  while #player.grave > 0 do
      recycle_one(player)
    end
  local idxs = player:deck_idxs_with_preds(pred.follower)
  local buff = GlobalBuff(player)
  for i=1,#idxs do
    buff.deck[player][idxs[i]] = {atk={"+", 1}, sta={"+", 1}}
  end
  buff:apply()
end,

-- SS Pursuer Four
[120018] = function(player)
  local mag = player.game.turn == 10 and 0 or player.character.life <= 7 and 7 or -1
  if mag > -1 then
    OneBuff(player, 0, {life={"=", mag}}):apply()
  end
end,

-- Lightning Wolf Henlifei
[120019] = function(player, opponent)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(player, idx, {atk={"+", 1}, sta={"+", 2}}):apply()
  end
  idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(opponent, idx, {atk={"-", 1}, sta={"-", 2}}):apply()
  end
end,
  
-- Do not touch that curly brace!
}
setmetatable(characters_func, {__index = function()return function() end end})
