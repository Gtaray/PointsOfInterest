-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- I have to replace this entire script because I need access to the local variables
-- and there's no way to get them outside of copying the whole script.

local MIN_WIDTH = 200;
local MIN_HEIGHT = 200;
local SMALL_WIDTH = 500;
local SMALL_HEIGHT = 500;

local IMAGEDATA_WIDTH = 288;
local bImagePositionInitialized = false;
local nImageLeft, nImageTop, nImageRight, nImageBottom;

local POI_WIDTH = 288;

local _bLastHasTokens = nil;

function onInit()
	local bPanel = isPanel();
	if bPanel then
		registerMenuItem(Interface.getString("windowshare"), "windowshare", 7, 7);
		if toolbar and toolbar.subwindow then
			toolbar.subwindow.toolbar_anchor.setAnchor("right", nil, "right", "absolute", -100);
		end
	end
	
	self.saveImagePosition();

	self.updateHeaderDisplay();
	self.updateImagePosition();
	self.updateToolbarDisplay();

	ImageManager.registerImage(image);

	if not bPanel then
		_bLastHasTokens = image.hasTokens();
		if _bLastHasTokens then
			self.setToolbarVisibility(true);
		end
	end

	-- Initialize PoI window to be hidden first
	self.updatePointsOfInterestVisibility(false);
end

function onClose()
	ImageManager.unregisterImage(image);
end

function isPanel()
	return (getClass() ~= "imagewindow");
end

function onIDChanged()
	self.updateHeaderDisplay();
	self.onNameUpdated();
end

function onLockChanged()
	self.updateHeaderDisplay();
	self.updateImagePosition();
end

function onToolbarChanged(nState)
	local bShow = (nState == 1);
	self.updateToolbarVisibility(bShow);
end

-- START NEW CODE
function onPoiChanged(nState)
	local bShow = (nState == 1);
	self.updatePointsOfInterestVisibility(bShow);
end
-- END NEW CODE

function onCursorModeChanged()
	self.updateToolbarDisplay();
end

function onStateChanged()
	self.updateToolbarDisplay();
end

function onTokenCountChanged()
	self.updateToolbarDisplay();
	
	if not isPanel() then
		local bHasTokens = image.hasTokens();
		if _bLastHasTokens ~= bHasTokens then
			_bLastHasTokens = bHasTokens;
			self.setToolbarVisibility(bHasTokens);
		end
	end
end

function saveImagePosition()
	nImageLeft, nImageTop, nImageRight, nImageBottom = image.getStaticBounds();
	bImagePositionInitialized = true;
end

-- THIS FUNCTION WAS UPDATED TO ACCOUNT FOR THE POI WINDOW
function updateImagePosition()
	if not bImagePositionInitialized then return; end
	if Session.IsHost then
		local nLocalImageRight = nImageRight;

		if WindowManager.getLockedState(getDatabaseNode()) then
			imagedata.setVisible(false);
		else
			nLocalImageRight = nLocalImageRight - IMAGEDATA_WIDTH;

			imagedata.setVisible(true);
			imagedata.setStaticBounds(nLocalImageRight, nImageTop, nImageRight, nImageBottom);
		end

		if poi.isVisible() then
			-- We move the local right anchor after setting static bounds
			-- so that the poi window's right anchor accounts for the imagedata's
			-- left anchor point.
			poi.setStaticBounds(nLocalImageRight - POI_WIDTH, nImageTop, nLocalImageRight, nImageBottom);
			nLocalImageRight = nLocalImageRight - POI_WIDTH;
		end

		-- Finally update the image's right anchor with the combined width of 
		-- the poi window and imagedata control
		image.setStaticBounds(nImageLeft, nImageTop, nLocalImageRight, nImageBottom);
	else
		image.setStaticBounds(nImageLeft, nImageTop, nImageRight, nImageBottom);
	end
end

function updateHeaderDisplay()
	if header and header.subwindow then
		header.subwindow.update();
	end
end

function setToolbarVisibility(bState)
	local nState;
	if bState then
		nState = 1;
	else
		nState = 0;
	end
	if header and header.subwindow and header.subwindow.button_toolbar then
		header.subwindow.button_toolbar.setValue(nState);
	end
end

function updateToolbarVisibility(bShowToolbar)
	if not bImagePositionInitialized then return; end
	if not toolbar then return; end
	
	if isPanel() then
		bShowToolbar = true;
	end

	if bShowToolbar ~= toolbar.isVisible() then
		local nToolbarLeft, nToolbarTop, nToolbarRight, nToolbarHeight = toolbar.getStaticBounds();
		if bShowToolbar then
			nImageTop = nToolbarTop + nToolbarHeight;
		else
			nImageTop = nToolbarTop;
		end

		self.updateImagePosition();

		toolbar.setVisible(bShowToolbar);
	end
