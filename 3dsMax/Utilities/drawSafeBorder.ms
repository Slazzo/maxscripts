(
	fn gw_frameborder =
	(
		/* parameters */
		frame_border_mul = 0.1; --5% border on longest edge
		
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
	
	try( unregisterredrawviewscallback ::sz_gw_frameborder ) catch()
	::sz_gw_frameborder = gw_frameborder;
	registerredrawviewscallback ::sz_gw_frameborder;
)