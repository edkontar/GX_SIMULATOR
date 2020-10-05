function gxWidget::INIT,wParent,subject,frame=frame,name=name,_extra=_extra
 compile_opt hidden
  catch, error_stat
  if error_stat ne 0 then begin
      catch, /cancel
      if !ERROR_STATE.NAME eq 'IDL_M_KEYWORD_BAD' then goto,jump
      MESSAGE, /INFO, !ERROR_STATE.MSG
      if widget_valid(self.wIDBase) then widget_control,self.wIDBase,/destroy
      return, 0
  end
 if ~obj_valid(subject) then message,'Invalid subject provided'
 if ~widget_info(wparent,/valid) then message,'Invalid parent widget provided'
 self.subject=subject
 void=self->IDLexWidget::Init(wParent,frame=frame)
 widget_control,self.wIDBase,set_uvalue=self.subject
 self.subject->SetProperty,wParent=wParent
 jump:
 self.wBase = widget_base( $
    self.wIDBase, $
    /column, $
    event_func='IDLexWidget__HandleEvent', $
    uvalue=self, $
    notify_realize='IDLexWidget__OnRealize', $
    uname=name,_extra=_extra)
  self->CreatePanel,_extra=_extra
 return,1
end
;------------------------------------------------------------
function gxWidget::Rewrite, event
compile_opt hidden
if obj_isa(self.subject,'gxmodel') then (self.subject->GetVolume())->Update
if obj_isa(self.subject,'gxvolume') then (self.subject)->Update
return, {GXDRAW,id: self.wIDBase, top: event.top, handler:0L} 
end
;------------------------------------------------------------
pro gxWidget::CreatePanel,_extra=_extra
  main_base=get_tlb(self.wBase)
  state_base=widget_info(main_base,find_by_uname='STATEBASE')
  if widget_info(state_base,/valid) then begin
    widget_control,state_base,get_uvalue=state
    if size(state,/tname) eq 'STRUCT' then expert=state.expert
  endif

 subdirectory=['resource', 'bitmaps']
 device, get_screen_size=scr
 xscale=scr[0]/1920.
 font=!defaults.font
 case 1 of
   obj_isa(self.subject,'gxMapContainer'):begin
   prefix='GXMAPCONTAINER:'
   wMenu=widget_button(self.wbase, VALUE='Map_Container',uname=prefix+'MENU', /MENU,sensitive=0);,font=font)
  end
  obj_isa(self.subject,'gxmodel'):begin
   prefix='GXMODEL:'
   self.subject->GetProperty,NS=NS,EW=EW,ROI=ROI,FLUXTUBECOUNT=FLUXTUBECOUNT,$
                 XCOORD_CONV=XCOORD_CONV,YCOORD_CONV=YCOORD_CONV,ZCOORD_CONV=ZCOORD_CONV,$
                 XRANGE=XRANGE,YRANGE=YRANGE,ZRANGE=ZRANGE,ISROI=ISROI,FULLROI=FULLROI,STEPS=STEPS,SUBGRIDPTS=SUBGRIDPTS,bscale=bscale,gyro=gyro,winOS=winOS
   wToolbarBase = widget_base(self.wBase, /row, /frame,/TOOLBAR)

   wZoom= widget_button(font=font,widget_base(wToolbarBase,/nonexclusive,/row,/toolbar)  , $
              value=gx_bitmap(filepath('zoom_in.bmp', subdirectory=subdirectory)), $
              /bitmap,tooltip='Model View',uname=prefix+'ModelView')
  
   wUpdate= widget_button(font=font,widget_base(wToolbarBase,/row,/toolbar)  , $
              value=gx_bitmap(filepath('redo.bmp', subdirectory=subdirectory)), $
              /bitmap,tooltip='Update Volume',uname=prefix+'update')            

   wROIBase=widget_base(wToolbarBase,/row,/toolbar,/nonexclusive)

   wIsROI= widget_button(font=font, wROIBase, $
              value=IsROI?gx_bitmap(filepath('image.bmp', subdirectory=subdirectory)):$
              gx_bitmap(filepath('eye_closed.bmp', subdirectory=subdirectory)), $
              /bitmap,tooltip='Select this Model as ROI',uname=prefix+'IsROI')
   widget_control,wIsROI,SET_BUTTON=IsROI
   wFullROI= widget_button(font=font, wROIBase, $
              value=gx_bitmap(filepath('volume.bmp', subdirectory=subdirectory)), $
              /bitmap,tooltip='Full Volume ROI',uname=prefix+'FullROI')
   widget_control,wFullROI,SET_BUTTON=FullROI

   wExecBase=widget_base(wToolbarBase,/row,/toolbar)
   
   
   wLINESFROMSEEDS= widget_button(font=font, wExecBase, $
     value=gx_bitmap(filepath('roi.bmp', subdirectory=subdirectory)), $
     /bitmap,tooltip='Create fieldlines at seeded locations',uname=prefix+'LINESFROMSEEDS')
   
   wImportSeeds= widget_button(font=font, wExecBase, $
     value=gx_bitmap(filepath('freehand.bmp', subdirectory=subdirectory)), $
     /bitmap,tooltip='Import fieldlines seeds',uname=prefix+'ImportSeeds')
   
   wImportLOSMap= widget_button(font=font, wExecBase, $
              value=gx_bitmap(filepath('surface.bmp', subdirectory=subdirectory)), $
              /bitmap,tooltip='Import LOS reference map',uname=prefix+'LOSMAP')  
   wImportBaseMap= widget_button(font=font, wExecBase, $
              value=gx_bitmap(gx_findfile('basemap.bmp')), $
              /bitmap,tooltip='Import BASE reference map',uname=prefix+'BASEMAP')                                 
   wCleanModel= widget_button(font=font, wExecBase, $
              value=gx_bitmap(gx_findfile('clean.bmp')), $
              /bitmap,tooltip='Clean unlocked components',uname=prefix+'CLEAN')

   wSaveModel= widget_button(font=font, wExecBase, $
              value=gx_bitmap(filepath('save.bmp', subdirectory=subdirectory)), $
              /bitmap,tooltip='Save this Model',uname=prefix+'SAVE')
   wRemoveModel= widget_button(font=font, wExecBase, $
              value=gx_bitmap(filepath('delete.bmp', subdirectory=subdirectory)), $
              /bitmap,tooltip='Remove this Model',uname=prefix+'REMOVE')
   ;xlabelsize=85
   xtextsize=10
   wDimensions=widget_base(self.wbase,/row)
   pbr=pb0r(self.subject->GetTime())*60
   if self.subject->IsCombo(csize=csz,bsize=sz) then begin
     wVolumeInfo = widget_label(font=font,wDimensions, $
       VALUE='['+self.subject->GetTime()+'] ' +string(sz[1],sz[2],sz[3],csz[3],xcoord_conv[1],xcoord_conv[1]*pbr[2],$
       format="('Dimension: [',i3,',',i3,',',i3,'(',i3,')] Resolution: ',g0,'R (',g0,' arcsec)')"))
   endif else begin
     wVolumeInfo = widget_label(font=font,wDimensions, $
       VALUE='['+self.subject->GetTime()+'] ' +string(sz[1],sz[2],sz[3],xcoord_conv[1],xcoord_conv[1]*pbr[2],$
       format="('Dimension: [',i3,',',i3,',',i3,'] Resolution: ',g0,'R (',g0,' arcsec)')"))
   endelse
  
   wSelectBase=widget_base(self.wBase,/row)   
   wBaseMapMenu=widget_button(font=font,wSelectBase,/menu,value='Reference Map Actions')
   wLOSMapImport=widget_button(font=font,wBaseMapMenu,value='Import LOS Reference Map',uname=prefix+'LOSMAP')
   wBaseMapImport=widget_button(font=font,wBaseMapMenu,value='Import BASE Reference Map',uname=prefix+'BASEMAP')
   wAll2Plotman=widget_button(font=font,wBaseMapMenu,value='Send All to Plotman',uname=prefix+'All2Plotman')
   wBaseMapUp=widget_button(font=font,wBaseMapMenu,value='Move Up',uname=prefix+'BaseMapUp',sensitive=0)
   wBaseMapRemove=widget_button(font=font,wBaseMapMenu,value='Remove',uname=prefix+'BaseMapRemove',sensitive=0)
   wBaseMap=widget_combobox(font=font,wSelectBase,value=['Bx','By','Bz'],/dynamic_resize,uname=prefix+'BaseMapSelect')
   widget_control,wBaseMap,set_combobox_select=2
   wHideBase=widget_base(self.wBase,/row,/nonexclusive)
   wHideModel=widget_button(font=font,wHideBase ,value=' Hide model',uname=prefix+'Hide')
   wHideMap=widget_button(font=font,wHideBase ,value=' Hide base map',uname=prefix+'HideMap')
   wHideMap=widget_button(font=font,wHideBase ,value=' Hide FOV map',uname=prefix+'HideFovMap')
   wHideROI=widget_button(font=font,wHideBase ,value=' Hide ROI box',uname=prefix+'HideRoi')
   
   wTopView=widget_button(font=font,wHideBase ,value=' Top View',uname=prefix+'TopView')
   wTopViewCorrection=widget_button(font=font,wHideBase ,value=' Top View Correction',uname=prefix+'TopViewCorrection',sensitive=0)
   
   wLocation=widget_base(self.wbase,/row)
   wEW=cw_objfield(wLocation, uname=prefix+'EW', LABEL=' EW',$
          XTEXTSIZE=10,$; XLABELSIZE=30,$
          INCREMENT=1, $
          UNITS=STRING(176b), $
          VALUE=EW,Sensitive=keyword_set(expert))
   wNS=cw_objfield(wLocation, uname=prefix+'NS', LABEL=' NS',$
          XTEXTSIZE=10,$ ; XLABELSIZE=30,$
          INCREMENT=1, $
          UNITS=STRING(176b), $
          VALUE=NS,Sensitive=keyword_set(expert))
   wGyro=cw_objfield(wLocation, uname=prefix+'GYRO', LABEL=' PHI',$
          XTEXTSIZE=10,$ ; XLABELSIZE=30,$
          INCREMENT=1, $
          UNITS=STRING(176b), $
          VALUE=gyro,Sensitive=keyword_set(expert))       
   wLineSteps=wLocation
   if keyword_set(expert) then begin
     wsteps=cw_objfield(wLineSteps, uname=prefix+'STEPS', LABEL=' Bline steps',$
            XTEXTSIZE=7,$ ; XLABELSIZE=80,$
            INCREMENT=1, $
            UNITS='', $
            VALUE=steps,Sensitive=1)
     wSubgridpts=cw_objfield(wLineSteps, uname=prefix+'SUBGRIDPTS', LABEL=' Subgrid steps',$
            XTEXTSIZE=7,$ ; XLABELSIZE=85,$
            INCREMENT=1, $
            UNITS='', $
            VALUE=subgridpts,Sensitive=1)
    end      
    if keyword_set(expert) and WinOS then begin
    wWinOS=cw_bgroup(font=font,wLocation,$
      ['use DLL (Win-OS only)'],$
      set_value=[winOS],$
      /nonexclusive,/return_index,uname=prefix+'WinOS')
    endif
    volume=self.subject->GetVolume()
    flags=volume->getflags()  
    
   if flags.hasBL then begin    
    if keyword_set(expert) then begin
      wVolumeBase=widget_base(self.wbase,/row,/frame)   
      
      wNTbase=widget_base(wVolumeBase,/column,/frame)
      wUseDEM=cw_bgroup(font=font,wNTbase,$
      ['Radio/Xray/EUV: stored n-T','EUV:EBTEL DEM, Radio/Xray:stored n-T','Radio/Xray/EUV: analytical EBTEL'],$
      set_value=ishft((flags.NTstored or ishft(flags.NTdem,1) or ishft(flags.NTss,2)),-1) ,$
      /exclusive,/return_index,/no_release,uname=prefix+'USEDEM')
      wUpdateNT=widget_button(font=font,wNTbase,value='Compute/Store n-T using EBTEL',uname=prefix+'COMPUTENT',sensitive=flags.newNT)
      
      wDemBase=widget_base(wVolumeBase,/column,/frame,map=flags.NTdem,uname='DEMBASE')
      wDemButtons=widget_base(wDemBase,/non,/column)
      wAddTR=widget_button(font=font,wDemButtons ,value='Add TR Contribution',uname=prefix+'ADDTR')
      widget_control,wAddTR,set_button=flags.TRadd
      wApplyTRmask=widget_button(font=font,wDemButtons ,value='Apply TR Mask',uname=prefix+'TRmask')
      widget_control,wApplyTRmask,set_button=flags.TRmask
      wSS=widget_button(font=font,wDemButtons ,value='Steady State EBTEL',uname=prefix+'SS')
      widget_control,wSS,set_button=flags.NTssdem
      wExpertButtons=widget_base(wDemBase,/column)
      wTRfactor=widget_button(font=font,widget_base(wExpertButtons,/non) ,value='Apply TR factor',uname=prefix+'TRfactor')
      widget_control,wTRfactor,set_button=flags.TRfactor     
    endif else begin
      wVolumeBase=widget_base(self.wbase,/row,/frame)
      
      wNTbase=widget_base(wVolumeBase,/column)
      wUseDEM=cw_bgroup(font=font,wNTbase,$
      ['Radio/Xray/EUV: stored n-T','EUV:EBTEL DEM, Radio/Xray:stored n-T'],$
      set_value=ishft((flags.NTstored or ishft(flags.NTdem,1)),-1) ,$
      /exclusive,/return_index,/no_release,uname=prefix+'USEDEM')
      wUpdateNT=widget_button(font=font,wNTbase,value='Compute/Store N-T from DEM',uname=prefix+'COMPUTENT',sensitive=flags.newNT)
      
      wDemBase=widget_base(wVolumeBase,/column,/frame,map=flags.NTdem,uname='DEMBASE')
      wDemButtons=widget_base(wDemBase,/non,/column)
      wAddTR=widget_button(font=font,wDemButtons ,value='Add TR Contribution',uname=prefix+'ADDTR')
      widget_control,wAddTR,set_button=flags.TRadd
      wApplyTRmask=widget_button(font=font,wDemButtons ,value='Apply TR Mask',uname=prefix+'TRmask')
      widget_control,wApplyTRmask,set_button=flags.TRmask
      wSS=widget_button(font=font,wDemButtons ,value='Steady State EBTEL',uname=prefix+'SS')
      widget_control,wSS,set_button=flags.NTssdem
    endelse
   endif 
   
  if keyword_set(expert) then begin
    if ~widget_valid(wVolumeBase) then wVolumeBase=widget_base(self.wbase,/row,/frame)
    wFlagBase=Widget_Base(wVolumeBase,/row,/frame,uname='gxflags')
    names=tag_names(flags)
    nflags=n_elements(names)
    nc=nflags/4
    button=lonarr(nflags)
    k=0
    for i=0, 3 do begin
      column=Widget_Base(wFlagbase,/nonexclusive,/column)
      for j=k,k+nc-1 do begin
        button[j]=widget_button(font=font,column,value=names[j],sensitive=0,uname=names[j])
        widget_control,button[j],set_button=flags.(j)
      endfor
      k+=nc
    endfor
  endif
   
   
   wComponentTab=WIDGET_TAB(self.wBase,font=font, /Align_Left,LOCATION=0,uname=prefix+'COMPONENTTAB')
   
   corona=self.subject->Get(/all,isa='gxcorona')
   if ~obj_valid(corona) then begin
    corona=obj_new('gxCorona',name='Corona')
    self.subject->add,corona
   endif
   if obj_valid(corona) then begin
     wCoronaPage=Widget_Base(wComponentTab, title='Volume Fillout')
     void=obj_new('gxWidget',wCoronaPage,corona)
     corona->UpdateVolume
   endif

   wControlPage=Widget_Base(wComponentTab, title='Volume Attributes')  
   wBase=widget_base(wControlPage,/column)
   wLabel=widget_label(font=font,widget_base(wBase,/row),value='Scaling Factors for Numerically Defined Coronal Parameters:')
   wScaleBase=widget_base(wBase,/row)
   wBscale=cw_ObjField(wScaleBase,value=10000,increment=1,label='Magnetic Field:',uname=prefix+'Bscale')
   if n_elements(bscale) eq 0 then begin
   widget_control,wBscale,set_value=1
   self.subject->SetProperty,bscale=1
   endif else widget_control,wBscale,set_value=bscale 
   
   
   volume->GetVertexAttributeData,'n',n
   
   if n_elements(n) ne 0 or flags.hasBL then begin
     volume->GetVertexAttributeData,'Nscale',Nscale
     wNscale=cw_ObjField(wScaleBase,value=10000,increment=1,label='Coronal Thermal Density:',uname=prefix+'Nscale')
     if n_elements(Nscale) eq 0 then begin
     widget_control,wNscale,set_value=1
     volume->SetVertexAttributeData,'Nscale',1
     endif else widget_control,wNscale,set_value=Nscale 
   end
   
   volume->GetVertexAttributeData,'T',T
   if n_elements(T) ne 0 or flags.hasBL then begin
     volume->GetVertexAttributeData,'Tscale',Tscale
     wTscale=cw_ObjField(wScaleBase,value=10000,increment=1,label='Coronal Temperature:',uname=prefix+'Tscale')
     if n_elements(Tscale) eq 0 then begin
     widget_control,wTscale,set_value=1
     volume->SetVertexAttributeData,'Tscale',1
     endif else widget_control,wTscale,set_value=Tscale
   end 
   
   if flags.hasBL  then begin
        
     volume->GetVertexAttributeData,'q0_coeff',q
     if n_elements(q) eq 0 then begin
       q=[0.415e-3,1e2,1e9,0,0]
       volume->SetVertexAttributeData,'q0_coeff',q
     end
     
     volume->GetVertexAttributeData,'q0_formula',q0_formula
     q0_formula=volume->SetQ0(q0_formula,q_formula=q_formula)    
  
     wParmBase=widget_base(wBase,/column,uname=prefix+'q_formula_base')
     wqBase=widget_base(wParmBase,/row,/frame)
     wq=cw_objArray( wqBase,uname=prefix+'q',xtextsize=5,format='(g0)',units='',value=[q],label='q',/frame)
     wqreset=widget_button(font=font, wqBase,value='Reset to default',uname=prefix+'q_reset')
     
     wq0FormulaBase=widget_base(wParmBase,/row,/frame)
     label=widget_label(font=font,wq0FormulaBase,value='     q0=  ')
     g=widget_info(wq,/geo)
     gl=widget_info(label,/geo)
     wq0f=widget_text(font=font,wq0FormulaBase,value=q0_formula,scr_xsize=g.scr_xsize-gl.scr_xsize,/edit,uname=prefix+'q0_formula')
     wq0freset=widget_button(font=font,wq0FormulaBase,value='Reset to default',uname=prefix+'q0_formula_reset')
     
     wqFormulaBase=widget_base(wParmBase,/row,/frame)
     label=widget_label(font=font,wqFormulaBase,value='     Q=  ',scr_xsize=gl.scr_xsize)
     
     wqf=widget_text(font=font,wqFormulaBase,value=q_formula,scr_xsize=g.scr_xsize-gl.scr_xsize,/edit,uname=prefix+'q_formula')
     wqfreset=widget_button(font=font,wqFormulaBase,value='Reset to default',uname=prefix+'q_formula_reset')
     

   endif 
   
    
    wPlotBase=widget_base(wbase,/row,uname=prefix+'ATTRIBUTEPLOTBASE')
    device, get_screen_size=scr
    ysize = fix (scr[0] * .25)
    xsize = ysize*(5./4)
    wAttributeplot=widget_draw( wPlotBase, $
        xsize=xsize, $
        ysize=ysize, $
        retain=2, $
        uvalue=[xSize,ySize], $
        uname=prefix+'AttributePlot') 
   wOptionBase=widget_base(wPlotBase,/column)  
   wAttributes=['Bx','By','Bz','B']
   xselect=4
   yselect=5
   if flags.hasBL or n_elements(n) gt 0 then wAttributes=[wAttributes,'Thermal Electron Density (cm^-3)','Temperature (K)']
   if flags.hasBL then begin
    wAttributes=[wAttributes,'Closed Loops Length (cm)','Closed Loops Heating Rate (Q)']
    wAttributes=[wAttributes,'alpha']
    wAttributes=[wAttributes,'q0']
    wAttributes=[wAttributes,'curlb']
   end 
   label=widget_label(font=font,wOptionBase,value='X Axis:',/align_left)
   wXAttribute=WIDGET_DROPLIST(font=font,wOptionBase,value=wAttributes,uname=prefix+'xAttribute')
   label=widget_label(font=font,wOptionBase,value='Y Axis:',/align_left)
   wYAttribute=WIDGET_DROPLIST(font=font,wOptionBase,value=wAttributes,uname=prefix+'yAttribute')
   wCheckBase=widget_base(wOptionBase,/column,/non)
   wRotateXY=widget_button(font=font,wCheckBase,value='Rotate XY',uname=prefix+'RotateXY')
   wHistogram=widget_button(font=font,wCheckBase,value='X Histogram',uname=prefix+'XHistogram')
   if ~flags.hasBL then xselect=4 else xselect=6
   if ~flags.hasBL  then yselect=5 else yselect=7
   if n_elements(wAttributes) le 4 then widget_control, wHistogram,/set_button
   widget_control,wXattribute,SET_DROPLIST_SELECT=xselect
   widget_control,wYattribute,SET_DROPLIST_SELECT=yselect
   wPlotOptions=cw_objPlotOptions(font=font,wOptionBase,uname=prefix+'AttributePlotOptions',/ylog,/xlog)            
  
  if flags.hasBL  then begin
   if keyword_set(expert) then begin
    for avgdem=0, 6 do begin
      dem_interpolate,avgdem=avgdem, method=method,/expert,/info
      buttons=n_elements(buttons) eq 0?method:[buttons,method]
    endfor
   endif else begin
    for avgdem=0, 3 do begin
      dem_interpolate,avgdem=avgdem, method=method,/info
      buttons=n_elements(buttons) eq 0?method:[buttons,method]
    endfor
   endelse
   wLabel=widget_label(wOptionBase,value='DEM Interpolation Method',font=font)
   wDEMinterpolate=cw_bgroup(font=font,wOptionBase,$
      buttons,$
      set_value=0 ,$
      /exclusive,/return_index,/no_release,uname=prefix+'DEMAVG')
   wLabel=widget_label(wOptionBase,value='',font=font,/dynamic,uname=prefix+'DEMDT',/Align_left)
   
   wTRPage=Widget_Base(wComponentTab, title='Transition Region Attributes')
   if !version.os_family eq 'Windows' then set_plot,'win' else set_plot,'x'
   device, get_screen_size=scr
   xsize = fix (scr[0] * .3)
   ysize = xsize
   frame=1
   wTRbase=Widget_Base(wTRPage,/row)
   wTRdraw= widget_draw(wTRBase, $
     xsize=XSIZE, $
     ysize=YSIZE, $
     uvalue=[xSize,ySize], $
     Uname=prefix+'TR Mask')
   wTRControllBase=Widget_Base(wTRbase,/column)
   label=widget_label(font=font,wTRControllBase,value='Transition Region Mask Settings')
   wTypeDisplayBase=widget_base(wTRControllBase,/row,/frame)
   label=widget_label(font=font,wTypeDisplayBase,value='TR MASK Type: ')
   g1=widget_info(wTRPage,/geo)
   g2=widget_info(wTRdraw,/geo)
   g3=widget_info(label,/geo)
   wTypeDisplay=widget_text(font=font,wTypeDisplayBase,value='',scr_xsize=(g2.scr_xsize-g3.scr_xsize)/2,uname=prefix+'TR_TypeDisplay')
   g4=widget_info(wTypeDisplay,/geo)
   wThresholdDisplayBase=widget_base(wTRControllBase,/row,/frame)
   label=widget_label(font=font,wThresholdDisplayBase,value='Threshold: ',scr_xsize=g3.scr_xsize)
   wTRThresholdDisplay=widget_text(font=font,wThresholdDisplayBase,value='',scr_xsize=g4.scr_xsize,uname=prefix+'TR_ThresholdDisplay')
   wTRMaskMenuBase=widget_base(wTRControllBase,/column,/frame)
   wTRMaskMenu=WIDGET_DROPLIST(font=font,wTRMaskMenuBase,value=['Replace Existing Transition Region Mask','Create Bz Mask', 'Create Bz/B Mask','Upload Custom Mask'],uname=prefix+'TRMaskMenu')
   g=widget_info(wTRMaskMenu,/geometry)
   widget_control,wTRMaskMenu,set_uvalue=g.scr_xsize
   self.subject->DisplayTRmask
  end 
  
   all=self.subject->Get(/all,count=count)
   tubes=0
   self.subject->SetProperty,FluxTubeCount=0
   for i=0, count -1 do begin
    case 1 of
     obj_isa(all[i],'gxfluxtube'):begin
            tubes+=1
            self.subject->SetProperty,FluxTubeCount=tubes
            name=string(tubes,format="('Flux Tube',i2)")
            all[i]->SetProperty,name=name
            wParent=Widget_Base(wComponentTab, title=name)
            void=obj_new('gxWidget',wParent,all[i],name=name)
            all[i]->DisplayB2B0ratio
            widget_control,wComponentTab,SET_TAB_CURRENT=widget_info(wComponentTab,/N_CHILDREN)-1
          end    
     else:        
    endcase
   endfor
  end
  
  obj_isa(self.subject,'gxfluxtube'):begin
    prefix='GXFLUXTUBE:'
    
    wToolbarBase = widget_base(self.wBase, /row, /frame,/TOOLBAR)
    self.subject->GetProperty,centerline=centerline,centerindex=centerindex,nrho=nrho,nphi=nphi,$
                             lock=lock,p_nth=p_nth,nr_nth=nr_nth,q_nth=q_nth,ns_nth=ns_nth,$
                             p_th=p_th,q_th=q_th,nr_th=nr_th,nz_th=nz_th,n_th=n_th,T0=T0,$
                             a=ra,b=rb,phi=phi,n_nth=n_nth,s0=s0,hide=hide,length=l
    centerline->GetProperty,data=line
    sz=size(line)
    wRemoveBase=widget_base(wToolbarBase,/toolbar,/row)
    wRemoveFluxTube= widget_button(font=font, wRemoveBase, $
            value=gx_bitmap(filepath('delete.bmp', subdirectory=subdirectory)), $
            /bitmap,tooltip='Remove this FluxTube',uname=prefix+'REMOVE',sensitive=~lock)
    wButtonBase=widget_base(wToolbarBase,/nonexclusive,/toolbar,/row)

    wLockFluxTube= widget_button(font=font, wButtonBase, $
            value=lock?gx_bitmap(gx_findfile('lock.bmp')):gx_bitmap(gx_findfile('unlock.bmp')), $
            /bitmap,tooltip='Lock this FluxTube',uname=prefix+'LOCK')
    widget_control,wLockFluxTube,set_button=lock
           
    wTab=widget_tab(font=font,self.wBase)
    wGeometry=widget_base(wTab,/column, title='Geometry')
    ;xlabelsize=200
    centerline->GetProperty,data=line,parent=parent
    p=line[*,centerindex] 
    centerline->GetVertexAttributeData,'s',s
    centerline->GetVertexAttributeData,'B',B  
    alpha=centerline->GetAlpha()   
    self.subject->GetProperty,parent=Model
    Model->GetProperty,Bscale=Bscale
    if n_elements(Bscale) ne 0 then B=B*Bscale       
    sz=size(line)
    l=abs(s[0]-s[sz[2]-1]) 
    l_min=min([s[0],s[sz[2]-1]])/l
    l_max=max([s[0],s[sz[2]-1]])/l
    label=widget_label(font=font,wGeometry,Value=strcompress(string(l,l*gx_rsun(),format="(' Cross section position along the central line(l=',f8.5,'R=',g10.4,'cm)')")),/align_center)              
    label=widget_label(font=font,/dynamic_resize,wGeometry,UNAME =prefix+ 'CENTERVALUE',value= $
    strcompress(string(p[0],p[1],p[2],s[centerindex],s[centerindex]*gx_rsun(),norm(b[*,centerindex]),alpha[centerindex],$
    format="('grid:[',i3,',',i3,',',i3,']; s=',f8.5,'R=',g11.4,'cm; B=',f10.3,'G ','alpha=',g10.3,'/cm')" )))
   
    wCenter= WIDGET_SLIDER(wGeometry, MINIMUM = 0, $
      MAXIMUM =sz[2]-1, VALUE = centerindex,  UNAME =prefix+ 'CENTER',/SUPPRESS_VALUE,font=font)
    
     
    tooltip=(ra eq rb)?'Switch to elliptical cross section':'Switch to circular cross section'
    wEllipse= widget_button(font=font, wButtonBase, $
            value=(ra eq rb)?gx_bitmap(filepath('eba_meth_noex_nocm.bmp', subdirectory=subdirectory)):$
            gx_bitmap(filepath('ellipse.bmp', subdirectory=subdirectory)), $
            /bitmap,tooltip=tooltip,uname=prefix+'E')  
    widget_control,wEllipse,set_button=(ra ne rb)
    
    tooltip=hide?'Show and Include this Fluxtube':'Hide and Exclude this Fluxtube'
    wHide= widget_button(font=font, wButtonBase, $
      value=~hide?gx_bitmap(filepath('image.bmp', subdirectory=subdirectory)):$
      gx_bitmap(filepath('eye_closed.bmp', subdirectory=subdirectory)), $
      /bitmap,tooltip=tooltip,uname=prefix+'HIDE')
    widget_control,wHide,set_button=hide
    
    centerline->GetProperty,hide=hidectrl
    tooltip=hidectrl?'Show fluxtube center line':'Hide fluxtube center line'
    wHideCTRL= widget_button(font=font, wButtonBase, $
              value=~hidectrl?gx_bitmap(filepath('image.bmp', subdirectory=subdirectory)):$
              gx_bitmap(filepath('eye_closed.bmp', subdirectory=subdirectory)), $
              /bitmap,tooltip=tooltip,uname=prefix+'HIDECTRL')  
    widget_control,wHideCTRL,set_button=hidectrl 
    
     
    (self.subject->GetByName('Top'))->GetProperty,hide=top_hide    
    
    tooltip=top_hide?'Show Bmin locus':'Hide Bmin locus'      
    wTop=widget_button(font=font, wButtonBase, $
              value=~top_hide?gx_bitmap(filepath('image.bmp', subdirectory=subdirectory)):$
              gx_bitmap(filepath('eye_closed.bmp', subdirectory=subdirectory)), $
              /bitmap,tooltip=tooltip,uname=prefix+'TOP')
    widget_control,wTop,set_button=1-top_hide                    
   
    xtextsize=7
   
    wCrossBase=widget_base(wGeometry,/row)
    wCrossBaseC1=widget_base(wCrossBase,/column)
    wCrossBaseC2=widget_base(wCrossBase,/column)
    wR=cw_objfield(wCrossBaseC1, UNAME=prefix+'R', LABEL='Cross section radius',$
        XTEXTSIZE=XTEXTSIZE, XLABELSIZE=XLABELSIZE,$
        INCREMENT=ra/10, $
        UNITS='gridpts', $
        VALUE=ra,Sensitive=1,map=ra eq rb)        
    wnrho=cw_objfield(wCrossBaseC1, UNAME=prefix+'NRHO', LABEL='Cross section radial grid points',$
        XTEXTSIZE=XTEXTSIZE, XLABELSIZE=XLABELSIZE,$
        INCREMENT=1, $
        UNITS='', $
        VALUE=nrho,Sensitive=1)
    wnphi=cw_objfield(wCrossBaseC1, UNAME=prefix+'NPHI', LABEL='Cross section polar grid points',$
        XTEXTSIZE=XTEXTSIZE, XLABELSIZE=XLABELSIZE,$
        INCREMENT=1, $
        UNITS='', $
        VALUE=nphi,Sensitive=1)
    ;xlabelsize=150
    wa=cw_objfield(wCrossBaseC2, UNAME=prefix+'a', LABEL='Cross section a semiaxis',$
        XTEXTSIZE=XTEXTSIZE, XLABELSIZE=XLABELSIZE,$
        INCREMENT=ra/10, $
        UNITS='gridpts', $
        VALUE=ra,map=(ra  ne rb))
    wb=cw_objfield(wCrossBaseC2, UNAME=prefix+'b', LABEL='Cross section b semiaxis',$
        XTEXTSIZE=XTEXTSIZE, XLABELSIZE=XLABELSIZE,$
        INCREMENT=rb/10, $
        UNITS='gridpts', $
        VALUE=rb,map=(ra ne rb))
    wphi=cw_objfield(wCrossBaseC2, UNAME=prefix+'phi', LABEL='Ellipse rotation angle',$
        XTEXTSIZE=XTEXTSIZE, XLABELSIZE=XLABELSIZE,$
        INCREMENT=1, $
        UNITS=STRING(176b), $
        VALUE=phi,map=1) 
   xsize=fix(550*xscale)
   ysize=2*fix(220*xscale)     
   wDraw=widget_draw(wGeometry,xsize=xsize,ysize=ysize,uname=prefix+'draw_clg') 
   label=widget_label(font=font,/dynamic_resize,wGeometry,UNAME =prefix+ 's0value',value=string(s0,format='(g0)'))
   ws0= Widget_SLIDER(wGeometry, MINIMUM = 0, $
      MAXIMUM =sz[2]-1, VALUE = centerindex,  UNAME =prefix+ 's0',/SUPPRESS_VALUE,font=font)
       
  ;THERMAL ELECTRON DISTRIBUTION      
      wThermalTab=widget_base(wTab,/column,title='Thermal electron distribution',uname=prefix+'TH')  
      self.subject->SelectThermalModel
       
             
 ;NONTHERMAL ELECTRON DISTRIBUTION         
      wNdistribution=widget_base(wTab,/column,title='Nonthermal electron distribution')  
      wParmBase=widget_base(wNdistribution,/column,/frame)
      wp=cw_objArray(wParmBase,uname=prefix+'p_nth',xtextsize=5,format='(g0)',units='',$
      value=p_nth,label='p',/frame)
      wq=cw_objArray(wParmBase,uname=prefix+'q_nth',xtextsize=5,format='(g0)',units='',$
      value=q_nth,label='q',/frame) 
      wbase=widget_base(wParmBase,/row,/frame)
      wn_nth=cw_objfield(wBase, UNAME=prefix+'n_nth', LABEL='nb=',$
        INCREMENT=1e7, $
        UNITS='cm^-3', $
        VALUE=n_nth,map=1,/frame) 
      ws02l=cw_objfield(wBase, UNAME=prefix+'s0/l', LABEL='s0/l=',$
        INCREMENT=0.1, $
        UNITS='', $
        VALUE=s0/l,map=1,/frame,xtextsize=10,min=l_min,max=l_max)    
      text=widget_label(font=font,wbase,value='         n(x,y,s)=nb*nr(x,y)*ns(s)')   
      wnr=cw_field(wNdistribution,/string,value=nr_nth,title='nr=',/return,xsize=73,uname=prefix+'nr_nth',/frame,font=font,fieldfont=font)
      wns=cw_field(wNdistribution,/string,value=ns_nth,title='ns=',/return,xsize=73,uname=prefix+'ns_nth',/frame,font=font,fieldfont=font)
      g=widget_info(wns,/geometry)
      xsize=g.xsize
      ysize=xsize*200/550
      wDraw=widget_draw(wNdistribution,xsize=xsize,ysize=ysize,uname=prefix+'draw_nth')
      xtextsize=18
      wn_chromo=widget_base(wNDistribution,/row,/frame)
      wlabel=widget_label(wn_chromo,font=font,value='Chromo Volume: ')
      wn_nth_total_chromo=cw_objfield(wn_chromo, font=font,UNAME=prefix+'nb_total_chromo', LABEL='Sum(nbdv)=',$
        INCREMENT=1e7, $
        UNITS='', $
        xtextsize=xtextsize,$
        VALUE=0,/frame,/indicator)
      wn2_nth_total_chromo=cw_objfield(wn_chromo,font=font, UNAME=prefix+'nb^2_total_chromo', LABEL='Sum(nb^2dv)=',$
        INCREMENT=1e7, $
        UNITS='cm^-3', $
        xtextsize=xtextsize,$
        VALUE=0,/frame,/indicator)
      wn_corona=widget_base(wNDistribution,/row,/frame)
      wlabel=widget_label(wn_corona,font=font,value='Coronal Volume:')
      wn_nth_total_corona=cw_objfield(wn_corona, font=font,UNAME=prefix+'nb_total_corona', LABEL='Sum(nbdv)=',$
        INCREMENT=1e7, $
        UNITS='', $
        xtextsize=xtextsize,$
        VALUE=0,/frame,/indicator)
      wn2_nth_total_corona=cw_objfield(wn_corona,font=font, UNAME=prefix+'nb^2_total_corona', LABEL='Sum(nb^2dv)=',$
        INCREMENT=1e7, $
        UNITS='cm^-3', $
        xtextsize=xtextsize,$
        VALUE=0,/frame,/indicator)
      wn_total=widget_base(wNDistribution,/row,/frame)
      wlabel=widget_label(wn_total,font=font,value='Total Volume:  ')
      wn_nth_total=cw_objfield(wn_total, font=font,UNAME=prefix+'nb_total', LABEL='Sum(nbdv)=',$
        INCREMENT=1e7, $
        UNITS='', $
        xtextsize=xtextsize,$
        VALUE=0,/frame,/indicator)
      wn2_nth_total=cw_objfield(wn_total,font=font, UNAME=prefix+'nb^2_total', LABEL='Sum(nb^2dv)=',$
        INCREMENT=1e7, $
        UNITS='cm^-3', $
        xtextsize=xtextsize,$
        VALUE=0,/frame,/indicator)
      
  ;ELECTRON DISTRIBUTION OVER ENERGY      
      wEdistributionBase=widget_base(wTab,/column,title='Electron energy distribution')
      wEdistribution=widget_base(wEdistributionBase,/column,uname=prefix+'Ebase')   
      select_str=[$
      'free-free only (FFO)',$
      'thermal (THM)',$
      'single power law over kinetic energy (PLW)',$
      'double power law over kinetic energy (DPL)',$
      'thermal/nonthermal over kinetic energy (TNT)',$
      'kappa (KAP)',$
      'power law over the absolute value of momentum (PLP)',$
      'power law over the Lorentz factor (PLG)',$
      'thermal/nonthermal over the absolute value of momentum (TNP)',$
      'thermal/nonthermal over the Lorentz factor (TNG)',$
      'thermal+ single power law over kinetic energy (TPL)',$
      'thermal+ double power law over kinetic energy (TDP)']
      wEnergySelectBase=widget_base(wEdistribution,/row)   
      wEnergySelect=widget_combobox(font=font,wEnergySelectBase,value=select_str,/dynamic_resize,uname=prefix+'E_Select')
      
      xsize=fix(550*xscale)
      ysize=fix(220*xscale)
      
      wDraw=widget_draw(wEdistribution,xsize=xsize,ysize=ysize,uname=prefix+'draw_e')  
      wParmBase=widget_base(wEdistribution,/column,uname=prefix+'parm_e')   
      self.subject->SelectEnergyDistribution
   ;ELECTRON DISTRIBUTION OVER PITCH-ANGLE     
      wPAdistributionBase=widget_base(wTab,/column,title='Pitch-angle distribution')
      wPAdistribution=widget_base(wPAdistributionBase,/column,uname=prefix+'PAbase')   
      select_str=[$
      'isotropic* (ISO)',$
      'isotropic (ISO)',$
      'exponential loss-cone (ELC)',$
      'Gaussian loss-cone (GLC)',$
      'Gaussian (GAU)',$
      'super-Gaussian (SGA)']
      wPASelectBase=widget_base(wPAdistribution,/row)   
      wPASelect=widget_combobox(font=font,wPASelectBase,value=select_str,/dynamic_resize,uname=prefix+'PA_Select')
      
      xsize=fix(550*xscale)
      ysize=fix(220*xscale)
      wDraw=widget_draw(wPAdistribution,xsize=xsize,ysize=ysize,uname=prefix+'draw_pa')  
      label=widget_label(font=font,/dynamic_resize,wPAdistribution,UNAME =prefix+ 'svalue',value=string(s0/l,format='("s/l=",g0)'))
      ws= Widget_SLIDER(wPAdistribution, MINIMUM = 0, $
      MAXIMUM =sz[2]-1, VALUE = centerindex,  UNAME =prefix+ 's',/SUPPRESS_VALUE,font=font)
      label=widget_label(font=font,/dynamic_resize,wPAdistribution,UNAME =prefix+ 's0value_duplicate',value=string(s0/l,format='("s0/l=",g0)'))
      ws0= Widget_SLIDER(wPAdistribution, MINIMUM = 0, $
      MAXIMUM =sz[2]-1, VALUE = centerindex,  UNAME =prefix+ 's0_duplicate',/SUPPRESS_VALUE,font=font)
      wParmBase=widget_base(wPAdistribution,/column,uname=prefix+'parm_pa')   
      self.subject->SelectPADistribution  
   end
   obj_isa(self.subject,'gxCORONA'):begin
    prefix='GXCORONA:'
    xtextsize=12
    ;xlabelsize=40
    self.subject->GetProperty,xcoord_conv=xcoord_conv,data0=data0,n0=n0,T0=T0,p=parm_p,n_th=n_th,dist_e=dist_e,kappa=kappa,$
    emin=emin,emax=emax,chromo_n=chromo_n,chromo_T=chromo_T,chromo_h=chromo_h,chromo_view=chromo_view,blend=blend,ignore=ignore,parent=parent                     
    ;wDimensions=widget_base(self.wbase,/row)
    sz=size(data0) 
    wLabel=widget_label(font=font,  self.wbase,value='Corona',/align_left)                    
    wNdistribution=widget_base(self.wbase,/column,title='Density distribution')  
       
      wParmBase=widget_base(wNdistribution,/row)
      wn_th=cw_objfield(wParmBase, UNAME=prefix+'n0', LABEL='n0=',$
        INCREMENT=1e7, $
        UNITS='cm^-3', $
        VALUE=n0,map=1,/frame) 
      wT0=cw_objfield(wParmBase, UNAME=prefix+'T0', LABEL='T0=',$
        INCREMENT=1, $
        UNITS='K', $
        VALUE=T0,map=1,/frame,XTEXTSIZE=10)   
      wp=cw_objArray(wParmBase,uname=prefix+'p',xtextsize=5,format='(g0)',units='',$
      value=parm_p,label='p',lfont=lfont,/frame)   
      wn_th=cw_field(wNdistribution,/string,value=n_th,title='n(z)=',/return,xsize=60,uname=prefix+'n_th',font=font,fieldfont=font,/frame)