end

function updateToolbarDisplay()
	if toolbar and toolbar.subwindow then
		toolbar.subwindow.update();
	end
end

-------------------------------------------------------------------------------
-- START NEW CODE
-------------------------------------------------------------------------------
function updatePointsOfInterestVisibility(bShowPoiWindow)
	if not bImagePositionInitialized then return; end
	if not poi then return; end

	if bShowPoiWindow ~= poi.isVisible() then
		poi.subwindow.list_iedit.setValue(0);
		poi.setVisible(bShowPoiWindow);
		self.updateImagePosition();
	end
end

-------------------------------------------------------------------------------
-- END NEW CODE
-------------------------------------------------------------------------------

function onNameUpdated()
	local nodeRecord = getDatabaseNode();
	local bID = LibraryData.getIDState("image", nodeRecord);
	
	local sTooltip = "";
	if bID then
		sTooltip = DB.getValue(nodeRecord, "name", "");
		if sTooltip == "" then
			sTooltip = Interface.getString("library_recordtype_empty_image")
		end
	else
		sTooltip = DB.getValue(nodeRecord, "nonid_name", "");
		if sTooltip == "" then
			sTooltip = Interface.getString("library_recordtype_empty_nonid_image")
		end
	end
	setTooltipText(sTooltip);
	if header and header.subwindow and header.subwindow.link then
		header.subwindow.link.setTooltipText(sTooltip);
	end
end

function onMenuSelection(item, subitem)
	if item == 3 then
		if subitem == 1 then
			local w,h = self.getWindowSizeAtSmallImageSize();
			setSize(w, h);
			image.setViewpoint(0,0,0);
		elseif subitem == 2 then
			local w,h = self.getWindowSizeAtOriginalImageSize();
			setSize(w, h);
			image.setViewpoint(0,0,1);
		elseif subitem == 4 then
			local w,h = self.getWindowSizeAtOriginalHeight();
			setSize(w, h);
			image.setViewpoint(0,0,0.1);
		elseif subitem == 5 then
			local w,h = self.getWindowSizeAtOriginalWidth();
			setSize(w, h);
			image.setViewpoint(0,0,0.1);
		end
	elseif item == 7 then
		if subitem == 7 then
			share();
		end
	end
end

function getWindowSizeAtSmallImageSize()
	local iw, ih = image.getImageSize();
	local cw, ch = image.getSize();
	local nMarginLeft, nMarginTop = image.getPosition();
	local ww, wh = getSize();
	local nMarginRight = ww - nMarginLeft - cw;
	local nMarginBottom = wh - nMarginTop - ch;

	local w = iw + nMarginLeft + nMarginRight;
	local h = ih + nMarginTop + nMarginBottom;
	if w > SMALL_WIDTH then
		w = SMALL_WIDTH;
	end
	if h > SMALL_HEIGHT then
		h = SMALL_HEIGHT;
	end
	
	return w,h;
end

function getWindowSizeAtOriginalImageSize()
	local iw, ih = image.getImageSize();
	local cw, ch = image.getSize();
	local nMarginLeft, nMarginTop = image.getPosition();
	local ww, wh = getSize();
	local nMarginRight = ww - nMarginLeft - cw;
	local nMarginBottom = wh - nMarginTop - ch;

	local w = iw + nMarginLeft + nMarginRight;
	local h = ih + nMarginTop + nMarginBottom;
	if w < MIN_WIDTH then
		local fScaleW = (MIN_WIDTH/w);
		w = w * fScaleW;
		h = h * fScaleW;
	end
	if h < MIN_HEIGHT then
		local fScaleH = (MIN_HEIGHT/h);
		w = w * fScaleH;
		h = h * fScaleH;
	end
	
	return w,h;
end

function getWindowSizeAtOriginalHeight()
	local iw, ih = image.getImageSize();
	local cw, ch = image.getSize();
	local nMarginLeft, nMarginTop = image.getPosition();
	local ww, wh = getSize();
	local nMarginRight = ww - nMarginLeft - cw;
	local nMarginBottom = wh - nMarginTop - ch;

	local w = cw + nMarginLeft + nMarginRight;
	local h = ((ih/iw)*cw) + nMarginTop + nMarginBottom;
	
	return w,h;
end

function getWindowSizeAtOriginalWidth()
	local iw, ih = image.getImageSize();
	local cw, ch = image.getSize();
	local nMarginLeft, nMarginTop = image.getPosition();
	local ww, wh = getSize();
	local nMarginRight = ww - nMarginLeft - cw;
	local nMarginBottom = wh - nMarginTop - ch;

	local w = ((iw/ih)*ch) + nMarginLeft + nMarginRight;
	local h = ch + nMarginTop + nMarginBottom;
	
	return w,h;
end
