function onInit()
	DB.addHandler(DB.getPath(window.getDatabaseNode(), "poi.*"), "onDelete", onPoiDeleted);
end

function onClose()
	DB.removeHandler(DB.getPath(window.getDatabaseNode(), "poi.*"), "onDelete", onPoiDeleted);
end

function addEntry(sClass, sRecord)
	local w = createWindow();
	if not w then
		return;
	end
	w.setLink(sClass, sRecord)

	local node = DB.findNode(sRecord);
	if node then
		local token = DB.getValue(node, "token", "");
		if token ~= "" then
			w.setToken(token);
		end
	end
	
	return w;
end

function onMenuSelection(selection)
	if selection == 5 then
		addEntry(true);
	end
end

function onDrop(x, y, draginfo)
	local sDragType = draginfo.getType();
	if sDragType ~= "shortcut" then
		return false;
	end

	local sClass, sRecord = draginfo.getShortcutData()

	local w = self.addEntry(sClass, sRecord);
end

function onPoiDeleted(nodeDeleted)
	local token = POI.getTokenFromPoi(nodeDeleted);
	if token then
		token.delete();
	end
end
