(	
	rollout main "Set background image" width:260 height:32
	(
		spinner 'spn_max_edge_size' "Longest edge pixels" pos:[8,8] width:106 height:16 \
			range:[64,64000,1920] type:#integer scale:10 fieldwidth:40 align:#left
		button 'btn_pick_image' "Load image..." pos:[162,8] width:82 height:16 align:#left 
 
		on btn_pick_image pressed do
		(
			local longest_edge_pixels = spn_max_edge_size.value;

			local bg_bitmap = selectbitmap caption:"Select new background image";
			
			if (bg_bitmap != undefined and (environmentmap == undefined \
				or querybox "Environment slot already busy, override with new selected map?")) do 
			(
				bg_ratio = (bg_bitmap.width as float)/(bg_bitmap.height as float);
			
				-- calculate ouput 
				output_res = point2 longest_edge_pixels longest_edge_pixels;
				
				if bg_ratio >= 1 then 
					output_res.y/=bg_ratio; 
				else 
					output_res.x*=bg_ratio;
				
				-- create new bitmap
				bg_map = bitmaptexture bitmap:bg_bitmap;
				
				-- set to environment
				environmentmap = bg_map;
				bg_map.coords.mappingtype = 1; -- as environment
				bg_map.coords.mapping = 3;	-- as screen
				
				-- set to viewport
				backgroundimagefilename = bg_bitmap.filename;
				actionman.executeaction 0 "620"; -- check use file
				setbkgimageaspect #output;
				displaysafeframes = true;
				
				-- apply new output resolution
				renderwidth = output_res.x;
				renderheight = output_res.y;
				renderscenedialog.update();
			)	
		)
	)
	
	try( destroydialog ::setBackgroundImage_roll ) catch()
	::setBackgroundImage_roll = main;
	createdialog ::setBackgroundImage_roll;
)