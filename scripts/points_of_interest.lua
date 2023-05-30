local fOnDoubleClick;

function onInit()
	fOnDoubleClick = TokenManager.onDoubleClick;
	TokenManager.onDoubleClick = POI.onDoubleClick;

	Token.addEventHandler("onDelete", POI.onTokenDelete);
end

function onTokenDelete(tokenMap)
	if not Session.IsHost then
		return;
	end

	local nodePoi = POI.getPoiFromToken(tokenMap)
	if nodePoi then
		DB.setValue(nodePoi, "tokenrefnode", "string", "");
		DB.setValue(nodePoi, "tokenrefid", "string", "");
	end
end

function onDoubleClick(tokenMap, vImage)
	local poinode = POI.getPoiFromToken(tokenMap)

	-- if the token clicked is not a point of interest
	-- then we treat it like any other token
	if not poinode then
		fOnDoubleClick();
		return true;
	end
	
	if Session.IsHost then
		local sClass, sRecord = DB.getValue(poinode, "link", "", "");
		if sRecord ~= "" then
			Interface.openWindow(sClass, sRecord);
		else
			Interface.openWindow(sClass, poinode);
		end
		return true;
	else
		local sClass, sRecord = DB.getValue(poinode, "link", "", "");
		local nodeEntry;

		-- Attempt to resolve the source node for the poi entry
		if sRecord ~= "" then
			nodeEntry = DB.findNode(sRecord);
		else
			nodeEntry = poinode;
		end

		if nodeEntry then
			Interface.openWindow(sClass, nodeEntry);
		else
			ChatManager.SystemMessage(Interface.getString("poi_error_openotherlinkedtokenwithoutaccess"));
		end
		vImage.clearSelectedTokens();
	end
end

function replacePoiToken(nodePoi, newTokenInstance)
	local oldTokenInstance = POI.getTokenFromPoi(nodePoi);
	if oldTokenInstance and oldTokenInstance ~= newTokenInstance then
		if not newTokenInstance then
			local nodeContainerOld = oldTokenInstance.getContainerNode();
			if nodeContainerOld then
				local x,y = oldTokenInstance.getPosition();
				newTokenInstance = Token.addToken(DB.getPath(nodeContainerOld), DB.getValue(nodePoi, "token", ""), x, y);
			end
		end
		-- New token's scale should match the old one
		local scale = oldTokenInstance.getScale();
		newTokenInstance.setScale(scale);

		oldTokenInstance.delete();
	end

	TokenManager.linkToken(nodePoi, newTokenInstance);
	POI.updateVisibility(nodePoi);
end

function getPoiFromToken(token)
	if not token then
		return nil;
	end

	local nodeContainer = token.getContainerNode();
	local nId = token.getId();
	local sContainerNode = DB.getPath(nodeContainer);
	
	for _,v in ipairs(DB.getChildList(nodeContainer, "..poi")) do
		local sPoiContainerName = DB.getValue(v, "tokenrefnode", "");
		local nPoiId = tonumber(DB.getValue(v, "tokenrefid", "")) or 0;
		if (sPoiContainerName == sContainerNode) and (nPoiId == nId) then
			return v;
		end
	end
	
	return nil;
end

function getTokenFromPoi(vEntry)
	local nodePoi = nil;
	if type(vEntry) == "string" then
		nodePoi = DB.findNode(vEntry);
	elseif type(vEntry) == "databasenode" then
		nodePoi = vEntry;
	end
	if not nodePoi then
		return nil;
	end
	
	return Token.getToken(DB.getValue(nodePoi, "tokenrefnode", ""), DB.getValue(nodePoi, "tokenrefid", ""));
end

function updateVisibility(nodePoi)
	local token = POI.getTokenFromPoi(nodePoi);
	if not token then
		return;
	end

	local bVis = POI.getTokenVisibilityFromPoi(nodePoi);

	if not bVis then
		token.setVisible(false);
		return;
	end

	if token.isVisible() ~= true then
		token.setVisible(nil);
	end
end

function getTokenVisibilityFromPoi(vEntry)
	local nodePoi = nil;
	if type(vEntry) == "string" then
		nodePoi = DB.findNode(vEntry);
	elseif type(vEntry) == "databasenode" then
		nodePoi = vEntry;
	end
	if not nodePoi then
		return true;
	end
	
	return (DB.getValue(nodePoi, "tokenvis", 0) == 1);
end

function openMap(nodePoi)
	if not nodePoi then 
		return; 
	end
	ImageManager.centerOnToken(getTokenFromPoi(nodePoi), true);
end