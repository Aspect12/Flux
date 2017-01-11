--[[ 
	Rework © 2016-2017 TeslaCloud Studios
	Do not share or re-distribute before 
	the framework is publicly released.
--]]

timer.Remove("HintSystem_OpeningMenu");
timer.Remove("HintSystem_Annoy1");
timer.Remove("HintSystem_Annoy2");

do
	local scrW, scrH = ScrW(), ScrH();

	-- This will let us detect whether the resolution has been changed, then call a hook if it has.
	function GM:Tick()
		local newW, newH = ScrW(), ScrH();

		if (scrW != newW or scrH != newH) then
			rw.core:Print("Resolution changed from "..scrW.."x"..scrH.." to "..newW.."x"..newH..".");

			plugin.Call("OnResolutionChanged", newW, newH, scrW, scrH);

			scrW, scrH = newW, newH;
		end;
	end;
end;

-- Called when the resolution has been changed and fonts need to be resized to fit the client's res.
function GM:OnResolutionChanged(oldW, oldH, newW, newH)
	rw.fonts:CreateFonts();
end;

-- Called when the client connects and spawns.
function GM:InitPostEntity()
	rw.client = rw.client or LocalPlayer();

	if (!rw.client:GetActiveCharacter()) then
		rw.IntroPanel = vgui.Create("rwIntro");
		rw.IntroPanel:MakePopup();
	end;

 	for k, v in ipairs(player.GetAll()) do
 		local model = v:GetModel();

 		plugin.Call("PlayerModelChanged", v, model, model);
 	end;
end;

function GM:RenderScreenspaceEffects()
	if (rw.client.colorModify) then
		DrawColorModify(rw.client.colorModifyTable);
	end;
end;

function GM:PlayerDropItem(itemTable, panel, mouseX, mouseY)
	netstream.Start("PlayerDropItem", itemTable.instanceID);
end;

function GM:HUDDrawScoreBoard() end;

-- Called when the scoreboard should be shown.
function GM:ScoreboardShow()
	if (rw.client:HasInitialized()) then
		if (rw.tabMenu and rw.tabMenu.CloseMenu) then
			rw.tabMenu:CloseMenu(true);
		end;

		rw.tabMenu = theme.CreatePanel("TabMenu", nil, "rwTabMenu");
		rw.tabMenu:MakePopup();
		rw.tabMenu.heldTime = CurTime() + 0.3;
	end;
end;

-- Called when the scoreboard should be hidden.
function GM:ScoreboardHide()
	if (rw.client:HasInitialized()) then
		if (rw.tabMenu and rw.tabMenu.heldTime and CurTime() >= rw.tabMenu.heldTime) then
			rw.tabMenu:CloseMenu();
		end;
	end;
end;

-- Called when category icons are presented.
function GM:AddTabMenuItems(menu)
	menu:AddMenuItem("!mainmenu", {
		title = "Main Menu",
		icon = "fa-users",
		override = function(menuPanel, button)
			menuPanel:SetVisible(false);
			menuPanel:Remove();
			rw.IntroPanel = theme.CreatePanel("MainMenu");
		end;
	});

	menu:AddMenuItem("!inventory", {
		title = "Inventory",
		panel = "reInventory",
		icon = "fa-inbox",
		callback = function(menuPanel, button)
			local inv = menuPanel.activePanel;
			inv:SetInventory(rw.client:GetInventory());
			inv:SetTitle("Inventory");
		end
	});

	menu:AddMenuItem("scoreboard", {
		title = "Scoreboard",
		panel = "rwScoreboard",
		icon = "fa-list-alt"
	});
end;

function GM:OnMenuPanelOpen(menuPanel, activePanel)
	activePanel:SetPos(ScrW() / 2 - activePanel:GetWide() / 2 + 64, 256);
end;

rw.bars:Register("health", {
	text = "HEALTH",
	color = Color(200, 40, 40),
	maxValue = 100
}, true);

rw.bars:Register("armor", {
	text = "armor",
	color = Color(80, 80, 220),
	maxValue = 100
}, true);

-- Called when the player's HUD is drawn.
function GM:HUDPaint()
	if (!IsValid(rw.IntroPanel)) then
		if (!plugin.Call("RWHUDPaint") and rw.settings:GetBool("DrawBars")) then
			rw.bars:SetValue("health", rw.client:Health());
			rw.bars:SetValue("armor", rw.client:Armor());
			rw.bars:DrawTopBars();

			self.BaseClass:HUDPaint();
		end;
	end;
end;

function GM:HUDDrawTargetID()
	if (IsValid(rw.client) and rw.client:Alive()) then
		local trace = rw.client:GetEyeTraceNoCursor();
		local ent = trace.Entity;

		if (IsValid(ent)) then
			local screenPos = (trace.HitPos + Vector(0, 0, 16)):ToScreen();
			local x, y = screenPos.x, screenPos.y;
			local distance = rw.client:GetPos():Distance(trace.HitPos);

			if (ent:IsPlayer()) then
				plugin.Call("DrawPlayerTargetID", ent, x, y, distance);
			elseif (ent.DrawTargetID) then
				ent:DrawTargetID(x, y, distance);
			end;
		end;
	end;
end;

function GM:DrawPlayerTargetID(player, x, y, distance)
	if (distance < 640) then
		local alpha = 255;

		if (distance > 500) then
			local d = distance - 500;
			alpha = math.Clamp((255 * (140 - d) / 140), 0, 255);
		end;

		local width, height = util.GetTextSize(player:Name(), "tooltip_large");
		draw.SimpleText(player:Name(), "tooltip_large", x - width * 0.5, y - 40, Color(255, 255, 255, alpha));

		local width, height = util.GetTextSize(player:GetPhysDesc(), "tooltip_small");
		draw.SimpleText(player:GetPhysDesc(), "tooltip_small", x - width * 0.5, y - 14, Color(255, 255, 255, alpha));
		
		if (distance < 125) then
			if (distance > 90) then
				local d = distance - 90;
				alpha = math.Clamp((255 * (35 - d) / 35), 0, 255);
			end;

			local smallerFont = rw.fonts:GetSize("tooltip_small", 12);
			local width, height = util.GetTextSize("#TargetID_Information", smallerFont);
			draw.SimpleText("#TargetID_Information", smallerFont, x - width * 0.5, y + 5, Color(50, 255, 50, alpha));
		end;
	end;
end;

do
	local hiddenElements = { -- Hide default HUD elements.
		CHudHealth = true,
		CHudBattery = true,
		CHudAmmo = true,
		CHudSecondaryAmmo = true,
		CHudCrosshair = true,
		CHudHistoryResource = true
	}

	function GM:HUDShouldDraw(element)
		if (hiddenElements[element]) then
			return false;
		end

		return true;
	end
end;