(
	local g_mainForm = undefined
	local g_listForm = undefined
	local g_lockForm = undefined
	
	/* structures */
	struct NodeLockState
	(
		mNode,
		-- reading member values
		-- only true and false flags permited
		mv_x = false, mv_y = false, mv_z = false,
		rt_x = false, rt_y = false, rt_z = false,
		sc_x = false, sc_y = false, sc_z = false,
	
		fn GetLocks =
		(
			if not isValidNode mNode do return false
			
			nLocks = getTransformLockFlags mNode
			mv_x = nLocks[1] ; mv_y = nLocks[2]; mv_z = nLocks[3];
			rt_x = nLocks[4] ; rt_y = nLocks[5]; rt_z = nLocks[6];
			sc_x = nLocks[7] ; sc_y = nLocks[8]; sc_z = nLocks[8];
		),
		fn SetLocks =
		(
			if not isValidNode mNode do return false
			
			locksBitArr = #{1..9}
			locksBitArr[1] = mv_x; locksBitArr[2] = mv_y; locksBitArr[3] = mv_z;
			locksBitArr[4] = rt_x; locksBitArr[5] = rt_y; locksBitArr[6] = rt_z;
			locksBitArr[7] = sc_x; locksBitArr[8] = sc_y; locksBitArr[9] = sc_z;
			setTransformLockFlags mNode locksBitArr
		),
		fn CheckMove =
		(
			state = 0 --0 = has no locks; 1 = has some locks; 2 = has all locks
			if mv_x and mv_y and mv_z 
			then state = 2
			else
			(
				if mv_x or mv_y or mv_z do state = 1
			)
			state
		),
		fn CheckRotate =
		(
			state = 0 --0 = has no locks; 1 = has some locks; 2 = has all locks
			if rt_x and rt_y and rt_z 
			then state = 2
			else
			(
				if rt_x or rt_y or rt_z do state = 1
			)
			state
		),
		fn CheckScale =
		(
			state = 0 --0 = has no locks; 1 = has some locks; 2 = has all locks
			if sc_x and sc_y and sc_z 
			then state = 2
			else
			(
				if sc_x or sc_y or sc_z do state = 1
			)
			state
		)		
	)
	
	struct CommonLockState
	(
		NodeLockStates=#(),
		-- reading the member values
		-- unsupplied = don't read
		-- true = all flags are true
		-- false = all flags are false
		-- undefined = flags are mixed
		mv_x = unsupplied, mv_y = unsupplied, mv_z = unsupplied,
		rt_x = unsupplied, rt_y = unsupplied, rt_z = unsupplied,
		sc_x = unsupplied, sc_y = unsupplied, sc_z = unsupplied,
		
		fn CValue &v1 v2 =
		(
			if v1 != undefined do
			(
				if v1 != v2 do v1 = undefined
				
			)
		),
		fn UpdateStates =
		(
			if NodeLockStates == undefined or classof NodeLockStates != array or NodeLockStates.count == 0 do
			(
				mv_x = unsupplied; mv_y = unsupplied; mv_z = unsupplied;
				rt_x = unsupplied; rt_y = unsupplied; rt_z = unsupplied;
				sc_x = unsupplied; sc_y = unsupplied; sc_z = unsupplied;
				return false
			)
			-- Use first node lock as reference
			mv_x = NodeLockStates[1].mv_x; mv_y = NodeLockStates[1].mv_y; mv_z = NodeLockStates[1].mv_z;
			rt_x = NodeLockStates[1].rt_x; rt_y = NodeLockStates[1].rt_y; rt_z = NodeLockStates[1].rt_z;
			sc_x = NodeLockStates[1].sc_x; sc_y = NodeLockStates[1].sc_y; sc_z = NodeLockStates[1].sc_z;
			-- Loop and detect if any state is diferent from first's node
			for nlstate in NodeLockStates do
			(
				CValue &mv_x nlstate.mv_x; CValue &mv_y nlstate.mv_y; CValue &mv_z nlstate.mv_z
				CValue &rt_x nlstate.rt_x; CValue &rt_y nlstate.rt_y; CValue &rt_z nlstate.rt_z
				CValue &sc_x nlstate.sc_x; CValue &sc_y nlstate.sc_y; CValue &sc_z nlstate.sc_z
			)
		),
		fn ApplyState =
		(
			for nlstate in NodeLockStates do
			(
				if mv_x != unsupplied and mv_x != undefined do nlstate.mv_x = mv_x
				if mv_y != unsupplied and mv_y != undefined do nlstate.mv_y = mv_y
				if mv_z != unsupplied and mv_z != undefined do nlstate.mv_z = mv_z
				if rt_x != unsupplied and rt_x != undefined do nlstate.rt_x = rt_x
				if rt_y != unsupplied and rt_y != undefined do nlstate.rt_y = rt_y
				if rt_z != unsupplied and rt_z != undefined do nlstate.rt_z = rt_z
				if sc_x != unsupplied and sc_x != undefined do nlstate.sc_x = sc_x
				if sc_y != unsupplied and sc_y != undefined do nlstate.sc_y = sc_y
				if sc_z != unsupplied and sc_z != undefined do nlstate.sc_z = sc_z
				nlstate.SetLocks()
			)
		)
	)
	
	rollout ObjectList_roll "Objects" width:204 height:160
	(
		local callbackSelectionChanged
		local selectedNodes
		
		/* ui controls */
		multiListBox mlb "" items:#() selection:#() height:12 width:180 pos:(point2 0 0)
		
		/* functions */
		fn UpdateList ev nd =
		(
			selectedNodes = selection as array
			mlb.items = for o in selectedNodes collect o.name
			mlb.selection = #{1..selectedNodes.count}
			g_mainForm.ReadLocksFrom selectedNodes
		)
		
		/* events */
		on mlb selectionEnd do 
		(
			currentSelection = for i in mlb.selection collect selectedNodes[i]
			g_mainForm.ReadLocksFrom currentSelection
		)
		on ObjectList_roll open do
		(
			-- register callback
			callbackSelectionChanged = NodeEventCallback mouseUp:true delay:1000 selectionChanged:UpdateList
			UpdateList undefined undefined
		)
		on ObjectList_roll close do
		(
			-- remove callback
			callbackSelectionChanged = undefined
			gc light:true
		)
	)
	
	/* rollouts */
	rollout Locks_roll "Locks" width:192 height:160
	(
		local currentState
		/* ui controls */
		group "Move:" 
		(
			checkbox chk_mv_x	"X" pos:[24,24] width:32 height:16
			checkbox chk_mv_y	"Y" pos:[64,24] width:32 height:16
			checkbox chk_mv_z	"Z" pos:[104,24] width:32 height:16
			checkbox chk_mv_all	"All" pos:[144,24] width:32 height:16
		)
		group "Rotate:"
		(
			checkbox chk_rt_x	"X" pos:[24,64] width:32 height:16
			checkbox chk_rt_y	"Y" pos:[64,64] width:32 height:16
			checkbox chk_rt_z	"Z" pos:[104,64] width:32 height:16
			checkbox chk_rt_all	"All" pos:[144,64] width:32 height:16
		)
		group "Scale:"
		(
			checkbox chk_sc_x	"X" pos:[24,104] width:32 height:16
			checkbox chk_sc_y	"Y" pos:[64,104] width:32 height:16
			checkbox chk_sc_z	"Z" pos:[104,104] width:32 height:16
			checkbox chk_sc_all	"All" pos:[144,104] width:32 height:16
		)
		button btn_clearLocks 	"Clear Locks" pos:[8,136] width:176 height:16 tooltip:"Remove all locks from selection"
		--button btn_setLocks 	"Set Locks" pos:[112,136] width:72 height:16
		
		/* functions */
		fn UpdateState =
		(
			if chk_mv_x.triState == 2 then() else (currentState.mv_x = chk_mv_x.state)
			if chk_mv_y.triState == 2 then() else (currentState.mv_y = chk_mv_y.state)
			if chk_mv_z.triState == 2 then() else (currentState.mv_z = chk_mv_z.state)
			if chk_rt_x.triState == 2 then() else (currentState.rt_x = chk_rt_x.state)
			if chk_rt_y.triState == 2 then() else (currentState.rt_y = chk_rt_y.state)
			if chk_rt_z.triState == 2 then() else (currentState.rt_z = chk_rt_z.state)
			if chk_sc_x.triState == 2 then() else (currentState.sc_x = chk_sc_x.state)
			if chk_sc_y.triState == 2 then() else (currentState.sc_y = chk_sc_y.state)
			if chk_sc_z.triState == 2 then() else (currentState.sc_z = chk_sc_z.state)
		)
		fn ApplyLocks =
		(
			suspendEditing()
			if currentState != undefined do
			(
				UpdateState()
				currentState.ApplyState()
			)
			resumeEditing()
		)
		fn ClearUI =
		(
			chk_mv_x.state = chk_mv_y.state = chk_mv_z.state = chk_mv_all.state = false
			chk_rt_x.state = chk_rt_y.state = chk_rt_z.state = chk_rt_all.state = false
			chk_sc_x.state = chk_sc_y.state = chk_sc_z.state = chk_sc_all.state = false
		)
		fn ReadFromLockState nState =
		(
			currentState = nState
			if nState.mv_x == undefined then chk_mv_x.triState = 2 else chk_mv_x.state = nState.mv_x
			if nState.mv_y == undefined then chk_mv_y.triState = 2 else chk_mv_y.state = nState.mv_y
			if nState.mv_z == undefined then chk_mv_z.triState = 2 else chk_mv_z.state = nState.mv_z
			if nState.rt_x == undefined then chk_rt_x.triState = 2 else chk_rt_x.state = nState.rt_x
			if nState.rt_y == undefined then chk_rt_y.triState = 2 else chk_rt_y.state = nState.rt_y
			if nState.rt_z == undefined then chk_rt_z.triState = 2 else chk_rt_z.state = nState.rt_z
			if nState.sc_x == undefined then chk_sc_x.triState = 2 else chk_sc_x.state = nState.sc_x
			if nState.sc_y == undefined then chk_sc_y.triState = 2 else chk_sc_y.state = nState.sc_y
			if nState.sc_z == undefined then chk_sc_z.triState = 2 else chk_sc_z.state = nState.sc_z
			
			chk_mv_all.triState = if chk_mv_x.triState == chk_mv_y.triState and chk_mv_x.triState == chk_mv_z.triState then chk_mv_x.triState else 0
			chk_rt_all.triState = if chk_rt_x.triState == chk_rt_y.triState and chk_rt_x.triState == chk_rt_z.triState then chk_rt_x.triState else 0
			chk_sc_all.triState = if chk_sc_x.triState == chk_sc_y.triState and chk_sc_x.triState == chk_sc_z.triState then chk_sc_x.triState else 0
		)
		fn UpdateUI =
		(
			States = g_mainForm.States
			if States.NodeLockStates.count > 0 then
			(
				ReadFromLockState States
			)
			else
			(
				ClearUI()
			)
		)
		
		/* events */
		on chk_mv_x changed state do ApplyLocks()
		on chk_mv_y changed state do ApplyLocks()
		on chk_mv_z changed state do ApplyLocks()
		
		on chk_rt_x changed state do ApplyLocks()
		on chk_rt_y changed state do ApplyLocks()
		on chk_rt_z changed state do ApplyLocks()
		
		on chk_sc_x changed state do ApplyLocks()
		on chk_sc_y changed state do ApplyLocks()
		on chk_sc_z changed state do ApplyLocks()
		
		on chk_mv_all changed state do
		(
			chk_mv_x.state = chk_mv_y.state = chk_mv_z.state = state
			ApplyLocks()
		)
		on chk_rt_all changed state do
		(
			chk_rt_x.state = chk_rt_y.state = chk_rt_z.state = state
			ApplyLocks()
		)
		on chk_sc_all changed state do
		(
			chk_sc_x.state = chk_sc_y.state = chk_sc_z.state = state
			ApplyLocks()
		)
		on btn_clearLocks pressed do
		(
			ClearUI()
			ApplyLocks()
		)
		--on btn_setLocks pressed do
		--(
		--	ApplyLocks()
		--)
	)
	
	rollout objectLocks_roll "Transform Locks" width:400 height:188
	(
		/* ui controls */
		subrollout roll_objectList width:196 height:200 pos:(point2 0 0)
		subrollout roll_Paramenters width:204 height:200 pos:(point2 196 0)
		
		/* locals */
		local aboutTitle = false
		local States = undefined
		
		/* functions */
		function ReadLocksFrom nObjects =
		(
			States=CommonLockState()
			States.NodeLockStates = for nObj in nObjects collect
				NodeLockState mNode:nObj
			
			for s in States.NodeLockStates do s.GetLocks()
			States.UpdateStates()
			g_lockForm.UpdateUI()
		)
		
		/* events */
		on objectLocks_roll close do
		(
			iniPath = (getDir #temp)+"/Slazzo"
			if(not doesfileexist iniPath) do makedir iniPath
			iniDir = iniPath + "/UI_defaultSettings.ini"
			rollPos=GetDialogPos objectLocks_roll
			setINISetting iniDir "Lock_Transform" "position_x" (rollPos.x as string) 
			setINISetting iniDir "Lock_Transform" "position_y" (rollPos.y as string)
		)
		on objectLocks_roll open do
		(
			iniDir=(getDir #temp)+"/Slazzo/UI_defaultSettings.ini"
			if(doesfileexist iniDir) do
			(
				rollPos=point2 ((getINISetting iniDir "Lock_Transform" "position_x" )as float) ((getINISetting iniDir "Lock_Transform" "position_y") as float)
				if rollPos!= point2 0 0 do SetDialogPos objectLocks_roll rollPos
			)
			
			g_mainForm = objectLocks_roll
			AddSubRollout roll_Paramenters Locks_roll
			g_lockForm = Locks_roll
			AddSubRollout roll_objectList ObjectList_roll	
			g_listForm = ObjectList_roll
		)
		
		on objectLocks_roll help do
		(
			objectLocks_roll.title = "For help please contact slazzo@gmail.com"
		)
	)

	try( destroydialog ::sz_objectLocks_roll ) catch()
	::sz_objectLocks_roll = objectLocks_roll;
	createDialog ::sz_objectLocks_roll;
)