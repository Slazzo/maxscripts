(
	/* global params */
	if sz_frameborder_params == undefined do (
		::sz_frameborder_params = true;
		::sz_frameborder_scale = 0.1;
		::sz_gw_frameborder_clbk = undefined;
	)
	
	fn gw_frameborder =
	(
		/* parameters */
		local frame_border_mul = ::sz_frameborder_scale; --0.1 = 5% border on longest edge
		
		/* border valid only when safeFrames are on */
		if displaysafeframes do
		(
			gw.settransform (matrix3 1);
			
			/* draw safe frame */
			vw = gw.getwinsizex(); vh = gw.getwinsizey(); va = (vw as float)/(vh as float);
			rw = renderwidth; rh = renderheight; ra = (rw as float)/(rh as float); fw = vw; fh = vh;
			if ra >= 1. then (fw = vw; fh=fw/ra) else (fw=vw*ra; fh=vw)
			if fh >= vh then ( scl = 1.*vh/fh; fw *= scl; fh *= scl);
			fwo = (vw-fw)*0.5; fho = (vh-fh)*0.5;

			if fw > fh then border = fw*frame_border_mul*0.5 else border= fh*frame_border_mul*0.5;
			gw.hpolyline #( \
				[fwo+border,fho+border,0], \
				[fw+fwo-border,fho+border,0], \
				[fw+fwo-border,fh+fho-border,0], \
				[fwo+border,fh+fho-border,0] ) true rgb:#(gray,gray,gray,gray)
				
			/* draw render output */
			ri = "output: "+(rw as string)+"x"+(rh as string)
			ris = gw.gettextextent ri; ris.x = vw/2-ris.x/2; --center on viewport width
			if ris.y>border then ris.y=fho+border else ris.y=fho+(border-ris.y)/2 ; --center inside/over border
			if ris.y<0 do ris.y=0; --check for out of screen
			gw.wtext [ris.x, vh-ris.y,0] ri color:gray

			/* ask for a full redraw */
			gw.enlargeupdaterect #whole
		)

	)
	
	rollout main "Draw custom safe border" width:200 (
		spinner spn_border_scale "border scale" range:[1e-6, 1, ::sz_frameborder_scale] scale:1e-3
		checkbutton chk_enable "Enabled" checked:(::sz_gw_frameborder != undefined)
		
		on spn_border_scale changed val do ( ::sz_frameborder_scale = val; )
		
		on chk_enable changed state do (
			if state == on then (
				::sz_gw_frameborder_clbk = gw_frameborder;
				registerredrawviewscallback ::sz_gw_frameborder_clbk;
			) else (
				unregisterredrawviewscallback ::sz_gw_frameborder_clbk;
				::sz_gw_frameborder_clbk = undefined;
			)
		)
	)
	
	try(destroydialog ::sz_gw_frameborder_roll) catch()
	::sz_gw_frameborder_roll = main;
	createdialog ::sz_gw_frameborder_roll;
)