;      xsize=fix(450*xscale)
;      ysize=fix(450*xscale)
      xsize=fix(800*xscale)
      ysize=fix(400*xscale)
      wdraw=widget_draw(wNdistribution,xsize=xsize,ysize=ysize,uname=prefix+'draw')  
      wEnergySelectBase=widget_base(wNdistribution,/row,/toolbar)
      wEnergySelect=widget_combobox(font=font,wEnergySelectBase,value=['free-free only (FFO)','thermal (THM)','kappa (KAP)'],/dynamic_resize,uname=prefix+'E_Select') 
      wBlendBase=widget_base(wEnergySelectBase,/nonexclusive,/row)
      wIgnore=widget_button(font=font,wBlendBase, UNAME=prefix+'Ignore',value='Ignore Analytical Corona',tooltip='Do not use analytical corona to fill empty voxels')
      widget_control,wIgnore,set_button=keyword_set(ignore)
      if keyword_set(expert) then begin
        wBlend=widget_button(font=font,wBlendBase, UNAME=prefix+'Blend',value='Blend Analytical with Numerical',tooltip='Blend or Replace Analytical Coronal Model by Numerical Model')
        widget_control,wBlend,set_button=keyword_set(blend)
      end 
      wParms=widget_base(wNdistribution,/row)
      wEmin=cw_objfield(wParms, UNAME=prefix+'Emin', LABEL='Emin=',$
        INCREMENT=1, $
        UNITS='MeV', $
        VALUE=Emin,map=1,/frame,XTEXTSIZE=XTEXTSIZE,xlabelsize=xlabelsize,lfont=lfont)
      wEmax=cw_objfield(wParms, UNAME=prefix+'Emax', LABEL='Emax=',$
        INCREMENT=1, $
        UNITS='MeV', $
        VALUE=Emax,map=1,/frame,XTEXTSIZE=XTEXTSIZE,xlabelsize=xlabelsize,lfont=lfont)  
      wkappa=cw_objfield(wParms, UNAME=prefix+'kappa', LABEL='kappa=',$
        INCREMENT=0.1, $
        UNITS='', $
        VALUE=kappa,map=0,/frame,XTEXTSIZE=XTEXTSIZE,xlabelsize=xlabelsize,lfont=lfont)  
     wChromoBase=widget_base(wNdistribution,/column,/frame)
     wChromoToolbar=widget_base(wChromoBase,/toolbar,/row) 
     wLabel=widget_label(font=font, wChromoToolbar,value='Chromosphere')  
     wButtonBase=widget_base(wChromoToolbar,/nonexclusive,/toolbar)
     wShowChromo= widget_button(font=font, wButtonBase, $
              value=chromo_view?gx_bitmap(filepath('image.bmp', subdirectory=subdirectory)):$
              gx_bitmap(filepath('eye_closed.bmp', subdirectory=subdirectory)), $
              /bitmap,tooltip='Show chromosphere',uname=prefix+'chromo_view')   
     not_combo=~(parent->IsCombo())  
     if not_combo then begin      
     wChromoParms=widget_base(wChromoBase,/row,/frame,map=not_combo)  
     wnc=cw_objfield(wChromoParms, UNAME=prefix+'chromo_n', LABEL='n0=',$
        INCREMENT=1, $
        UNITS='cm^-3', $
        VALUE=chromo_n,map=not_combo,/frame,XTEXTSIZE=XTEXTSIZE,xlabelsize=xlabelsize,lfont=lfont)
     wTc=cw_objfield(wChromoParms, UNAME=prefix+'chromo_T', LABEL='T0=',$
        INCREMENT=1, $
        UNITS='K', $
        VALUE=chromo_T,map=not_combo,/frame,XTEXTSIZE=XTEXTSIZE,xlabelsize=xlabelsize,lfont=lfont)  
     wHc=cw_objfield(wChromoParms, UNAME=prefix+'chromo_h', LABEL='h=',$
        INCREMENT=1000, $
        UNITS='km', $
        VALUE=chromo_h*gx_rsun(unit='km'),map=not_combo,/frame,XTEXTSIZE=XTEXTSIZE,xlabelsize=xlabelsize,lfont=lfont) 
     end           
   end 

 else:
 endcase
