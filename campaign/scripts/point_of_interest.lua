local bWatchingSource = false;
local bMirrorIDState = false;

function onInit()
	-- Acquire token reference, if any
	self.linkToken()
	-- Set up the links
	self.onLinkChanged();

	-- Register the deletion menu item for the host
	registerMenuItem(Interface.getString("list_menu_deleteitem"), "delete", 6);
	registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7);

	self.onEditModeChanged();
end

function onClose()
	self.stopWatchingSourceIDState();
end

-------------------------------------------------------------------------------
-- STATE MANAGEMENT
-------------------------------------------------------------------------------
function startWatchingSourceIDState()
	if not bWatchingSource and self.isValidSourceLink() then
		bWatchingSource = true;
		local node = link.getTargetDatabaseNode();
		DB.addHandler(DB.getPath(node, "isidentified"), "onUpdate", onSourceIDUpdated)
	end
end

function stopWatchingSourceIDState()
	if bWatchingSource and self.isValidSourceLink() then
		bWatchingSource = false;
		local node = link.getTargetDatabaseNode();
		DB.removeHandler(DB.getPath(node, "isidentified"), "onUpdate", onSourceIDUpdated)
	end
end

function isWatchingSourceIDState()
	return bWatchingSource;
end

function startMirroringIDState()
	if not bMirrorIDState then
		bMirrorIDState = true;
	end
end

function stopMirroringIDState()
	if bMirrorIDState then
		bMirrorIDState = false;
	end
end

function isMirroringSourceIDState()
	return bMirrorIDState;
end

function isValidSourceLink()
	return link.getTargetDatabaseNode() ~= getDatabaseNode();
end

-------------------------------------------------------------------------------
-- EVENTS
-------------------------------------------------------------------------------
function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		DB.deleteNode(getDatabaseNode())
	end
end

function onEditModeChanged()
	local bEditMode = WindowManager.getEditMode(self, "list_iedit");
	idelete.setVisible(bEditMode);
end

function onSourceIDUpdated()
	if not self.isValidSourceLink() then
		return;
	end
	local sourcenode = link.getTargetDatabaseNode();

	local sClass = link.getValue();
	local sRecordType = LibraryData.getRecordTypeFromDisplayClass(sClass);
	local bID = LibraryData.getIDState(sRecordType, sourcenode, true);
	local nCur = isidentified.getValue();
	
	-- Only set the value if it's different than what it should be
	if bID and nCur == 0 then
		isidentified.setValue(1)
	elseif not bID and nCur == 1 then
		isidentified.setValue(0);
	end
end

function onIDChanged()
	local nodeRecord = getDatabaseNode();
	local sClass = link.getValue();
	local sRecordType = LibraryData.getRecordTypeFromDisplayClass(sClass);
	local bID = LibraryData.getIDState(sRecordType, nodeRecord, true);
	
	name.setVisible(bID);
	nonid_name.setVisible(not bID);

	self.setSourceIDStateToMatch();
end

function onVisibilityChanged()
	POI.updateVisibility(getDatabaseNode());
end

function onLinkChanged()
	-- Stop watching/mirroring the id state of the previous source node
	self.stopMirroringIDState();
	self.stopWatchingSourceIDState();

	-- link the name, nonid_name, and isidentified fields
	self.linkFields();

	self.setIDStateToMatchSource();

	-- update the id state
	self.onIDChanged();

	-- Start watching/mirroring the id state of the current source node
	self.startMirroringIDState();
	self.startWatchingSourceIDState();
end

-------------------------------------------------------------------------------
-- DATA MODIFIERS
-------------------------------------------------------------------------------
function setIDStateToMatchSource()
	local sClass = link.getValue();
	local sRecordType = LibraryData.getRecordTypeFromDisplayClass(sClass);
	isidentified.setVisible(LibraryData.getIDMode(sRecordType));

	-- if this element doesn't care about identification, then bail early
	if not isidentified.isVisible() then
		return;
	end

	if not self.isValidSourceLink() then
		return;
	end
	
	-- Pull from the source and set this
	local linknode = link.getTargetDatabaseNode();
	local newState = DB.getValue(linknode, "isidentified", 0);
	local curState = isidentified.getValue();
	if curState ~= newState then
		isidentified.setValue(newState)
	end
end

function setSourceIDStateToMatch()
	if not self.isMirroringSourceIDState() then
		return;
	end

	if not self.isValidSourceLink() then
		return
	end

	local sourcenode = link.getTargetDatabaseNode();
	local nCur = DB.getValue(sourcenode, "isidentified", 0);
	local nNew = isidentified.getValue()

	if nCur ~= nNew then
		DB.setValue(sourcenode, "isidentified", "number", nNew);
	end
end

function linkToken()
	local imageinstance = token.populateFromImageNode(tokenrefnode.getValue(), tokenrefid.getValue());
	if imageinstance then
		TokenManager.linkToken(getDatabaseNode(), imageinstance);
	end
end

function setLink(sClass, sRecord)
	link.setValue(sClass, sRecord);
end

function linkFields()
	-- Don't do any of this linking unless the link reference is set to something
	-- other than this current node
	if self.isValidSourceLink() then
		local node = link.getTargetDatabaseNode();

		name.setLink(DB.createChild(node, "name", "string"), true);
		nonid_name.setLink(DB.createChild(node, "nonid_name", "string"), true);

		self.startWatchingSourceIDState();
	end
end

function setToken(sToken)
	token.setValue(sToken)
end