end
;----------------------------------------------------------------------
function gxWidget::HandleEvent, event
subdirectory=['resource', 'bitmaps']
CASE TAG_NAMES(event, /STRUCTURE_NAME) OF
'GXREMOVEFLUXTUBEEVENT':BEGIN
                          if dialog_message('Do you want to destroy this fluxtube?',/question) eq 'Yes' then begin
                             widget_control,widget_info(event.id,/child),get_uvalue=gxWidget
                             obj_destroy, gxWidget
                          end
                        END                     
else:
ENDCASE
compile_opt hidden
catch, error_stat
if error_stat ne 0 then begin
  catch, /cancel
  answ=dialog_message(!ERROR_STATE.MSG+' Please report this bug to gnita@njit.edu. Thank you!')
  return, self->Rewrite(event)
end
 if widget_valid(event.id) then begin
   case strupcase(widget_info(event.id,/uname)) of
     ;----------------gxMapContainer-----------------
     'GXMAPCONTAINER:SELECT':begin
                              widget_control,event.id,get_uvalue=uvalue,get_value=value
                              uvalue.omap->plotman,uvalue.k,plotman_obj=uvalue.plotman,/use_colors,nodup=0,desc=value
                              widget_control,get_tlb(event.id),get_uvalue=state
                              if isa(state,'STRUCT') then begin
                               if tag_exist(state,'widgets') then if tag_exist(state.widgets,'w_message') then $
                                  widget_control,state.widgets.w_message,set_value=value
                              endif
                             end
     'GXMAPCONTAINER:REMOVE':begin
                              widget_control,event.id,get_uvalue=uvalue
                              self.subject->Remove,uvalue.omap
                              obj_destroy,uvalue.omap
                              widget_control,uvalue.button,/destroy
                             end  
     'GXMAPCONTAINER:SETCOLOR':begin
                                widget_control,event.id,get_uvalue=group
                                 tvlct,rgb_curr,/get
                                 xloadct,/silent,/block,file=loc_file(path=path_dir('plotman'), 'plotman_colors_hessi.tbl')
                                 count=group.omap->get(/count)
                                 for k=0,count-1 do group.omap->save_ct,k  
                                 group.plotman->select
                                 panel_struct=group.plotman->get(/current_panel_struct)
                                 omap=(*panel_struct.saved_data.data)
                                 for k=0,count-1 do begin
                                  if group.omap->get(k,/id) eq omap->get(/id) then matched_k=k
                                 end 
                                 if n_elements(matched_k) ne 0 then begin
                                  group.plotman->delete_panel,/current
                                  group.omap->plotman,matched_k,plotman_obj=group.plotman,/use_colors,nodup=0
                                 end
                                 tvlct,rgb_curr    
                               end    
     'GXMAPCONTAINER:SAVE':begin
                            widget_control,event.id,get_uvalue=group
                            widget_control,widget_info(event.id,/parent),get_value=file
                            file=strcompress(strjoin(strsplit(strjoin(strsplit(file+group.omap->get(/time),':',/extract)),'.',/extract)))
                             catch, error_stat
                             if error_stat ne 0 then begin
                                catch, /cancel
                                MESSAGE, /INFO, !ERROR_STATE.MSG
                                file='*'
                             end
                            file=dialog_pickfile(filter='*.map',$
                                 DEFAULT_EXTENSION='map',$
                                 /write,/OVERWRITE_PROMPT,$
                                 file=file,$
                                 title='Please select a file to save this MAP object') 
                            if file ne '' then begin
                             map=group.omap
                             save,map,file=file
                            end       
                           end     
                           
    'GXMAPCONTAINER:IMPORTFITS':begin
                                 file=dialog_pickfile(title='Please select a fits file',filter=['*.f*'],path=gx_findfile(folder='demo'),/must_exist)
                                 if file eq '' then return,self->Rewrite(event)
                                 widget_control,event.id,get_uvalue=proc
                                 gx_fits2map,file,map
                                 if n_elements(map) eq 0 then begin
                                   answ=dialog_message('Invalid file content!',/error)
                                   return,self->Rewrite(event)
                                 end
                                 map=map[0]
                                 if map.id eq '' then begin
                                   break_file, file, dsk_log, dir, filename, ext
                                   map.id=filename
                                 end
                                 map=make_map(map.data,xc=map.xc,yc=map.yc,dx=map.dx,dy=map.dy,time=map.time,id=map.id)
                                 goto,getmap
                               end
    
     'GXMAPCONTAINER:IMPORTMAP':begin
                                 file=dialog_pickfile(title='Please select a file containing an IDL map structure',filter=['*.sav','*.map'],path=gx_findfile(folder='demo'),/must_exist)
                                 if file eq '' then return,self->Rewrite(event)
                                 osav=obj_new('idl_savefile',file)
                                 names=osav->names()
                                 valid=0
                                 for i=0,n_elements(names)-1 do begin
                                   osav->restore,names[i]
                                   e=execute('result=size('+names[i]+',/tname)')
                                   if (result eq 'STRUCT') or (result eq 'OBJREF') then begin
                                     e=execute('m=temporary('+names[i]+')')
                                     if valid_map(m) then map=temporary(m)
                                   endif
                                 endfor
                                 ;restore,file,/RELAXED_STRUCTURE_ASSIGNMENT
                                 getmap:
                                 break_file, file, dsk_log, dir, filename, ext
                                 widget_control,/hourglass
                                 if ~(size(map,/tname) eq 'STRUCT' or size(map,/tname) eq 'OBJREF') then begin
                                   answ=dialog_message('Unexpected file content!',/error)
                                   return,self->Rewrite(event)
                                 endif else begin
                                   if size(map,/tname) eq 'STRUCT' then begin
                                     omap=obj_new('map')
                                     for k=0,n_elements(map)-1 do begin
                                       omap->setmap,k,map[k]
                                     endfor
                                   endif else omap=map
                                   if omap->get(/count) gt 1 then begin
                                     self.subject->Add,omap,filename
                                   endif else begin
                                     omap->plotman,0,plotman_obj=self->GetPlotmanObj(),nodup=0
                                     obj_destroy,omap
                                   end
                                 endelse
                           end                                                                                     
     ;----------------gxCorona-------------------------------------------------------------
     
     'GXCORONA:N0':Begin
                         widget_control,event.id,get_value=n0
                         self.subject->SetProperty,n0=n0
                         self.subject->UpdateVolume
                        End 
     'GXCORONA:T0':Begin
                         widget_control,event.id,get_value=T0
                         self.subject->SetProperty,T0=T0
                         self.subject->UpdateVolume
                        End    
     'GXCORONA:N_TH':Begin
                     widget_control,event.id,get_value=n_th
                     self.subject->SetProperty,n_th=n_th
                     self.subject->UpdateVolume
                    End  
     'GXCORONA:P':Begin
                     widget_control,event.id,get_value=p
                     self.subject->SetProperty,p=p
                     self.subject->UpdateVolume
                    End  
     'GXCORONA:E_SELECT':Begin
                      case event.index of
                       0:dist_e=1
                       1:dist_e=2
                       else:dist_e=6
                      end
                      self.subject->SetProperty,dist_e=dist_e
                      self.subject->UpdateVolume
                      self.subject->GetProperty,wParent=wParent
                      widget_control,widget_info(wParent,find_by_uname='GXCORONA:kappa'),map=(dist_e eq 6)
                    End  
     'GXCORONA:EMIN':Begin
                       widget_control,event.id,get_value=emin
                       self.subject->SetProperty,emin=emin
                       self.subject->UpdateVolume
                    End
     'GXCORONA:EMAX':Begin
                       widget_control,event.id,get_value=emax
                       self.subject->SetProperty,emax=emax
                       self.subject->UpdateVolume
                    End 
     'GXCORONA:KAPPA':Begin
                       widget_control,event.id,get_value=kappa
                       self.subject->SetProperty,kappa=kappa
                       self.subject->UpdateVolume
                    End
     'GXCORONA:CHROMO_N':Begin
                       widget_control,event.id,get_value=chromo_n
                       self.subject->SetProperty,chromo_n=chromo_n
                       self.subject->UpdateVolume
                    End
     'GXCORONA:CHROMO_T':Begin
                       widget_control,event.id,get_value=chromo_T
                       self.subject->SetProperty,chromo_T=chromo_T
                       self.subject->UpdateVolume
                    End  
     'GXCORONA:CHROMO_H':Begin
                       widget_control,event.id,get_value=chromo_h
                       chromo_h=chromo_h/gx_rsun(unit='km')
                       self.subject->SetProperty,chromo_h=chromo_h
                       self.subject->UpdateVolume,/newID
                    End 
     'GXCORONA:CHROMO_VIEW':Begin
                       ; Set the button state if called manually.
                       if (WIDGET_INFO(event.id, /BUTTON_SET) ne event.select) then $
                       WIDGET_CONTROL, event.id, SET_BUTTON=event.select
                       self.subject->SetProperty,chromo_view=event.select
                       self.subject->GetProperty,chromo_view=chromo_view
                       tooltip=chromo_view?'Hide Chromosphere':'Show Chromosphere'
                       WIDGET_CONTROL, event.id,/bitmap,tooltip=tooltip,set_value=chromo_view?$
                        gx_bitmap(filepath('image.bmp', subdirectory=subdirectory)):$
                        gx_bitmap(filepath('eye_closed.bmp', subdirectory=subdirectory))
                        self.subject->UpdateVolume
                    End 
     'GXCORONA:BLEND':BEGIN
                        self.subject->SetProperty,blend=event.select
                        self.subject->UpdateVolume
                       END  
     'GXCORONA:IGNORE':BEGIN
                         self.subject->SetProperty,ignore=event.select
                         self.subject->UpdateVolume
                       END                                                                                                                                                                                       
     ;---------------- gxModel-------------------------------------------------------------
     'GXMODEL:HIDE':BEGIN
                        self.subject->SetProperty,hide=event.select
                       END
     'GXMODEL:HIDEMAP':BEGIN
                        map=(self.subject->GetByName('Reference Map'))
                        if obj_isa(map,'idlgrimage') then map->SetProperty,ALPHA_CHANNEL=1-event.select,BLEND_FUNCTION = [3, 4]
                       END
     'GXMODEL:HIDEFOVMAP':BEGIN
                         ((self.subject->scanbox())->GetFOVscreen())->SetProperty,hide=event.select
                       END                 
     'GXMODEL:HIDEROI':BEGIN
                         ROI=self.subject->GetROI()
                         if obj_isa(roi,'idlgrroi') then roi->SetProperty,hide=event.select
                       END 
     'GXMODEL:ISROI':BEGIN
                 IsROI=event.select
                 self.subject->SetProperty,IsROI=IsROI
                 return, {GXMODELSELECTEVENT,id: self.wIDBase, top: event.top, handler:0L,model:IsROI?self.subject:obj_new()}
               END
     'GXMODEL:FULLROI':BEGIN
                ; Set the button state if called manually.
                 if (WIDGET_INFO(event.id, /BUTTON_SET) ne event.select) then $
                 WIDGET_CONTROL, event.id, SET_BUTTON=event.select
                 self.subject->SetProperty,FullROI=event.select
                 self.subject->SetRoi
                 return,{GXSCANBOXEVENT,id: self.wIDBase, top: event.top, handler:0L,$
                  auto:widget_info(widget_info(event.top,find_by_uname='Auto FOV'),/button_set)}
               END
     'GXMODEL:MODELVIEW':BEGIN
                     widget_control,widget_info(event.handler,find_by_uname='GXMODEL:REMOVE'),sensitive=1-event.select
                     return,{gxZoomInModelEvent,id: self.wIDBase, top: event.top, handler:0L,select:event.select}
                    END
     'GXMODEL:EW': BEGIN
               widget_control,event.id,get_value=value
               self.subject->SetProperty,EW=value
               self.subject->ResetPosition
              END
     'GXMODEL:NS': Begin
                widget_control,event.id,get_value=value
                self.subject->SetProperty,NS=value
                self.subject->ResetPosition
              END         
     'GXMODEL:GYRO': BEGIN
                widget_control,event.id,get_value=value
                self.subject->SetProperty,gyro=value
                self.subject->ResetPosition
              END         
     'GXMODEL:TOPVIEW': BEGIN
               TopView=widget_info(event.id,/button_set)
               self.subject->ResetPosition
               self.subject->GetProperty,wparent=wparent
               wTopViewCorrection=widget_info(wparent,find_by_uname='GXMODEL:TopViewCorrection')
               widget_control,wTopViewCorrection,set_button=0
               widget_control,wTopViewCorrection,sensitive=TopView
              END         
     'GXMODEL:STEPS': BEGIN
               widget_control,event.id,get_value=value
               self.subject->SetProperty,steps=value
              END
     'GXMODEL:SUBGRIDPTS': BEGIN
               widget_control,event.id,get_value=value
               self.subject->SetProperty,subgridpts=value
              END
     'GXMODEL:WINOS': BEGIN
                widget_control,event.id,get_value=value
                self.subject->SetProperty,winos=value[0]
              END         
    'GXMODEL:LINESFROMSEEDS':begin
                              model=self.subject
                              sz=model->Size()
                              self.subject->AddBLines,x0=sz[1]/2.,y0=sz[2]/2.,z0=0,dx=10,dy=10,dz=1,nx=sz[1]/10,ny=sz[2]/10,nz=1
                            end 
        
    'GXMODEL:IMPORTSEEDS':Begin
                            file=dialog_pickfile(filter='*.sav',$
                                 DEFAULT_EXTENSION='sav',$
                                 /read,/must_exist,$
                                 title='Please select a file to upload an input magnetic field seed array for this model')
                            if file ne '' then begin
                            osav=obj_new('idl_savefile',file)
                            names=osav->names()
                            for i=0,n_elements(names)-1 do begin
                             osav->restore,names[i]
                             e=execute('result=n_elements('+names[i]+')/3')
                             if result ge 1 then begin
                              e=execute('inputSeeds=temporary('+names[i]+')')
                              dim=size(inputSeeds,/dim)
                              if n_elements(dim) eq 2 and dim[0] eq 3 then begin
                                found=1
                                self.subject->GetProperty,winOS=winOS
                                if winOS then begin
                                  lines=self.subject->ComputeBlines(inputSeeds)
                                  good=where(obj_valid(lines) eq 1,count)
                                  if count gt 0 then self.subject->add,lines[good]
                                endif else begin
                                  for i=0, nSeeds-1 do self.subject->CreateBline,InputSeeds[*,i],/any
                                endelse
                              endif
                             endif
                            endfor
                           endif   
                           if n_elements(found) eq 0 then answ=dialog_message('No valid InputSeeds variable found in this file!',/info)                     
                         End 
     'GXMODEL:LOSMAP':Begin
                            files=dialog_pickfile(title='Please select one more more files containg maps saved as IDL map structure, IDL objects, or fits',filter=['*.sav','*.map','*.f*s'],/must_exist,/multiple)
                            files=files[sort(files)]
                            FOR idx=0, n_elements(files)-1 DO BEGIN
                              file=files[idx]
                              if file ne '' then begin
                                catch, error_stat
                                if error_stat ne 0 then begin
                                  catch, /cancel
                                  gx_fits2map,file,map
                                  goto, got_a_map
                                end
                                osav=obj_new('idl_savefile',file)
                                names=osav->names()
                                valid=0
                                for i=0,n_elements(names)-1 do begin
                                  osav->restore,names[i];,/RELAXED_STRUCTURE_ASSIGNMENT
                                  e=execute('result=size('+names[i]+',/tname)')
                                  if (result eq 'STRUCT') or (result eq 'OBJREF') then begin
                                    e=execute('m=temporary('+names[i]+')')
                                    if valid_map(m) then map=temporary(m)
                                  endif
                                endfor
                              got_a_map:  
                              if ~(size(map,/tname) eq 'STRUCT' or size(map,/tname) eq 'OBJREF') then begin
                               answ=dialog_message('Unexpected file content!',/error)
                              endif else begin
                               edge=[-10,10]
                               for i=0, n_elements(map)-1 do begin
                                 sub_map,map[i],amap,xrange=edge+((self.subject->GetFovMap())->get(/xrange)),yrange=edge+((self.subject->GetFovMap())->get(/yrange))
                                 self.subject->AddMap,amap,id=id
                                 if n_elements(id) gt 0 then begin
                                   wBaseSelect=widget_info(self.wBase,find_by_uname='GXMODEL:BaseMapSelect')
                                   widget_control,wBaseSelect,Get_Value=items
                                   nitems=n_elements(items)
                                   for k=0, n_elements(id)-1 do widget_control,wBaseSelect,COMBOBOX_ADDITEM=id[k]
                                   widget_control,wBaseSelect,SET_COMBOBOX_SELECT=nitems
                                   self.subject->DisplayMap,nitems
                                 end
                                end 
                              end 
                              end
                              nitems=widget_info(widget_info(self.wBase,find_by_uname='GXMODEL:BaseMapSelect'),/COMBOBOX_NUMBER)
                              widget_control,widget_info(self.wBase,find_by_uname='GXMODEL:BaseMapRemove'),sensitive=(nitems gt 3)
                              widget_control,widget_info(self.wBase,find_by_uname='GXMODEL:BaseMapUp'),sensitive=(nitems gt 3)
                           ENDFOR  
                         End   
      'GXMODEL:BASEMAP':Begin
                           files=dialog_pickfile(title='Please select one or more map fits files',filter=['*.f*s'],/must_exist,/multiple)
                           files=files[sort(files)]
                           FOR idx=0, n_elements(files)-1 DO BEGIN
                             file=files[idx]
                             if file ne '' then begin
                                gx_los2base,self.subject->GetBaseIndex(),file,basemap,pixel=pixel
                                if valid_map(basemap) then self.subject->AddMap,basemap,id=id
                                 if n_elements(id) gt 0 then begin
                                   wBaseSelect=widget_info(self.wBase,find_by_uname='GXMODEL:BaseMapSelect')
                                   widget_control,wBaseSelect,Get_Value=items
                                   nitems=n_elements(items)
                                   for k=0, n_elements(id)-1 do widget_control,wBaseSelect,COMBOBOX_ADDITEM=id[k]
                                   widget_control,wBaseSelect,SET_COMBOBOX_SELECT=nitems
                                   self.subject->DisplayMap,nitems
                                 end
                             end
                             nitems=widget_info(widget_info(self.wBase,find_by_uname='GXMODEL:BaseMapSelect'),/COMBOBOX_NUMBER)
                             widget_control,widget_info(self.wBase,find_by_uname='GXMODEL:BaseMapRemove'),sensitive=(nitems gt 3)
                             widget_control,widget_info(self.wBase,find_by_uname='GXMODEL:BaseMapUp'),sensitive=(nitems gt 3)
                           ENDFOR
                         End                    
     'GXMODEL:BASEMAPSELECT':Begin
                             self.subject->DisplayMap,event.index
                             widget_control,widget_info(self.wBase,find_by_uname='GXMODEL:BaseMapRemove'),sensitive=(event.index ge 3)
                             widget_control,widget_info(self.wBase,find_by_uname='GXMODEL:BaseMapUp'),sensitive=(event.index ge 4)
                             nitems=widget_info(widget_info(self.wBase,find_by_uname='GXMODEL:BaseMapSelect'),/COMBOBOX_NUMBER)
                            End  
     'GXMODEL:BASEMAPUP':Begin
                           wBaseSelect=widget_info(self.wBase,find_by_uname='GXMODEL:BaseMapSelect')
                           item=widget_info(wBaseSelect,/COMBOBOX_GETTEXT)
                           widget_control,wBaseSelect,get_value=items
                           find=where(items eq item,count)
                           if count gt 0 then selected=find[count-1] else selected=0
                           if selected gt 3 then begin
                             refmaps=self.subject->Refmaps()
                             map=(*refmaps)->get(selected,/map)
                             mapup=(*refmaps)->get(selected-1,/map)
                             (*refmaps)->set,selected-1,map=map
                             (*refmaps)->set,selected,map=mapup
                           endif 
                           wBaseSelect=widget_info(self.wBase,find_by_uname='GXMODEL:BaseMapSelect')
                           widget_control,wBaseSelect,get_value=value   
                           idx=lindgen(n_elements(value))
                           idx[selected-1]=selected
                           idx[selected]=selected-1
                           value=value[sort(idx)]
                           widget_control,wBaseSelect,set_value=value   
                           self.subject->DisplayMap,selected     
                           widget_control,wBaseSelect,SET_COMBOBOX_SELECT=selected  
                           widget_control,widget_info(self.wBase,find_by_uname='GXMODEL:BaseMapUp'),sensitive=((selected) gt 3)       
                         End                  
     'GXMODEL:BASEMAPREMOVE':Begin
                             wBaseSelect=widget_info(self.wBase,find_by_uname='GXMODEL:BaseMapSelect')
                             item=widget_info(wBaseSelect,/COMBOBOX_GETTEXT)
                             widget_control,wBaseSelect,get_value=items
                             find=where(items eq item,count)
                             if count gt 0 then selected=find[count-1] else selected=0
                             if selected gt 2 then begin
                             widget_control,wBaseSelect,COMBOBOX_DELETEITEM=selected
                             widget_control,wBaseSelect,SET_COMBOBOX_SELECT=selected-1
                             self.subject->RemoveMap,selected
                             end
                             nitems=widget_info(widget_info(self.wBase,find_by_uname='GXMODEL:BaseMapSelect'),/COMBOBOX_NUMBER)
                             widget_control,widget_info(self.wBase,find_by_uname='GXMODEL:BaseMapRemove'),sensitive=(nitems gt 3)
                             self.subject->DisplayMap,selected-1
                            End  
     'GXMODEL:ALL2PLOTMAN':Begin
                             self.subject->GetProperty,refmaps=refmaps
                             if ptr_valid(refmaps) then begin
                              (*refmaps)->Clone,omap,/all
                              widget_control,event.top,send_event={GX2PLOTMAN,id:0l,top:0l,handler:0l,omap:omap,name:'GX REFMAPS',k:0}
                             end
                           END   
                           
     'GXMODEL:NSCALE': Begin
                         widget_control,event.id,get_value=nscale
                         volume=self.subject->GetVolume()
                         volume->SetProperty,nscale=nscale
                       End
                       
     'GXMODEL:TSCALE': Begin
                         widget_control,event.id,get_value=tscale
                         volume=self.subject->GetVolume()
                         volume->SetProperty,tscale=tscale
                       End 
                                                                  
     'GXMODEL:BSCALE':Begin
                         widget_control,event.id,get_value=bscale
                         self.subject->SetProperty,bscale=bscale
                         all=self.subject->Get(/all,count=count)
                         for i=0, count -1 do begin
                          case 1 of
                           obj_isa(all[i],'gxfluxtube'):begin
                                 all[i]->GetProperty,centerline=centerline,centerindex=centerindex,wParent=wParent
                                 centerline->GetProperty,data=line,xcoord_conv=xcoord_conv,ycoord_conv=ycoord_conv,zcoord_conv=zcoord_conv
                                 centerline->GetVertexAttributeData,'s',s
                                 centerline->GetVertexAttributeData,'B',B
                                 alpha=centerline->GetAlpha() 
                                 self.subject->GetProperty,Bscale=Bscale
                                 if n_elements(Bscale) ne 0 then B=B*Bscale                                 
                                 sz=size(line)
                                 l=abs(s[0]-s[sz[2]-1])
                                 s=s[centerindex]
                                 alpha=alpha[centerindex]
                                 b=norm(b[*,centerindex])
                                 p=line[*,centerindex]
                                 dx=xcoord_conv[1]
                                 dy=ycoord_conv[1]
                                 dz=zcoord_conv[1]
                                 m=max([dx,dy,dz])
                                 widget_control,widget_info(wParent,find_by_uname='GXFLUXTUBE:CENTERVALUE'),set_value=$
                                 strcompress(string(p[0],p[1],p[2],s,s*gx_rsun(),b,alpha,$
                                 format="('grid:[',f6.2,',',f6.2,',',f6.2,']; s=',f8.5,'R=',g11.4,'cm; B=',f10.3,'G ','alpha=',g10.3,'/cm')" ))
                                 all[i]->DisplayB2B0ratio
                                end    
                           else:        
                          endcase
                         endfor
                       End 
                       
  
     'GXMODEL:Q_RESET':Begin 
                        volume=(self.subject->GetVolume())
                        q=[0.000415,1e2,1e9,0,0]
                        volume->SetVertexAttributeData,'q0_coeff',q
                        self.subject->GetProperty,wParent=wParent
                        widget_control,widget_info(wparent,find_by_uname='GXMODEL:q'),set_value=q
                        q0_formula=volume->SetQ0(q0_formula)                  
                       End                 
     'GXMODEL:Q':     Begin
                          volume=(self.subject->GetVolume())
                          volume->GetVertexAttributeData,'q0_formula',q0_formula
                          q0_formula=string(q0_formula)
                          widget_control,event.id,get_value=q
                          volume->SetVertexAttributeData,'q0_coeff',q
                          q0_formula=volume->SetQ0(q0_formula)      
                       end                 
     'GXMODEL:Q0_FORMULA': Begin
                            widget_control,event.id,get_value=q0_formula
                            q0_formula=q0_formula[0]
                            volume=(self.subject->GetVolume())
                            widget_control,event.id,set_value=volume->SetQ0(q0_formula)                           
                           End     
     'GXMODEL:Q0_FORMULA_RESET': Begin
                                   volume=(self.subject->GetVolume())
                                   self.subject->GetProperty,wParent=wParent
                                   wq0f=widget_info(wparent,find_by_uname='GXMODEL:q0_formula')
                                   widget_control,wq0f,set_value=volume->SetQ0()                                  
                                 End  
                                 
     'GXMODEL:Q_FORMULA':       Begin
                                   widget_control,event.id,get_value=q_formula
                                   q_formula=q_formula[0]
                                   volume=(self.subject->GetVolume())
                                   widget_control,event.id,set_value=volume->SetQ(q_formula)
                                 End                            
     'GXMODEL:Q_FORMULA_RESET': Begin
                                   volume=(self.subject->GetVolume())
                                   self.subject->GetProperty,wParent=wParent
                                   wqf=widget_info(wparent,find_by_uname='GXMODEL:q_formula')
                                   widget_control,wqf,set_value=volume->SetQ() 
                                 End     
     'GXMODEL:UPDATE': Begin
                        volume=(self.subject->GetVolume())
                        volume->Update,/force
                       End                                                                                     
     'GXMODEL:ADDTR': BEGIN
                         addtr=widget_info(event.id,/button_set)
                         flags=(self.subject->GetVolume())->setflags(TRADD=addtr)
                         widget_control,widget_info(event.top,find_by_uname='Scanbox'),get_uvalue=scanbox
                         scanbox->ReplaceParmValue,'AddTR',addtr
                       END  
     'GXMODEL:TRMASK': BEGIN
                         trmask=widget_info(event.id,/button_set)
                         flags=(self.subject->GetVolume())->setflags(TRMASK=trmask,/NEWID)
                       END                  
     'GXMODEL:TRFACTOR': BEGIN
                         ApplyTRfactor=widget_info(event.id,/button_set)
                         flags=(self.subject->GetVolume())->setflags(TRFACTOR=ApplyTRfactor)
                         widget_control,widget_info(event.top,find_by_uname='Scanbox'),get_uvalue=scanbox
                         scanbox->ReplaceParmValue,'ApplyTRfactor', ApplyTRfactor
                       END                  
     'GXMODEL:SS': BEGIN
                         NTSSDEM=widget_info(event.id,/button_set)
                         widget_control,widget_info(event.top,find_by_uname='Scanbox'),get_uvalue=scanbox
                         scanbox->ReplaceParmValue,'SS',NTSSDEM
                         volume=(self.subject->GetVolume())
                         flags=volume->Setflags(NTSSDEM=NTSSDEM) 
                         flags=volume->setflags(newNT=volume->NewNT())
                         if flags.NTSSDEM then begin
                          widget_control,event.id,set_uvalue=gx_ebtel_path()
                          scanbox->ReplaceEBTELtables,path=gx_ebtel_path(/ss)
                         endif else begin
                          widget_control,event.id,get_uvalue=path
                          scanbox->ReplaceEBTELtables,path=path
                         endelse
                         volume->PlotModelAttributes
                       END                  
     'GXMODEL:USEDEM': BEGIN
                         usedem=event.value
                         volume=(self.subject->GetVolume())
                         case usedem of
                          0:flags=volume->setflags(/NTstored)
                          1:flags=volume->setflags(/NTdem)
                          2:flags=volume->setflags(/NTss)
                          else:
                         endcase
                         flags=volume->setflags(newNT=volume->NewNT())
                         volume->PlotModelAttributes
                         all=self.subject->Get(/all,isa='GXFLUXTUBE',count=count)
                         for t=0,count-1 do all[t]->SelectThermalModel,usedem=usedem   
                       END  
     'GXMODEL:DEMAVG': BEGIN
                        volume=(self.subject->GetVolume())
                        flags=volume->setflags(newNT=volume->NewNT())
                        wnparms=widget_info(event.top,FIND_BY_UNAME='renderer:nparms')
                        if widget_valid(wnparms) then begin
                          widget_control,event.id,get_value=value
                          wDEMavg=widget_info(wnparms,find_by_uname='DEMavg')
                          if widget_valid(wDEMavg) then widget_control,wDEMavg,set_value=value
                        endif
                       END                    
     'GXMODEL:TRMASKMENU':begin
                            self.subject->ReplaceTRMask,event
                          end  
     'GXMODEL:TR_BZ_MASK_THRESHOLD': BEGIN
                                      widget_control,event.id,get_value=threshold
                                      self.subject->ComputeTRmask,type='Bz',threshold=threshold,/test 
                                    END
     'GXMODEL:TR_BZ_MASK_OK': BEGIN
                              widget_control,event.id, get_uvalue=wthreshold
                              widget_control,wthreshold,get_value=threshold
                              self.subject->ComputeTRmask,type='Bz',threshold=threshold
                              self.subject->DisplayTRmask
                              flags=(self.subject->GetVolume())->setflags(NEWID=((self.subject->GetVolume())->getflags()).TRMASK)
                              widget_control,widget_info(widget_info(widget_info(widget_info(event.id,/parent),/parent),/parent),find_by_uname='GXMODEL:TRMaskMenu'),SET_DROPLIST_SELECT=0
                              widget_control,widget_info(widget_info(event.id,/parent),/parent),/destroy
                             END   
     'GXMODEL:TR_THETA_MASK_THRESHOLD': BEGIN
                               widget_control,event.id,get_value=threshold
                               self.subject->ComputeTRmask,type='Bz/B',threshold=threshold,/test
                             END
     'GXMODEL:TR_THETA_MASK_OK': BEGIN
                               widget_control,event.id, get_uvalue=wthreshold
                               widget_control,wthreshold,get_value=threshold
                               self.subject->ComputeTRmask,type='Bz/B',threshold=threshold
                               self.subject->DisplayTRmask
                               flags=(self.subject->GetVolume())->setflags(NEWID=((self.subject->GetVolume())->getflags()).TRMASK)
                               widget_control,widget_info(widget_info(widget_info(widget_info(event.id,/parent),/parent),/parent),find_by_uname='GXMODEL:TRMaskMenu'),SET_DROPLIST_SELECT=0
                               widget_control,widget_info(widget_info(event.id,/parent),/parent),/destroy
                             END                        
     'GXMODEL:TR_MASK_CANCEL':BEGIN
                             widget_control,widget_info(widget_info(widget_info(widget_info(event.id,/parent),/parent),/parent),find_by_uname='GXMODEL:TRMaskMenu'),SET_DROPLIST_SELECT=0
                             widget_control,widget_info(widget_info(event.id,/parent),/parent),/destroy
                            END
                                      
     'GXMODEL:COMPUTENT': BEGIN
                              volume=(self.subject->GetVolume())
                              volume->ComputeNT,/question
                           END  
    
     'GXMODEL:ATTRIBUTEPLOTOPTIONS':  BEGIN
                                (self.subject->GetVolume())->PlotModelAttributes
                           END 
     'GXMODEL:XATTRIBUTE':  BEGIN
                                (self.subject->GetVolume())->PlotModelAttributes
                           END  
     'GXMODEL:YATTRIBUTE':  BEGIN
                                (self.subject->GetVolume())->PlotModelAttributes
                           END    
     'GXMODEL:ROTATEXY':  BEGIN
                                (self.subject->GetVolume())->PlotModelAttributes
                           END  
     'GXMODEL:XHISTOGRAM':  BEGIN
                                (self.subject->GetVolume())->PlotModelAttributes
                           END                                                                                                                                                                                                                                              
     'GXMODEL:CLEAN':Begin
                     model=self.subject
                     all=model->get(/all,count=count)
                     for i=0,count-1 do begin
                      case 1 of
  	                    obj_isa(all[i],'gxBline'):begin
  	                     all[i]->GetProperty,lock=lock
  	                     if ~lock then obj_destroy,all[i]
  	                    end
  	                    obj_isa(all[i],'gxFluxTube'):begin
  	                     all[i]->GetProperty,Parent=model,name=name,lock=lock
  	                     if ~lock then begin
  	                     if obj_isa(model,'GXMODEL') then begin
  	                      model->GetProperty,wParent=wParent
  	                      widget_control,widget_info(wParent,find_by_uname=name),/destroy
  	                      model->RequestVolumeUpdate,/newID
  	                      model->SetRoi
  	                     end
  	                     end
  	                    end
  	                  else:
  	                 endcase
                     end
                    End
     'GXMODEL:SAVE':Begin
                     model=self.subject
                     file=dialog_pickfile(filter='*.gxm',$
                     DEFAULT_EXTENSION='gxm',$
                     /write,/OVERWRITE_PROMPT,$
                     title='Please select a file to save current model configuration')
                     if file ne '' then begin
                      model->GetProperty,parent=parent
                      parent->Remove,model
                      grid=model->GetGrid()
                      if ptr_valid(grid) then begin
                        grid_size=n_elements(*grid)*4/1024
                        answ=dialog_message(strcompress(string(grid_size,format="('Do you want to save the scan grid along with the model (',g0,' kB increase in file size)?')")),/question)
                        if strupcase(answ) eq 'NO' then begin
                          model->SetGrid,ptr_new()
                          save,model,file=file,/compress
                          model->SetGrid,grid
                        endif else save,model,file=file,/compress
                      endif else save,model,file=file,/compress
                      parent->Add,model
                     end
                    End
                    
     'GXMODEL:REMOVE':return,{gxRemoveModelEvent,id: self.wIDBase, top: event.top, handler:0L}
  
     ;---------------- gxFluxtube-------------------------------------------------------------
     'GXFLUXTUBE:HIDECTRL':BEGIN
                   tooltip=event.select?'Show fluxtube center line':'Hide fluxtube center line'
                   widget_control,event.id,set_value=$
                   ~event.select?gx_bitmap(filepath('image.bmp', subdirectory=subdirectory)):$
                   gx_bitmap(filepath('eye_closed.bmp', subdirectory=subdirectory)),$
                   tooltip=tooltip,/bitmap
                   self.subject->GetProperty,centerline=centerline
                   centerline->SetProperty,hide=event.select
                 END
     
     'GXFLUXTUBE:HIDE':BEGIN
                   tooltip=event.select?'Show fluxtube mesh':'Hide fluxtube mesh'
                   widget_control,event.id,set_value=$
                   ~event.select?gx_bitmap(filepath('image.bmp', subdirectory=subdirectory)):$
                   gx_bitmap(filepath('eye_closed.bmp', subdirectory=subdirectory)),$
                   tooltip=tooltip,/bitmap
                   self.subject->SetProperty,hide=event.select
                   self.subject->RequestVolumeUpdate,/newID
                 END
     'GXFLUXTUBE:REMOVE':BEGIN
                  return,{gxRemoveFluxTubeEvent,id: self.wIDBase, top: event.top, handler:0L}
                 END
     'GXFLUXTUBE:LOCK': BEGIN
               self.subject->SetProperty,lock=event.select
               self.subject->GetProperty,lock=lock
               widget_control,event.id,set_value=lock?gx_bitmap(gx_findfile('lock.bmp')):$
               gx_bitmap(gx_findfile('unlock.bmp')),/bitmap
               widget_control,widget_info(event.handler,find_by_uname='GXFLUXTUBE:REMOVE'),sensitive=~lock
              END
     'GXFLUXTUBE:CENTER': BEGIN
               widget_control,event.id,get_value=value
               self.subject->SetProperty,Centerindex=value
               self.subject->SetVersors
               self.subject->SetBase
               self.subject->SetBLines
               self.subject->GetProperty,centerline=centerline,centerindex=centerindex
               centerline->GetProperty,data=line
               centerline->GetVertexAttributeData,'s',s
               centerline->GetVertexAttributeData,'B',B
               alpha=centerline->GetAlpha() 
               self.subject->GetProperty,parent=Model
               Model->GetProperty,Bscale=Bscale
               if n_elements(Bscale) ne 0 then B=B*Bscale
               sz=size(line)
               l=abs(s[0]-s[sz[2]-1])
               s=s[centerindex]
               alpha=alpha[centerindex]
               b=norm(b[*,centerindex])
               p=line[*,centerindex]
               widget_control,widget_info(self.wbase,find_by_uname='GXFLUXTUBE:CENTERVALUE'),set_value=$
               strcompress(string(p[0],p[1],p[2],s,s*gx_rsun(),b,alpha,$
               format="('grid:[',f6.2,',',f6.2,',',f6.2,']; s=',f8.5,'R=',g11.4,'cm; B=',f10.3,'G ','alpha=',g10.3,'/cm')" ))
               widget_control,event.id,set_slider_max=sz[2]-1
               self.subject->SetProperty,Centerindex=value
               show=widget_info(widget_info(self.wbase,find_by_uname='GXFLUXTUBE:TOP'),/button_set)
               (self.subject->GetByName('Top'))->SetProperty,hide=1-show
               self.subject->DisplayB2B0ratio
              END
     'GXFLUXTUBE:S0': BEGIN
               widget_control,event.id,get_value=index
               self.subject->GetProperty,centerline=centerline 
               centerline->GetVertexAttributeData,'s',s
               self.subject->SetProperty,s0=s[index]
               self.subject->UpdateAll
              END  
     'GXFLUXTUBE:S0_DUPLICATE': BEGIN
               widget_control,event.id,get_value=index
               self.subject->GetProperty,centerline=centerline 
               centerline->GetVertexAttributeData,'s',s
               self.subject->SetProperty,s0=s[index]
               self.subject->UpdateAll
              END                
     'GXFLUXTUBE:PHI': BEGIN
               widget_control,event.id,get_value=value
               self.subject->SetProperty,PHI=value
               self.subject->SetBase
               self.subject->SetBLines
               self.subject->ComputeVersors
               self.subject->UpdateAll         
              END
     'GXFLUXTUBE:R': BEGIN
               widget_control,event.id,get_value=value
               self.subject->SetProperty,a=value,b=value
               self.subject->SetBase
               self.subject->SetBLines
               self.subject->ComputeDistance
               self.subject->UpdateAll
              END         
     'GXFLUXTUBE:E': BEGIN
                      tooltip=event.select?'Switch to circular cross section':'Switch to elliptical cross section'
                      widget_control,event.id,set_value=$
                      ~event.select?gx_bitmap(filepath('eba_meth_noex_nocm.bmp', subdirectory=subdirectory)):$
                      gx_bitmap(filepath('ellipse.bmp', subdirectory=subdirectory)),$
                      tooltip=tooltip,/bitmap
                      if event.select then begin
                       widget_control, widget_info(event.handler,find_by_uname= 'GXFLUXTUBE:R'),map=0,get_value=radius
                       widget_control, widget_info(event.handler,find_by_uname= 'GXFLUXTUBE:a'),map=1,set_value=radius
                       widget_control, widget_info(event.handler,find_by_uname= 'GXFLUXTUBE:b'),map=1,set_value=radius
                       widget_control, widget_info(event.handler,find_by_uname= 'GXFLUXTUBE:phi'),map=1
                      endif else begin
                       widget_control, widget_info(event.handler,find_by_uname= 'GXFLUXTUBE:a'),map=0,get_value=radius
                       widget_control, widget_info(event.handler,find_by_uname= 'GXFLUXTUBE:R'),map=1,set_value=radius
                       widget_control, widget_info(event.handler,find_by_uname= 'GXFLUXTUBE:b'),map=0,set_value=radius
                       widget_control, widget_info(event.handler,find_by_uname= 'GXFLUXTUBE:phi'),map=0
                      end
                       self.subject->SetProperty,a=radius,b=radius
                       self.subject->SetBase
                       self.subject->SetBLines
                       self.subject->ComputeDistance
                       self.subject->UpdateAll
                     END 
     'GXFLUXTUBE:TOP': BEGIN
                      tooltip=~event.select?'Show Bmin locus':'Hide Bmin locus'
                      widget_control,event.id,set_value=$
                      event.select?gx_bitmap(filepath('image.bmp', subdirectory=subdirectory)):$
                      gx_bitmap(filepath('eye_closed.bmp', subdirectory=subdirectory)),$
                      tooltip=tooltip,/bitmap
                      (self.subject->GetByName('Top'))->SetProperty,hide=1-event.select
                     END                        
     'GXFLUXTUBE:A': BEGIN
               widget_control,event.id,get_value=value
               self.subject->SetProperty,a=value
               self.subject->SetBase
               self.subject->SetBLines
               self.subject->ComputeDistance
               self.subject->UpdateAll
              END
     'GXFLUXTUBE:B': BEGIN
               widget_control,event.id,get_value=value
               self.subject->SetProperty,b=value
               self.subject->SetBase
               self.subject->SetBLines
               self.subject->ComputeDistance
               self.subject->UpdateAll
              END                  
     'GXFLUXTUBE:NRHO': BEGIN
               widget_control,event.id,get_value=value
               self.subject->SetProperty,NRHO=value
               self.subject->SetBase
               self.subject->SetBLines
              END
     'GXFLUXTUBE:NPHI': BEGIN
               widget_control,event.id,get_value=value
               self.subject->SetProperty,NPHI=value
               self.subject->SetBase
               self.subject->SetBLines
              END
     'GXFLUXTUBE:N_NTH':Begin
                         widget_control,event.id,get_value=n_nth
                         self.subject->SetProperty,n_nth=n_nth
                         widget_control,widget_info(event.handler,Find_By_Uname='GXFLUXTUBE:n_nth_duplicate'),Set_Value=n_nth
                         self.subject->Update_N_nth
                        End 
     'GXFLUXTUBE:S0/L':Begin
                         widget_control,event.id,get_value=s0
                         self.subject->GetProperty,centerline=centerline
                         centerline->GetVertexAttributeData,'s',s 
                         l=abs(s[0]-s[n_elements(s)-1])
                         self.subject->SetProperty,s0=s0*l
                         self.subject->UpdateAll
                        End                    
     'GXFLUXTUBE:N_TH':Begin
                         widget_control,event.id,get_value=n_th
                         self.subject->SetProperty,n_th=n_th
                         dup=widget_info(event.handler,Find_By_Uname='GXFLUXTUBE:n_th_duplicate')
                         if widget_valid(dup) then widget_control,dup,Set_Value=n_th
                         self.subject->UpdateAll
                        End      
     'GXFLUXTUBE:T0':Begin
                         widget_control,event.id,get_value=T0
                         self.subject->SetProperty,T0=T0
                         dup=widget_info(event.handler,Find_By_Uname='GXFLUXTUBE:T0_duplicate')
                         if widget_valid(dup) then widget_control,dup,Set_Value=T0
                         self.subject->UpdateAll
                        End                                          
     'GXFLUXTUBE:P_NTH':Begin
                     widget_control,event.id,get_value=p_nth
                     self.subject->SetProperty,p_nth=p_nth
                     self.subject->Update_N_nth
                    End
     'GXFLUXTUBE:P_TH':Begin
                     widget_control,event.id,get_value=p_th
                     self.subject->SetProperty,p_th=p_th
                     self.subject->UpdateAll
                    End               
     'GXFLUXTUBE:Q_NTH':Begin
                     widget_control,event.id,get_value=q_nth
                     self.subject->SetProperty,q_nth=q_nth
                     self.subject->Update_N_nth
                    End
     'GXFLUXTUBE:Q_TH':Begin
                     widget_control,event.id,get_value=q_th
                     self.subject->SetProperty,q_th=q_th
                     self.subject->UpdateAll
                    End               
     'GXFLUXTUBE:NR_NTH':Begin
                     widget_control,event.id,get_value=nr_nth
                     if self.subject->CheckSyntax(nr_nth=nr_nth) then begin
                      self.subject->SetProperty,nr_nth=nr_nth
                      self.subject->Update_N_nth
                     end
                    End
     'GXFLUXTUBE:NR_TH':Begin
                     widget_control,event.id,get_value=nr_th
                     if self.subject->CheckSyntax(nr_th=nr_th) then begin
                      self.subject->SetProperty,nr_th=nr_th
                      self.subject->UpdateAll
                     end
                    End               
     'GXFLUXTUBE:NS_NTH':Begin
                     widget_control,event.id,get_value=ns_nth
                     if self.subject->CheckSyntax(ns_nth=ns_nth) then begin
                      self.subject->SetProperty,ns_nth=ns_nth
                      self.subject->UpdateAll
                     end 
                    End  
     'GXFLUXTUBE:NZ_TH':Begin
                     widget_control,event.id,get_value=nz_th
                     if self.subject->CheckSyntax(nz_th=nz_th) then begin
                      self.subject->SetProperty,nz_th=nz_th
                      self.subject->UpdateAll
                     end 
                    End   
     'GXFLUXTUBE:E_SELECT':Begin
                      self.subject->SelectEnergyDistribution,event.index
                      self.subject->RequestVolumeUpdate,condition='dist_E'
                    End   
     'GXFLUXTUBE:T0_DUPLICATE':Begin
                         widget_control,event.id,get_value=T0
                         self.subject->SetProperty,T0=T0
                         self.subject->UpdateEnergyDistribution
                         widget_control,widget_info(event.handler,Find_By_Uname='GXFLUXTUBE:T0'),Set_Value=T0
                         self.subject->UpdateAll
                        End 
     'GXFLUXTUBE:N_TH_DUPLICATE':Begin
                         widget_control,event.id,get_value=n_th
                         self.subject->SetProperty,n_th=n_th
                         self.subject->UpdateEnergyDistribution
                         widget_control,widget_info(event.handler,Find_By_Uname='GXFLUXTUBE:n_th'),Set_Value=n_th
                         self.subject->UpdateAll
                        End 
     'GXFLUXTUBE:N_NTH_DUPLICATE':Begin
                         widget_control,event.id,get_value=n_nth
                         self.subject->SetProperty,n_nth=n_nth
                         widget_control,widget_info(event.handler,Find_By_Uname='GXFLUXTUBE:n_nth'),Set_Value=n_nth
                         self.subject->Update_N_nth
                        End                                                                                                                          
     'GXFLUXTUBE:EMIN':Begin
                       self.subject->RequestVolumeUpdate,condition='Emin'
                       widget_control,event.id,get_value=emin
                       self.subject->SetProperty,emin=emin
                       self.subject->UpdateEnergyDistribution
                    End
     'GXFLUXTUBE:EMAX':Begin
                       self.subject->RequestVolumeUpdate,condition='Emax'
                       widget_control,event.id,get_value=emax
                       self.subject->SetProperty,emax=emax
                       self.subject->UpdateEnergyDistribution
                    End
     'GXFLUXTUBE:EBREAK':Begin
                       self.subject->RequestVolumeUpdate,condition='Ebreak'
                       widget_control,event.id,get_value=ebreak
                       self.subject->SetProperty,ebreak=ebreak
                       self.subject->UpdateEnergyDistribution
                    End       
     'GXFLUXTUBE:DELTA1':Begin
                       widget_control,event.id,get_value=delta1
                       self.subject->SetProperty,delta1=delta1
                       self.subject->UpdateEnergyDistribution
                       self.subject->RequestVolumeUpdate,condition='delta1'
                    End
     'GXFLUXTUBE:DELTA2':Begin
                       widget_control,event.id,get_value=delta2
                       self.subject->SetProperty,delta2=delta2
                       self.subject->UpdateEnergyDistribution
                       self.subject->RequestVolumeUpdate,condition='delta2'
                    End 
     'GXFLUXTUBE:KAPPA':Begin
                       widget_control,event.id,get_value=kappa
                       self.subject->SetProperty,kappa=kappa
                       self.subject->UpdateEnergyDistribution
                       self.subject->RequestVolumeUpdate,condition='kappa'
                    End   
     'GXFLUXTUBE:EPS':Begin
                       widget_control,event.id,get_value=eps
                       self.subject->SetProperty,eps=eps
                       self.subject->UpdateEnergyDistribution
                       self.subject->RequestVolumeUpdate,condition='eps'
                    End   
     'GXFLUXTUBE:PA_SELECT':Begin
                      self.subject->SelectPADistribution,event.index
   
                    End 
     'GXFLUXTUBE:THETA_C0':Begin
                       widget_control,event.id,get_value=theta_c0
                       self.subject->SetProperty,theta_c0=theta_c0
                       self.subject->Update_Theta_c
                       self.subject->UpdatePADistribution
                       self.subject->RequestVolumeUpdate,condition='THETA_C0'
                    End 
     'GXFLUXTUBE:THETA_B0':Begin
                       widget_control,event.id,get_value=theta_b0
                       self.subject->SetProperty,theta_b0=theta_b0
                       self.subject->Update_Theta_b
                       self.subject->UpdatePADistribution
                       self.subject->RequestVolumeUpdate,condition='THETA_B0'
                    End  
     'GXFLUXTUBE:DMU0':Begin
                       widget_control,event.id,get_value=dMu0
                       self.subject->SetProperty,dMu0=dMu0
                       self.subject->Update_dMu
                       self.subject->UpdatePADistribution
                       self.subject->RequestVolumeUpdate,condition='dMu'
                    End 
     'GXFLUXTUBE:A_40':Begin
                       widget_control,event.id,get_value=a_40
                       self.subject->SetProperty,parm_a4_0=a_40
                       self.subject->Update_a4
                       self.subject->UpdatePADistribution
                       self.subject->RequestVolumeUpdate,condition='A_40'
                    End  
     'GXFLUXTUBE:USE_CLG':Begin
                       self.subject->SetProperty,use_clg=event.select
                       self.subject->Update_Theta_c,c_idx,B2B0=B2B0
                       self.subject->Update_Theta_b
                       self.subject->Update_dMu
                       self.subject->Update_a4
                       self.subject->UpdatePADistribution
                       self.subject->RequestVolumeUpdate,condition='USE_CLG'
                    End    
     'GXFLUXTUBE:S':Begin
                      widget_control,event.id,get_value=index
                      self.subject->GetProperty,centerline=centerline
                      centerline->GetVertexAttributeData,'s',s
                      l=abs(s[0]-s[n_elements(s)-1])
                      s=s[index]
                      widget_control,widget_info(event.handler,find_by_uname='GXFLUXTUBE:svalue'),set_value=string(s/l,format='("s/l=",g0)')
                      self.subject->UpdatePADistribution
                      self.subject->RequestVolumeUpdate,condition='S'
                    End                                                                                                                                                                                             
    else:
   endcase
 end
 return, self->Rewrite(event)
end

;----------------------------------------------------------------------
pro gxWidget::GetProperty, subject=subject,wBase=wBase,_ref_extra=extra
compile_opt hidden
subject=self.subject
wBase=self.wBase
self->IDLexWidget::GetProperty,_extra=extra
end
;----------------------------------------------------------------------
pro gxWidget::Cleanup
compile_opt hidden
if obj_valid(self.subject) then begin
  self.subject->GetProperty,parent=parent
  if obj_valid(parent) then parent->Remove,self.subject
  obj_destroy,self.subject
  if widget_valid(self.wIDBase) then widget_control,widget_info(self.wIDBase,/parent),/destroy
end
self->IDLexWidget::Cleanup
end
;---------------------------------------------------------------
pro gxWidget__define
struct_hide, {gxWidget, inherits IDLexWidget,wBase:0l,subject:obj_new()}
end